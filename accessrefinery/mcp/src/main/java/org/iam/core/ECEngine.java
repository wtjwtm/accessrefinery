package org.iam.core;

import com.google.common.collect.HashMultimap;
import com.google.common.collect.ImmutableSet;
import com.google.common.collect.Multimaps;
import com.google.common.collect.SetMultimap;
import org.iam.variables.dynamics.OperableLabel;
import org.iam.variables.statics.Label;

import javax.annotation.Nonnull;
import javax.annotation.ParametersAreNonnullByDefault;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * An incremental EC engine based on Delta-net's atom-splitting approach.
 *
 * <p>
 * This engine supports adding labels incrementally: when a new label arrives,
 * it only splits existing ECs where they overlap with the new label,
 * rather than recomputing all ECs from the full label set.
 * </p>
 *
 * <p>
 * The internal state is a partition of the semantic space into mutually disjoint
 * {@link OperableLabel} regions (the "atoms" / ECs), each associated with the set of
 * labels that cover it. Adding a new label applies Delta-net's atom-splitting:
 * for each existing EC that overlaps the new label, the EC is split into
 * (inter) and (diff) parts, preserving all previous label associations.
 * </p>
 *
 * <p>
 * <b>Persistent EC indices.</b> Unlike a naive implementation that renumbers all ECs from 0
 * on every rebuild, this engine assigns each unique EC a persistent index that is
 * <em>never reused</em>. Dead ECs (those removed during a split) have their indices
 * abandoned but not reassigned. This ensures that BDD/SAT encodings of existing EC
 * indices remain valid across incremental updates.
 * </p>
 *
 * @since 2025-02-28
 */
@ParametersAreNonnullByDefault
public class ECEngine {

    /**
     * Primary state: maps each EC (as an OperableLabel) to the set of labels that cover it.
     * All ECs are mutually disjoint.
     */
    private final SetMultimap<OperableLabel, Label> _mmap;

    /**
     * Persistent index per unique OperableLabel.
     * Once assigned, an index is never reused — even if its EC is removed during a split.
     */
    private final Map<OperableLabel, Integer> _ecToIndex;

    /**
     * Next available EC index. Monotonically increasing.
     */
    private int _nextECIndex;

    /**
     * The number of currently active ECs.
     */
    private int _numECs;

    /**
     * Maps each label to its set of EC indices (persistent integers).
     */
    private Map<Label, Set<Integer>> _varToLabels;

    /**
     * All labels known to this engine (including the true label).
     */
    private Set<Label> _allLabels;

    // ─────────────────────────────────────────────────────────────────────────
    //  Construction
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Constructs ECs for the given set of labels using the batch algorithm
     * (same semantics as {@link ECEngine}).
     *
     * @param labels    the set of labels to compute ECs for
     * @param trueLabel a label representing logical "true"
     */
    public ECEngine(Set<Label> labels, Label trueLabel) {
        _mmap = HashMultimap.create();
        _ecToIndex = new HashMap<>();
        _nextECIndex = 0;
        _allLabels = ImmutableSet.<Label>builder().addAll(labels).add(trueLabel).build();

        // Batch initialization: add each label via the incremental algorithm.
        for (Label label : _allLabels) {
            addLabelInternal(label);
        }
        rebuildIndices();
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Public API
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Adds a new label incrementally, splitting existing ECs as needed
     * (Delta-net atom-splitting).
     *
     * @param newLabel the label to add
     */
    public void addLabel(Label newLabel) {
        OperableLabel remaining = newLabel.convert();
        if (remaining.isEmpty()) {
            throw new RuntimeException("Label " + newLabel + " does not match any strings");
        }

        // Snapshot current ECs to avoid concurrent modification of _mmap.
        Set<OperableLabel> existingECs = ImmutableSet.copyOf(_mmap.keySet());

        for (OperableLabel ec : existingECs) {
            OperableLabel inter = ec.inter(remaining);

            // Disjoint → no split needed, move on.
            if (inter.isEmpty()) {
                continue;
            }

            // This EC overlaps with the new label. Remove it and split.
            Set<Label> ecLabels = new HashSet<>(_mmap.removeAll(ec));
            int oldIdx = _ecToIndex.get(ec);

            // The dead EC's index no longer covers these labels.
            for (Label l : ecLabels) {
                Set<Integer> idxs = _varToLabels.get(l);
                if (idxs != null) {
                    idxs.remove(oldIdx);
                    if (idxs.isEmpty()) {
                        _varToLabels.remove(l);
                    }
                }
            }

            OperableLabel diff = ec.minus(remaining);

            // The part of the EC that is NOT covered by the new label
            // retains only the old labels.
            if (!diff.isEmpty()) {
                _mmap.putAll(diff, ecLabels);
                int diffIdx = getIndex(diff);
                for (Label l : ecLabels) {
                    _varToLabels.computeIfAbsent(l, x -> new HashSet<>()).add(diffIdx);
                }
            }

            // The intersection part retains old labels AND gets the new label.
            _mmap.putAll(inter, ecLabels);
            _mmap.put(inter, newLabel);
            int interIdx = getIndex(inter);
            for (Label l : ecLabels) {
                _varToLabels.computeIfAbsent(l, x -> new HashSet<>()).add(interIdx);
            }
            _varToLabels.computeIfAbsent(newLabel, x -> new HashSet<>()).add(interIdx);

            // Reduce the remaining space.
            remaining = remaining.minus(ec);
            if (remaining.isEmpty()) {
                break;
            }
        }

        // Any part of the new label that didn't overlap existing ECs
        // becomes a new EC.
        if (!remaining.isEmpty()) {
            _mmap.put(remaining, newLabel);
            _varToLabels.computeIfAbsent(newLabel, x -> new HashSet<>()).add(getIndex(remaining));
        }

        _allLabels = ImmutableSet.<Label>builder()
                .addAll(_allLabels)
                .add(newLabel)
                .build();

        _numECs = _mmap.keySet().size();
    }

    /**
     * Returns the number of currently active ECs.
     *
     * @return the number of active ECs
     */
    public int getNumECs() {
        return _numECs;
    }

    /**
     * Returns the set of persistent indices for all currently active ECs.
     *
     * @return set of active EC indices
     */
    @Nonnull
    public Set<Integer> getActiveECIndices() {
        Set<Integer> indices = new HashSet<>();
        for (OperableLabel ec : _mmap.keySet()) {
            Integer idx = _ecToIndex.get(ec);
            if (idx != null) {
                indices.add(idx);
            }
        }
        return indices;
    }

    /**
     * Returns a mapping from each label to the set of EC indices it covers.
     *
     * @return a map from Label to set of EC indices
     */
    @Nonnull
    public Map<Label, Set<Integer>> getECs() {
        return _varToLabels;
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Internal helpers
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Internal label addition (used during batch initialization, no index rebuild).
     */
    private void addLabelInternal(Label newLabel) {
        OperableLabel remaining = newLabel.convert();
        if (remaining.isEmpty()) {
            throw new RuntimeException("Label " + newLabel + " does not match any strings");
        }

        Set<OperableLabel> existingECs = ImmutableSet.copyOf(_mmap.keySet());

        for (OperableLabel ec : existingECs) {
            OperableLabel inter = ec.inter(remaining);
            if (inter.isEmpty()) continue;

            Set<Label> ecLabels = _mmap.removeAll(ec);
            OperableLabel diff = ec.minus(remaining);

            if (!diff.isEmpty()) {
                _mmap.putAll(diff, ecLabels);
            }
            _mmap.putAll(inter, ecLabels);
            _mmap.put(inter, newLabel);

            remaining = remaining.minus(ec);
            if (remaining.isEmpty()) break;
        }

        if (!remaining.isEmpty()) {
            _mmap.put(remaining, newLabel);
        }
    }

    /**
     * Rebuilds the derived index maps (_varToLabels, _numECs)
     * from the current _mmap state, preserving persistent EC indices.
     *
     * <p>New ECs (those in _mmap but not yet in _ecToIndex) get fresh indices.
     * Existing ECs retain their previously assigned index.
     * Dead ECs (removed from _mmap during split) retain their index in _ecToIndex
     * but are excluded from the active maps.
     * </p>
     */
    private void rebuildIndices() {
        Map<Label, Set<Integer>> result = new HashMap<>();
        for (OperableLabel ec : _mmap.keySet()) {
            int idx = getIndex(ec);
            for (Label l : _mmap.get(ec)) {
                result.computeIfAbsent(l, x -> new HashSet<>()).add(idx);
            }
        }
        _varToLabels = result;
        _numECs = _mmap.keySet().size();
    }

    /**
     * Returns the persistent index for an EC, assigning a fresh one if needed.
     */
    private int getIndex(OperableLabel ec) {
        Integer idx = _ecToIndex.get(ec);
        if (idx == null) {
            idx = _nextECIndex++;
            _ecToIndex.put(ec, idx);
        }
        return idx;
    }
}
