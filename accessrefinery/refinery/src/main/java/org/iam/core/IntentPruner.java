package org.iam.core;

import org.iam.intent.MCPIntent;
import org.iam.policy.model.MCPPolicy;
import org.iam.utils.Parameter;

import java.util.ArrayList;
import java.util.List;

// ADD_BEGIN_JOURNAL
/**
 * Phase 1 of the intent reducer: splits a set of candidate intents into the
 * <i>necessary</i> ones and the rest, so that the min-set-cover stage never has to
 * run equivalence class (EC) partitioning for the necessary ones.
 * <p>
 * An intent is necessary when it owns a unique space, i.e. when
 * {@code I ∧ ¬(⋃ of all other candidate intents) ∧ P} is non-empty: some request
 * allowed by the policy is covered by {@code I} and by no other candidate, so every
 * minimal cover of the policy has to contain {@code I}. The union of all other
 * intents is not rebuilt per intent (which would cost O(|S|²) BDD operations); it is
 * read off the prefix and suffix disjunctions of the candidate list (Definition 3),
 * which cost one BDD operation per intent, making the whole pass O(|S|).
 * <p>
 * The candidates that survive, together with the policy space left uncovered by the
 * necessary intents, are what the caller hands to the EC/ILP set cover.
 *
 * @author
 * @since 2026-10-09
 */
public final class IntentPruner {

    private IntentPruner() {
        // static utility: instantiation is not meaningful
    }

    /**
     * The outcome of one pruning pass.
     */
    public static final class Result {
        /** The necessary intents: each owns a unique space inside the policy. */
        private final List<MCPIntent> _essential;
        /** The intents left for the EC/ILP set cover. */
        private final List<MCPIntent> _candidates;
        /** The policy space the necessary intents do not cover. */
        private final MCPBitVector _remainingPolicy;

        /**
         * Constructs a pruning result.
         *
         * @param essential the necessary intents
         * @param candidates the intents left for the set cover
         * @param remainingPolicy the policy space not covered by the necessary intents
         */
        Result(List<MCPIntent> essential, List<MCPIntent> candidates, MCPBitVector remainingPolicy) {
            this._essential = essential;
            this._candidates = candidates;
            this._remainingPolicy = remainingPolicy;
        }

        /**
         * Returns the necessary intents, in the order they were given.
         *
         * @return the necessary intents
         */
        public List<MCPIntent> essential() {
            return _essential;
        }

        /**
         * Returns the intents that still have to be covered by the set cover, in the
         * order they were given.
         *
         * @return the candidate intents
         */
        public List<MCPIntent> candidates() {
            return _candidates;
        }

        /**
         * Returns the part of the policy space that the necessary intents leave open.
         * When this is zero the necessary intents already cover the policy and the set
         * cover has nothing left to do.
         *
         * @return the remaining policy space
         */
        public MCPBitVector remainingPolicy() {
            return _remainingPolicy;
        }
    }

    /**
     * Partitions the given findings into the necessary ones and the rest, using a
     * prefix/suffix scan so that each finding's coverage is compared against all the
     * others in one pass.
     *
     * @param findings the findings to partition, possibly empty
     * @param policySpace the symbolic policy space being covered
     * @return the necessary findings, the remaining candidates and the policy space the
     *         necessary ones leave open
     */
    public static Result prune(List<MCPIntent> findings, MCPBitVector policySpace) {
        List<MCPIntent> essential = new ArrayList<>();
        List<MCPIntent> candidates = new ArrayList<>();

        int n = findings.size();
        // No finding survives the zero-node filter: nothing is covered and nothing is
        // essential, so the whole space is still open. This guard is not an
        // optimization — the suffix scan below indexes suffOr[n-1] and would throw on
        // n == 0. It is what lets reducingIntents drop its former `n <= 1` shortcut:
        // that shortcut returned before this scan ran, so on the policies with the
        // fewest findings the Pruning Reducer stage's reducing columns carried the cost of the
        // short-circuit instead of the pre-filter's. The selected set is the same
        // either way — the shortcut only distorted the measurement.
        if (n == 0) {
            return new Result(essential, candidates, policySpace);
        }

        // Each finding only matters inside the policy space, so the unique-space test
        // is run on I ∧ P. Intersecting here rather than at the end is what keeps the
        // prefix/suffix disjunctions small.
        List<MCPBitVector> coverage = new ArrayList<>(n);
        for (MCPIntent finding : findings) {
            coverage.add(finding.getMCPNode().and(policySpace));
        }

        MCPBitVector[] prefixOr = prefixOr(coverage);
        MCPBitVector[] suffixOr = suffixOr(coverage);

        for (int i = 0; i < n; i++) {
            MCPBitVector othersOr = prefixOr[i].or(suffixOr[i]);
            MCPBitVector unique = coverage.get(i).diff(othersOr);
            if (!unique.isZero()) {
                essential.add(findings.get(i));
            } else {
                candidates.add(findings.get(i));
            }
        }

        Parameter.LOGGER.info("[5/6]  essential pre-filter: " + findings.size()
                + " -> " + essential.size() + " essential, " + candidates.size() + " candidates");

        // Verify essential coverage
        if (Parameter.isBDD) {
            MCPBitVector essentialCoverage = MCPPolicy.getMCPFactory().getFalse().id();
            for (MCPIntent f : essential) {
                essentialCoverage = essentialCoverage.or(f.getMCPNode());
            }
            MCPBitVector gap = policySpace.diff(essentialCoverage);
            if (!gap.isZero()) {
                double gapSat = gap.satCount();
                Parameter.LOGGER.info("[5/6]  essential coverage gap: satCount=" + String.format("%.0f", gapSat));
            } else {
                Parameter.LOGGER.info("[5/6]  essential coverage: FULL (no gap)");
            }
        }

        MCPBitVector remainingPolicy = policySpace.id();
        for (MCPIntent f : essential) {
            remainingPolicy = remainingPolicy.diff(f.getMCPNode());
        }
        return new Result(essential, candidates, remainingPolicy);
    }

    /**
     * Computes {@code PrefixOr(Iᵢ)} for every intent: the disjunction of the spaces of
     * all the intents preceding it. The first entry is false.
     *
     * @param coverage the per-intent spaces, in order
     * @return the prefix disjunctions, one per intent
     */
    static MCPBitVector[] prefixOr(List<MCPBitVector> coverage) {
        int n = coverage.size();
        MCPBitVector[] prefixOr = new MCPBitVector[n];
        if (n == 0) {
            return prefixOr;
        }
        prefixOr[0] = MCPPolicy.getMCPFactory().getFalse().id();
        for (int i = 1; i < n; i++) {
            prefixOr[i] = prefixOr[i - 1].or(coverage.get(i - 1));
        }
        return prefixOr;
    }

    /**
     * Computes {@code SuffixOr(Iᵢ)} for every intent: the disjunction of the spaces of
     * all the intents following it. The last entry is false.
     *
     * @param coverage the per-intent spaces, in order
     * @return the suffix disjunctions, one per intent
     */
    static MCPBitVector[] suffixOr(List<MCPBitVector> coverage) {
        int n = coverage.size();
        MCPBitVector[] suffixOr = new MCPBitVector[n];
        if (n == 0) {
            return suffixOr;
        }
        suffixOr[n - 1] = MCPPolicy.getMCPFactory().getFalse().id();
        for (int i = n - 2; i >= 0; i--) {
            suffixOr[i] = suffixOr[i + 1].or(coverage.get(i + 1));
        }
        return suffixOr;
    }
}
// END_BEGIN_JOURNAL
