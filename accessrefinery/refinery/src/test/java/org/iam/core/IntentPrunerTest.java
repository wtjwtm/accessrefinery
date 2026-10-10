package org.iam.core;

import com.google.common.collect.Collections2;
import org.batfish.datamodel.Prefix;
import org.iam.core.MCPFactory.MCPType;
import org.iam.intent.MCPIntent;
import org.iam.policy.model.MCPPolicy;
import org.iam.variables.statics.LabelType;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.IdentityHashMap;
import java.util.List;
import java.util.Set;

// ADD_BEGIN_JOURNAL
/**
 * Tests the intent pruner against the running example of the paper (Fig. 2, Fig. 3
 * and Fig. 6): a policy over the two domains Resource and IpAddress together with the
 * four candidate intents I6, I7, I8 and I9 that refinement produces out of it.
 * <p>
 * Fig. 2 allows Statement1 and then denies Statement2 and Statement3, so the policy
 * space is the whole label grid minus the two denied regions. Fig. 3 refines it into
 * the four intents {@code I6 = (RES_ALLOWED, IP_FIRST)},
 * {@code I7 = (RES_ALLOWED, IP_SECOND)}, {@code I8 = (RES_PARTIAL, IP_FIRST)} and
 * {@code I9 = (RES_PARTIAL, IP_SECOND)}, which is the 2×2 grid of Fig. 6(b).
 */
public class IntentPrunerTest {

    /** Resource labels of Fig. 2, i.e. the two values Fig. 6(a) splits the domain into. */
    private static final String RES_ALLOWED = "dept*/user1.txt";
    private static final String RES_PARTIAL = "dept1/user*.txt";
    /** IpAddress labels of Fig. 2. */
    private static final String IP_FIRST = "112.0.0.0/24";
    private static final String IP_SECOND = "113.0.0.0/24";

    private MCPFactory mcp;

    @Before
    public void setUp() {
        mcp = new MCPFactory(MCPType.BDD);
        mcp.addVar("Resource", LabelType.REGEXP, RES_ALLOWED);
        mcp.addVar("Resource", LabelType.REGEXP, RES_PARTIAL);
        mcp.addVar("IpAddress", LabelType.PREFIX, Prefix.parse(IP_FIRST));
        mcp.addVar("IpAddress", LabelType.PREFIX, Prefix.parse(IP_SECOND));
        mcp.updates();
        // The pruner reads the false node through the policy model's static factory,
        // and an intent builds its node from the static intent factory.
        MCPPolicy.setMCPFactory(mcp);
        MCPIntent.setMCPLabelsFactory(mcp);
    }

    /**
     * The paper's example: I6 and I9 each own a space inside the policy that no other
     * candidate covers (Fig. 6(c)), so they are necessary, while I7 and I8 are denied
     * by Statement3 and Statement2 respectively and own nothing inside the policy.
     */
    @Test
    public void prunesTheFourIntentsOfFigureSix() {
        MCPIntent i6 = intent(RES_ALLOWED, IP_FIRST);
        MCPIntent i7 = intent(RES_ALLOWED, IP_SECOND);
        MCPIntent i8 = intent(RES_PARTIAL, IP_FIRST);
        MCPIntent i9 = intent(RES_PARTIAL, IP_SECOND);

        IntentPruner.Result pruned = IntentPruner.prune(Arrays.asList(i6, i7, i8, i9), paperPolicy());

        Assert.assertEquals(identitySet(i6, i9), identitySet(pruned.essential()));
        Assert.assertEquals(identitySet(i7, i8), identitySet(pruned.candidates()));
        // I6 ∪ I9 already covers the policy of Fig. 2, so the set cover has nothing
        // left to do on Fig. 6 -- which is what "I6 and I9 are selected" means.
        Assert.assertTrue(pruned.remainingPolicy().isZero());
    }

    /**
     * Definition 3 of the paper: PrefixOr(I_i) stands for the union of the intents
     * before I_i and SuffixOr(I_i) for the union of those after it, with false at the
     * ends. The paper lists the eight values for I6..I9; this checks the same, on the
     * intent spaces already intersected with the policy (the pruner only ever needs
     * the union inside the policy, so it intersects once instead of at every step).
     */
    @Test
    public void prefixOrAndSuffixOrFollowDefinitionThree() {
        MCPIntent i6 = intent(RES_ALLOWED, IP_FIRST);
        MCPIntent i7 = intent(RES_ALLOWED, IP_SECOND);
        MCPIntent i8 = intent(RES_PARTIAL, IP_FIRST);
        MCPIntent i9 = intent(RES_PARTIAL, IP_SECOND);
        MCPBitVector policy = paperPolicy();

        MCPBitVector c6 = i6.getMCPNode().and(policy);
        MCPBitVector c7 = i7.getMCPNode().and(policy);
        MCPBitVector c8 = i8.getMCPNode().and(policy);
        MCPBitVector c9 = i9.getMCPNode().and(policy);
        List<MCPBitVector> coverage = Arrays.asList(c6, c7, c8, c9);

        MCPBitVector[] prefixOr = IntentPruner.prefixOr(coverage);
        Assert.assertTrue(isEquivalent(mcp.getFalse(), prefixOr[0]));          // PrefixOr(I6) = ⊥
        Assert.assertTrue(isEquivalent(c6, prefixOr[1]));                      // PrefixOr(I7) = I6
        Assert.assertTrue(isEquivalent(c6.or(c7), prefixOr[2]));               // PrefixOr(I8) = I6 ∨ I7
        Assert.assertTrue(isEquivalent(c6.or(c7).or(c8), prefixOr[3]));        // PrefixOr(I9) = I6 ∨ I7 ∨ I8

        MCPBitVector[] suffixOr = IntentPruner.suffixOr(coverage);
        Assert.assertTrue(isEquivalent(c7.or(c8).or(c9), suffixOr[0]));        // SuffixOr(I6) = I7 ∨ I8 ∨ I9
        Assert.assertTrue(isEquivalent(c8.or(c9), suffixOr[1]));               // SuffixOr(I7) = I8 ∨ I9
        Assert.assertTrue(isEquivalent(c9, suffixOr[2]));                      // SuffixOr(I8) = I9
        Assert.assertTrue(isEquivalent(mcp.getFalse(), suffixOr[3]));          // SuffixOr(I9) = ⊥
    }

    /**
     * The prefix/suffix scan replaces the definitional check, which compares every
     * intent against every other intent. Both have to agree on every input, so this
     * runs the four intents of Fig. 6 through all 24 orders and compares the pruner's
     * answer with the O(|S|²) definition computed here.
     */
    @Test
    public void agreesWithTheQuadraticDefinitionForEveryOrder() {
        MCPIntent i6 = intent(RES_ALLOWED, IP_FIRST);
        MCPIntent i7 = intent(RES_ALLOWED, IP_SECOND);
        MCPIntent i8 = intent(RES_PARTIAL, IP_FIRST);
        MCPIntent i9 = intent(RES_PARTIAL, IP_SECOND);
        List<MCPIntent> findings = Arrays.asList(i6, i7, i8, i9);
        MCPBitVector policy = paperPolicy();

        Set<MCPIntent> necessary = necessaryByDefinition(findings, policy);
        Assert.assertEquals(identitySet(i6, i9), necessary);

        for (List<MCPIntent> order : Collections2.permutations(findings)) {
            IntentPruner.Result pruned = IntentPruner.prune(order, policy);
            Assert.assertEquals(order.toString(), necessary, identitySet(pruned.essential()));
            // Every intent lands in exactly one of the two lists.
            Assert.assertEquals(order.size(), pruned.essential().size() + pruned.candidates().size());
        }
    }

    /**
     * Neither intent of an overlapping pair is necessary when the policy only allows
     * the part they share: each one's unique space lies outside the policy, so both
     * have to go through EC partitioning instead of being taken for free.
     */
    @Test
    public void keepsOverlappingIntentsForTheSetCover() {
        MCPIntent i6 = intent(RES_ALLOWED, IP_FIRST);
        MCPIntent i8 = intent(RES_PARTIAL, IP_FIRST);
        // The requests matching both Resource labels, from the first IpAddress half.
        MCPBitVector policy = resource(RES_ALLOWED).and(resource(RES_PARTIAL)).and(ipAddress(IP_FIRST));

        IntentPruner.Result pruned = IntentPruner.prune(Arrays.asList(i6, i8), policy);

        Assert.assertTrue(pruned.essential().isEmpty());
        Assert.assertEquals(identitySet(i6, i8), identitySet(pruned.candidates()));
        Assert.assertTrue(isEquivalent(policy, pruned.remainingPolicy()));
    }

    /**
     * Boundary cases: no candidate at all, a single candidate, and a candidate that
     * falls entirely outside the policy. An intent outside the policy owns no unique
     * space inside it, so it must not be taken as necessary.
     */
    @Test
    public void handlesEmptySingleAndDisjointInputs() {
        MCPBitVector policy = paperPolicy();

        IntentPruner.Result none = IntentPruner.prune(Collections.emptyList(), policy);
        Assert.assertTrue(none.essential().isEmpty());
        Assert.assertTrue(none.candidates().isEmpty());
        Assert.assertTrue(isEquivalent(policy, none.remainingPolicy()));

        MCPIntent i6 = intent(RES_ALLOWED, IP_FIRST);
        IntentPruner.Result single = IntentPruner.prune(Collections.singletonList(i6), policy);
        Assert.assertEquals(identitySet(i6), identitySet(single.essential()));
        Assert.assertTrue(single.candidates().isEmpty());
        Assert.assertTrue(isEquivalent(policy.diff(i6.getMCPNode()), single.remainingPolicy()));

        // I7 is denied by Statement3, so it covers nothing the policy allows.
        MCPIntent i7 = intent(RES_ALLOWED, IP_SECOND);
        IntentPruner.Result disjoint = IntentPruner.prune(Collections.singletonList(i7), policy);
        Assert.assertTrue(disjoint.essential().isEmpty());
        Assert.assertEquals(identitySet(i7), identitySet(disjoint.candidates()));
        Assert.assertTrue(isEquivalent(policy, disjoint.remainingPolicy()));
    }

    /**
     * Builds an intent over the two domains of Fig. 2.
     *
     * @param resource the Resource value
     * @param ipAddress the IpAddress value
     * @return the intent
     */
    private MCPIntent intent(String resource, String ipAddress) {
        MCPIntent intent = new MCPIntent();
        intent.setDomainValue("Resource", resource);
        intent.setDomainValue("IpAddress", ipAddress);
        return intent;
    }

    /**
     * Returns the space of one Resource label.
     *
     * @param value the Resource value
     * @return the label's space
     */
    private MCPBitVector resource(String value) {
        return mcp.getVar("Resource", value);
    }

    /**
     * Returns the space of one IpAddress label.
     *
     * @param value the IpAddress value
     * @return the label's space
     */
    private MCPBitVector ipAddress(String value) {
        return mcp.getVar("IpAddress", Prefix.parse(value));
    }

    /**
     * The policy of Fig. 2: Statement1 allows both Resource labels under both
     * IpAddress values, Statement2 denies the requests that match neither the first
     * Resource label nor the first IpAddress value, and Statement3 denies the requests
     * that match neither the second Resource label nor the second IpAddress value.
     *
     * @return the policy space
     */
    private MCPBitVector paperPolicy() {
        MCPBitVector allow = resource(RES_ALLOWED).or(resource(RES_PARTIAL))
                .and(ipAddress(IP_FIRST).or(ipAddress(IP_SECOND)));
        MCPBitVector denyStatement2 = resource(RES_ALLOWED).not().and(ipAddress(IP_FIRST));
        MCPBitVector denyStatement3 = resource(RES_PARTIAL).not().and(ipAddress(IP_SECOND));
        return allow.diff(denyStatement2).diff(denyStatement3);
    }

    /**
     * The definitional wording: an intent is necessary when its own space minus the
     * space of all the other candidates still intersects the policy. This is the
     * O(|S|²) check the prefix/suffix scan is meant to replace.
     *
     * @param findings the candidate intents
     * @param policySpace the policy space
     * @return the necessary intents, compared by identity
     */
    private static Set<MCPIntent> necessaryByDefinition(List<MCPIntent> findings, MCPBitVector policySpace) {
        Set<MCPIntent> necessary = identitySet();
        for (MCPIntent finding : findings) {
            MCPBitVector unique = finding.getMCPNode().and(policySpace);
            for (MCPIntent other : findings) {
                if (other != finding) {
                    unique = unique.diff(other.getMCPNode().and(policySpace));
                }
            }
            if (!unique.isZero()) {
                necessary.add(finding);
            }
        }
        return necessary;
    }

    /**
     * Checks two spaces for equality by comparing them both ways, since two BDDs for
     * the same space need not be the same node object.
     *
     * @param expected the expected space
     * @param actual the actual space
     * @return true when both spaces contain the same requests
     */
    private static boolean isEquivalent(MCPBitVector expected, MCPBitVector actual) {
        return expected.diff(actual).or(actual.diff(expected)).isZero();
    }

    /**
     * Collects intents into a set that compares them by identity, so that two distinct
     * candidates carrying the same domain values stay distinct.
     *
     * @param intents the intents to collect
     * @return the identity set
     */
    private static Set<MCPIntent> identitySet(MCPIntent... intents) {
        Set<MCPIntent> set = identitySet();
        Collections.addAll(set, intents);
        return set;
    }

    /**
     * Collects intents into a set that compares them by identity.
     *
     * @param intents the intents to collect
     * @return the identity set
     */
    private static Set<MCPIntent> identitySet(Collection<MCPIntent> intents) {
        Set<MCPIntent> set = identitySet();
        set.addAll(intents);
        return set;
    }

    /**
     * Creates an empty set that compares intents by identity.
     *
     * @return the empty identity set
     */
    private static Set<MCPIntent> identitySet() {
        return Collections.newSetFromMap(new IdentityHashMap<>());
    }
}
// END_BEGIN_JOURNAL
