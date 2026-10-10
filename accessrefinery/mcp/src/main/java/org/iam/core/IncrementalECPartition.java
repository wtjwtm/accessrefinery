package org.iam.core;

import com.google.common.collect.HashMultimap;
import com.google.common.collect.ImmutableSet;
import com.google.common.collect.SetMultimap;
import org.iam.variables.dynamics.OperableLabel;
import org.iam.variables.statics.Label;

import javax.annotation.Nonnull;
import javax.annotation.ParametersAreNonnullByDefault;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

// ADD_BEGIN_JOURNAL
/**
 * Technique 1 of the paper: the equivalence class (EC) partitioning of one domain,
 * plus the bookkeeping that lets a later mining task reuse it instead of rebuilding.
 *
 * <p>
 * The state is a partition of the domain's semantic space into mutually disjoint
 * {@link OperableLabel} regions (the "atoms" / ECs), each associated with the set of
 * labels covering it, together with the mapping {@code M} from each label to the ECs
 * it covers. A new mining task hands in its full label set through
 * {@link #update(Set)}:
 * </p>
 * <ul>
 *   <li>a variable whose label set has not changed is <em>unaffected</em>, and its
 *       partition is kept as it is — no EC is recomputed;</li>
 *   <li>for an affected variable, only the newly added labels are absorbed, and each
 *       of them splits just the existing ECs that have a non-empty intersection with
 *       it. An EC with an empty intersection is left untouched, index included
 *       (Delta-net's atom-splitting).</li>
 * </ul>
 *
 * <p>
 * <b>Persistent EC indices.</b> Each unique EC gets an index that is never reused:
 * the ECs a split removes have their indices abandoned rather than reassigned, so the
 * indices of the ECs that survive an update stay valid across successive mining tasks.
 * </p>
 *
 * @since 2026-10-09
 */
@ParametersAreNonnullByDefault
public class IncrementalECPartition {

    /**
     * The outcome of one {@link #update(Set)} call.
     */
    public static final class Update {
        /** Whether an existing partition had labels it had not absorbed yet. */
        private final boolean _affected;
        /** The labels this update added, in the order they were absorbed. */
        private final List<Label> _addedLabels;

        Update(boolean affected, List<Label> addedLabels) {
            this._affected = affected;
            this._addedLabels = addedLabels;
        }

        /**
         * Returns whether this update had real incremental work to do, i.e. whether the
         * variable was affected by the policy change. False both for an unaffected
         * variable and for the very first build of one, which is not incremental work.
         *
         * @return true when labels were absorbed into an existing partition
         */
        public boolean affected() {
            return _affected;
        }

        /**
         * Returns the labels this update absorbed, i.e. the ones the new mining task
         * added relative to the previous one.
         *
         * @return the newly added labels
         */
        public List<Label> addedLabels() {
            return _addedLabels;
        }
    }

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
     * Maps each label to its set of EC indices (persistent integers). This is the
     * mapping {@code M} of the paper.
     */
    private Map<Label, Set<Integer>> _varToLabels;

    /**
     * The labels this partition has already absorbed, including the true label. What a
     * later {@link #update(Set)} call does not find in here is what the new mining task
     * added.
     */
    private final Set<Label> _processedLabels;

    /**
     * Builds the partition of {@code labels} from scratch (the first mining task).
     *
     * @param labels    the labels to partition
     * @param trueLabel a label representing logical "true"
     */
    public IncrementalECPartition(Set<Label> labels, Label trueLabel) {
        _mmap = HashMultimap.create();
        _ecToIndex = new HashMap<>();
        _nextECIndex = 0;
        _processedLabels = new HashSet<>();
        _processedLabels.addAll(labels);
        _processedLabels.add(trueLabel);

        // Batch initialization: add each label via the incremental algorithm.
        for (Label label : ImmutableSet.copyOf(_processedLabels)) {
            addLabelInternal(label);
        }
        rebuildIndices();
    }

    /**
     * Absorbs the label set of the current mining task.
     * <p>
     * Labels already processed are skipped, so a domain whose label set did not change
     * is reported as unaffected and its partition is left exactly as it was.
     *
     * @param currentLabels the full label set of the current mining task
     * @return what this update did
     */
    public Update update(Set<Label> currentLabels) {
        List<Label> added = new ArrayList<>();
        for (Label label : currentLabels) {
            if (_processedLabels.add(label)) {
                addLabel(label);
                added.add(label);
            }
        }
        return new Update(!added.isEmpty(), added);
    }

    /**
     * Adds a new label incrementally, splitting existing ECs as needed
     * (Delta-net atom-splitting).
     *
     * @param newLabel the label to add
     */
    public void addLabel(Label newLabel) {
        _processedLabels.add(newLabel);

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

    /**
     * Returns the space of each active EC, keyed by its persistent index. This is the
     * partitioning itself rather than the label mapping, i.e. the "EC c" of the paper's
     * figures rather than the rows of {@code M}.
     *
     * @return a map from EC index to the space it covers
     */
    @Nonnull
    public Map<Integer, OperableLabel> getECSpaces() {
        Map<Integer, OperableLabel> spaces = new HashMap<>();
        for (OperableLabel ec : _mmap.keySet()) {
            Integer idx = _ecToIndex.get(ec);
            if (idx != null) {
                spaces.put(idx, ec);
            }
        }
        return spaces;
    }

    /**
     * Returns the labels this partition has already absorbed, including the true label.
     *
     * @return the processed labels
     */
    @Nonnull
    public Set<Label> getProcessedLabels() {
        return _processedLabels;
    }

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
// END_BEGIN_JOURNAL
