package org.iam.core;

import com.google.common.collect.ImmutableSet;
import org.batfish.datamodel.Prefix;
import org.iam.variables.dynamics.OperableLabel;
import org.iam.variables.statics.Label;
import org.iam.variables.statics.LabelFactory;
import org.iam.variables.statics.LabelType;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

// ADD_BEGIN_JOURNAL
/**
 * Tests the incremental EC partitioning against Technique 1 of the paper (Fig. 9 and
 * Fig. 10): a deployed policy is updated by adding deny rules for two requests, the
 * IpAddress variable is left alone, and the Resource variable's equivalence classes are
 * brought up to date by splitting only the ECs that overlap the newly added label.
 * <p>
 * The paper writes the Resource labels in glob notation (dept-star, dept1/user-star and
 * dept2/user-star); the engine consumes regular expressions, so the wildcards are
 * spelled out here as regexes holding the same sets. See the constants below.
 * <p>
 * Most of the tests here drive {@link IncrementalECPartition} directly, which is the
 * engine itself and ignores the stage switches. The one that goes through
 * {@link MCPLabels#computeLabels()} does not: the incremental EC engine is the
 * Incremental MCP stage's optimization and nothing is on by default, so the stage is
 * selected for the duration of each test rather than assumed.
 */
public class IncrementalECPartitionTest {

    /** {@code -p -i}: MCPLabels takes the incremental EC path only when the stage is on. */
    @Before
    public void selectTheIncrementalMCPStage() {
        PipelineStages.setStages(true, false, true);
    }

    /** Puts the stages back, since nothing is on by default. */
    @After
    public void restoreDefaultStages() {
        PipelineStages.setStages(false, false, false);
    }

    /** Resource labels of Fig. 9. */

    // The paper's dept*/user1.txt: any single "dept" directory, file user1.txt.
    private static final String RES_ONE = "dept.*/user1\\.txt";
    // The paper's dept1/user*.txt: directory dept1, any file name.
    private static final String RES_DEPT1 = "dept1/user.*\\.txt";
    // The label the policy update adds: dept2/user*.txt, i.e. directory dept2, any file.
    private static final String RES_DEPT2 = "dept2/user.*\\.txt";
    /** The whole Resource domain, i.e. the true label. */
    private static final String RES_ANY = ".*";

    /** IpAddress labels of Fig. 9. */
    private static final String IP_FIRST = "112.0.0.0/24";
    private static final String IP_SECOND = "113.0.0.0/24";

    /**
     * Fig. 9 and Fig. 10. Task one partitions Resource by the two labels of the deployed
     * policy, giving the 2x2 grid {@code RES_ONE x RES_DEPT1} of four ECs. The update adds
     * {@code RES_DEPT2}, which overlaps EC 1 ({@code RES_ONE and not RES_DEPT1}) and EC 3
     * ({@code neither}) but neither EC 0 nor EC 2, since those two are inside
     * {@code RES_DEPT1} and {@code RES_DEPT2} is a different directory. Those two ECs are
     * therefore left alone -- indices included -- and ECs 1 and 3 are each split in two,
     * for six ECs in total, exactly as Fig. 10 shows.
     */
    @Test
    public void splitMatchesFigureTen() {
        Label one = label(RES_ONE);
        Label dept1 = label(RES_DEPT1);
        Label dept2 = label(RES_DEPT2);
        Label any = label(RES_ANY);

        IncrementalECPartition partition = partition(one, dept1, any);
        Map<Integer, OperableLabel> beforeSpaces = partition.getECSpaces();
        Assert.assertEquals("Fig. 9 left four ECs behind", 4, beforeSpaces.size());

        IncrementalECPartition.Update update = partition.update(ImmutableSet.of(one, dept1, dept2));

        Assert.assertTrue("the added label makes Resource an affected variable", update.affected());
        Assert.assertEquals(ImmutableSet.of(dept2), ImmutableSet.copyOf(update.addedLabels()));
        Assert.assertEquals("Fig. 10 has six ECs", 6, partition.getNumECs());

        // The six spaces of Fig. 10, built the way the figure draws them.
        OperableLabel resOne = space(RES_ONE);
        OperableLabel resDept1 = space(RES_DEPT1);
        OperableLabel resDept2 = space(RES_DEPT2);
        OperableLabel both = resOne.inter(resDept1);                       // EC 0
        OperableLabel dept1Only = resDept1.minus(resOne);                  // EC 2
        OperableLabel oneNotDept1 = resOne.minus(resDept1);                // EC 1, split into:
        OperableLabel oneNotDept1NotNew = oneNotDept1.minus(resDept2);
        OperableLabel oneNotDept1New = oneNotDept1.inter(resDept2);        // EC 4
        OperableLabel neither = space(RES_ANY).minus(resOne).minus(resDept1);   // EC 3, split into:
        OperableLabel neitherNotNew = neither.minus(resDept2);
        OperableLabel neitherNew = neither.inter(resDept2);                // EC 5

        // The six spaces of the figure and the partition's six ECs have to match up one
        // to one, which is what makes the index set of each label below meaningful.
        Map<Integer, OperableLabel> after = partition.getECSpaces();
        Set<OperableLabel> figureTen = ImmutableSet.of(
                both, dept1Only, oneNotDept1NotNew, oneNotDept1New, neitherNotNew, neitherNew);
        Assert.assertEquals(6, figureTen.size());
        Assert.assertEquals(figureTen.size(), after.size());
        for (OperableLabel space : figureTen) {
            indexOf(after, space);   // each of the six occurs exactly once
        }

        // The mapping M of Fig. 10, read off the EC indices the partition assigned.
        // The paper's {0, 1, 4}, {0, 2} and {4, 5} rows come out here as index sets
        // rather than small integers, since the engine's indices are persistent and
        // need not start from the figure's numbering.
        Map<Label, Set<Integer>> mapping = partition.getECs();
        Assert.assertEquals(indicesOf(after, both, oneNotDept1NotNew, oneNotDept1New), mapping.get(one));
        Assert.assertEquals(indicesOf(after, both, dept1Only), mapping.get(dept1));
        Assert.assertEquals(indicesOf(after, oneNotDept1New, neitherNew), mapping.get(dept2));
        Assert.assertEquals(indicesOf(after, both, dept1Only, oneNotDept1NotNew, oneNotDept1New,
                neitherNotNew, neitherNew), mapping.get(any));

        // "ECs with an empty intersection are unaffected by the new label": the two ECs
        // inside dept1 are the only old ones that survive, and they keep their indices.
        Set<Integer> survived = new HashSet<>(beforeSpaces.keySet());
        survived.retainAll(after.keySet());
        Assert.assertEquals(indicesOf(beforeSpaces, both, dept1Only), survived);
    }

    /**
     * Technique 1, first half: "variables unaffected by the policy update do not need to
     * be reanalyzed". Handing the same label set back in leaves the partition exactly as
     * it was -- no EC recomputed, no index reassigned -- and reports the variable as
     * unaffected, which is what keeps the update's cost off the measurement.
     */
    @Test
    public void unaffectedVariableIsReusedAsIs() {
        Label one = label(RES_ONE);
        Label dept1 = label(RES_DEPT1);
        Label any = label(RES_ANY);

        IncrementalECPartition partition = partition(one, dept1, any);
        Map<Integer, OperableLabel> spacesBefore = new HashMap<>(partition.getECSpaces());
        Map<Label, Set<Integer>> mappingBefore = deepCopy(partition.getECs());

        IncrementalECPartition.Update update = partition.update(ImmutableSet.of(one, dept1, any));

        Assert.assertFalse("an unchanged variable is not reanalyzed", update.affected());
        Assert.assertTrue(update.addedLabels().isEmpty());
        Assert.assertEquals(spacesBefore.keySet(), partition.getECSpaces().keySet());
        Assert.assertEquals(mappingBefore, partition.getECs());
        Assert.assertEquals(4, partition.getNumECs());
    }

    /**
     * The property the whole technique rests on: absorbing labels one mining task at a
     * time has to land on the same partition as partitioning them all at once. Both runs
     * are compared as languages rather than as indices, since the two orders assign the
     * indices differently.
     */
    @Test
    public void incrementalUpdateAgreesWithFullRebuild() {
        Label one = label(RES_ONE);
        Label dept1 = label(RES_DEPT1);
        Label dept2 = label(RES_DEPT2);
        Label any = label(RES_ANY);

        IncrementalECPartition incremental = partition(one, dept1, any);
        incremental.update(ImmutableSet.of(one, dept1, dept2));

        IncrementalECPartition rebuild = new IncrementalECPartition(
                ImmutableSet.of(one, dept1, dept2), any);

        Assert.assertEquals(rebuild.getNumECs(), incremental.getNumECs());
        assertSamePartition(rebuild.getECSpaces(), incremental.getECSpaces());
    }

    /**
     * Fig. 9 through the real entry point: the IpAddress variable is not part of the
     * update, so it keeps its three ECs ({@code 112.0.0.0/24}, {@code 113.0.0.0/24} and
     * the rest) and their indices, while Resource grows from four ECs to six.
     */
    @Test
    public void unaffectedDomainKeepsItsECsAcrossMiningTasks() {
        MCPLabels labels = new MCPLabels();
        labels.addLabel("Resource", LabelType.REGEXP, label(RES_ONE));
        labels.addLabel("Resource", LabelType.REGEXP, label(RES_DEPT1));
        labels.addLabel("IpAddress", LabelType.PREFIX, prefix(IP_FIRST));
        labels.addLabel("IpAddress", LabelType.PREFIX, prefix(IP_SECOND));
        labels.computeLabels();

        Set<Integer> ipBefore = new HashSet<>(labels.getECs("IpAddress"));
        Set<Integer> resourceBefore = new HashSet<>(labels.getECs("Resource"));
        Assert.assertEquals("Fig. 5(b): three ECs for the IP Address variable", 3, ipBefore.size());
        Assert.assertEquals(4, resourceBefore.size());

        labels.addLabel("Resource", LabelType.REGEXP, label(RES_DEPT2));
        labels.computeLabels();

        Assert.assertEquals("the IP Address variable is unaffected", ipBefore, labels.getECs("IpAddress"));
        Assert.assertEquals(6, labels.getECs("Resource").size());
        Assert.assertNotEquals(resourceBefore, labels.getECs("Resource"));
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Helpers
    // ─────────────────────────────────────────────────────────────────────────

    /** Builds a partition of the given labels plus the true label of the domain. */
    private static IncrementalECPartition partition(Label one, Label dept1, Label any) {
        return new IncrementalECPartition(ImmutableSet.of(one, dept1), any);
    }

    /** Creates a Resource label. */
    private static Label label(String regexp) {
        return LabelFactory.createVar(LabelType.REGEXP, regexp);
    }

    /** Creates an IpAddress label. */
    private static Label prefix(String cidr) {
        return LabelFactory.createVar(LabelType.PREFIX, Prefix.parse(cidr));
    }

    /** The space a Resource label covers, as an operable label. */
    private static OperableLabel space(String regexp) {
        return label(regexp).convert();
    }

    /** Two labels cover the same space when neither has anything the other lacks. */
    private static boolean isEquivalent(OperableLabel a, OperableLabel b) {
        return a.minus(b).isEmpty() && b.minus(a).isEmpty();
    }

    /** Finds the index of the EC covering {@code expected}, which must be there once. */
    private static int indexOf(Map<Integer, OperableLabel> spaces, OperableLabel expected) {
        Integer found = null;
        for (Map.Entry<Integer, OperableLabel> entry : spaces.entrySet()) {
            if (isEquivalent(entry.getValue(), expected)) {
                Assert.assertNull("two ECs cover the space of " + expected, found);
                found = entry.getKey();
            }
        }
        Assert.assertNotNull("no EC covers the space of " + expected, found);
        return found;
    }

    /** Collects the indices of several ECs, which must all be distinct. */
    private static Set<Integer> indicesOf(Map<Integer, OperableLabel> spaces, OperableLabel... expected) {
        Set<Integer> indices = new HashSet<>();
        for (OperableLabel space : expected) {
            indices.add(indexOf(spaces, space));
        }
        Assert.assertEquals("the expected spaces must be distinct", expected.length, indices.size());
        return indices;
    }

    /** Checks two partitions cover the same set of spaces, ignoring index numbering. */
    private static void assertSamePartition(Map<Integer, OperableLabel> expected,
                                            Map<Integer, OperableLabel> actual) {
        Assert.assertEquals(expected.size(), actual.size());
        for (OperableLabel space : expected.values()) {
            indexOf(actual, space);
        }
    }

    /** Copies the label-to-ECs mapping so that later mutation of the original is visible. */
    private static Map<Label, Set<Integer>> deepCopy(Map<Label, Set<Integer>> mapping) {
        Map<Label, Set<Integer>> copy = new HashMap<>();
        for (Map.Entry<Label, Set<Integer>> entry : mapping.entrySet()) {
            copy.put(entry.getKey(), new HashSet<>(entry.getValue()));
        }
        return copy;
    }
}
// END_BEGIN_JOURNAL
