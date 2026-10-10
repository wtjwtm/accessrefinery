package org.iam.core;

import org.iam.variables.statics.Label;

import javax.annotation.Nonnull;
import javax.annotation.ParametersAreNonnullByDefault;
import java.util.Map;
import java.util.Set;

// ADD_BEGIN_JOURNAL
/**
 * The equivalence class (EC) engine of a domain, built on Delta-net's atom-splitting
 * approach.
 *
 * <p>
 * The partitioning and the incremental update that lets a later mining task reuse it
 * (Technique 1) both live in {@link IncrementalECPartition}; this class is the entry
 * point the rest of the code base holds on to. A caller that only needs a one-shot
 * partition — the intent reducer, for instance — builds the engine and reads
 * {@link #getECs()} back off it, while a caller that drives successive mining tasks
 * reaches the partitioning through {@link IncrementalECPartition#update(Set)}.
 * </p>
 *
 * @since 2025-02-28
 */
@ParametersAreNonnullByDefault
public class ECEngine {

    /**
     * The partition this engine exposes. All state and all update logic live here.
     */
    private final IncrementalECPartition _partition;

    /**
     * Constructs ECs for the given set of labels using the batch algorithm.
     *
     * @param labels    the set of labels to compute ECs for
     * @param trueLabel a label representing logical "true"
     */
    public ECEngine(Set<Label> labels, Label trueLabel) {
        _partition = new IncrementalECPartition(labels, trueLabel);
    }

    /**
     * Adds a new label incrementally, splitting existing ECs as needed
     * (Delta-net atom-splitting).
     *
     * @param newLabel the label to add
     */
    public void addLabel(Label newLabel) {
        _partition.addLabel(newLabel);
    }

    /**
     * Returns the underlying partitioning, so that a caller driving several mining
     * tasks can reuse it instead of rebuilding.
     *
     * @return the partition
     */
    @Nonnull
    public IncrementalECPartition getPartition() {
        return _partition;
    }

    /**
     * Returns the number of currently active ECs.
     *
     * @return the number of active ECs
     */
    public int getNumECs() {
        return _partition.getNumECs();
    }

    /**
     * Returns the set of persistent indices for all currently active ECs.
     *
     * @return set of active EC indices
     */
    @Nonnull
    public Set<Integer> getActiveECIndices() {
        return _partition.getActiveECIndices();
    }

    /**
     * Returns a mapping from each label to the set of EC indices it covers.
     *
     * @return a map from Label to set of EC indices
     */
    @Nonnull
    public Map<Label, Set<Integer>> getECs() {
        return _partition.getECs();
    }
}
// END_BEGIN_JOURNAL
