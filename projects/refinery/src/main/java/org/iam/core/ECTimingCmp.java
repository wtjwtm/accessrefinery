package org.iam.core;

import com.google.common.collect.ImmutableSet;
import org.iam.policy.grammer.Policy;
import org.iam.policy.grammer.Statement;
import org.iam.utils.Parameter;
import org.iam.utils.PolicyParser;
import org.iam.variables.statics.Label;
import org.iam.variables.statics.LabelFactory;
import org.iam.variables.statics.LabelType;

import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Standalone EC micro-benchmark comparing, per policy, the full rebuild of the
 * Resource-domain EC engine against incrementally adding a single new label.
 *
 * <p>For each policy we:</p>
 * <ul>
 *   <li><b>Full</b>:  {@code new ECEngine(allResourceLabels ∪ {newLabel}, trueLabel)} — rebuilds every EC.</li>
 *   <li><b>Incremental</b>: {@code new ECEngine(allResourceLabels, trueLabel)} (NOT timed), then time
 *       {@code addLabel(newLabel)} — only the single-label delta.</li>
 * </ul>
 *
 * <p>Repetitions are run and the <em>minimum</em> per metric is kept to suppress GC/JIT noise.</p>
 *
 * <p>Usage: {@code java -cp refinery.jar org.iam.core.ECTimingCmp <rwDir> <outFile> [reps]}</p>
 *
 * <p>Output: tab-separated {@code <index>\t<fullMs>\t<incMs>} lines (index is stable 0-based per input file).</p>
 */
public class ECTimingCmp {

    // The new label injected into the Resource domain for each policy.
    private static final String NEW_LABEL_VALUE = "s3:::886499mir";
    private static final String TRUE_VALUE = ".*";

    public static void main(String[] args) throws IOException {
        Path rwDir = Path.of(args[0]);
        Path outFile = Path.of(args[1]);
        int reps = args.length > 2 ? Integer.parseInt(args[2]) : 5;

        List<Path> files = new ArrayList<>();
        try (var stream = Files.list(rwDir)) {
            stream.filter(f -> f.getFileName().toString().toLowerCase().endsWith(".json"))
                    .sorted(Comparator.comparing(p -> p.getFileName().toString()))
                    .forEach(files::add);
        }

        boolean split = Parameter.isSplitLabel;
        Label trueLabel = split
                ? LabelFactory.createVar(LabelType.REGEXP, TRUE_VALUE)
                : LabelFactory.createVar(LabelType.REGEXP_SET, ImmutableSet.of(TRUE_VALUE));
        Label newLabel = split
                ? LabelFactory.createVar(LabelType.REGEXP, NEW_LABEL_VALUE)
                : LabelFactory.createVar(LabelType.REGEXP_SET, ImmutableSet.of(NEW_LABEL_VALUE));

        try (PrintWriter w = new PrintWriter(outFile.toFile())) {
            int index = 0;
            for (Path p : files) {
                Policy policy = PolicyParser.parseFile(p);
                if (policy == null) {
                    System.err.println("SKIP (parse null): " + p);
                    continue;
                }

                Set<Label> labels = collectResourceLabels(policy);

                // Full rebuild includes the new label.
                Set<Label> fullSet = new HashSet<>(labels);
                fullSet.add(newLabel);

                // Warm up JIT + automaton construction so the timed runs are steady.
                warmup(fullSet, labels, trueLabel, newLabel);

                long fullMin = Long.MAX_VALUE;
                long incMin = Long.MAX_VALUE;
                for (int r = 0; r < reps; r++) {
                    long t0 = System.nanoTime();
                    new ECEngine(fullSet, trueLabel);
                    long t1 = System.nanoTime();
                    fullMin = Math.min(fullMin, t1 - t0);

                    ECEngine engine = new ECEngine(labels, trueLabel);
                    long t2 = System.nanoTime();
                    engine.addLabel(newLabel);
                    long t3 = System.nanoTime();
                    incMin = Math.min(incMin, t3 - t2);
                }

                w.printf("%d\t%.3f\t%.3f%n", index, fullMin / 1e6, incMin / 1e6);
                index++;
            }
        }
    }

    /** Warm up both paths once so lazily-built BDD/automaton data does not pollute the timed runs. */
    private static void warmup(Set<Label> fullSet, Set<Label> labels, Label trueLabel, Label newLabel) {
        new ECEngine(fullSet, trueLabel);
        ECEngine e = new ECEngine(labels, trueLabel);
        e.addLabel(newLabel);
    }

    /**
     * Collects the Resource-domain labels for a policy, exactly mirroring
     * {@code MCPStatement.initialMCPFactory} (split vs REGEXP_SET based on
     * {@code Parameter.isSplitLabel}).
     */
    private static Set<Label> collectResourceLabels(Policy policy) {
        Set<Label> labels = new HashSet<>();
        if (policy.getStatement() == null) {
            return labels;
        }
        for (Statement s : policy.getStatement()) {
            if (s == null || s.getResource() == null) {
                continue;
            }
            if (Parameter.isSplitLabel) {
                for (String r : s.getResource()) {
                    labels.add(LabelFactory.createVar(LabelType.REGEXP, r));
                }
            } else {
                labels.add(LabelFactory.createVar(LabelType.REGEXP_SET, ImmutableSet.copyOf(s.getResource())));
            }
        }
        return labels;
    }
}
