package org.iam.core;

import com.google.common.collect.ImmutableSet;
import net.sf.javabdd.BDDFactory;
import net.sf.javabdd.JFactory;
import org.iam.variables.statics.*;
import org.batfish.datamodel.Prefix;

import com.google.common.collect.Range;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.Callable;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.Future;

/**
 * The MCPLabels class represents a collection of equivalence classes (ECs) across multiple domains.
 * <p>
 * It manages different types of static variable domains and provides methods to calculate and query ECs,
 * as well as to manage the mapping between domain names, variable types, and their ECs.
 * </p>
 *
 * @since 2025-02-28
 */
public class MCPLabels {
    /**
     * Domain name to variable type.
     */
    protected HashMap<String, LabelType> _domainNames;

    /**
     * Domain name to set of EC indices. Published by the EC workers, so it has to
     * be a concurrent map (see the constructor).
     */
    protected Map<String, Set<Integer>> _domainToECs;

    /**
     * Domain name to set of static variables.
     */
    protected Map<String, Set<Label>> _domainToLabels;

    /**
     * Domain name to mapping from static variable to its EC indices.
     * Published by the EC workers, so it has to be a concurrent map (see the constructor).
     */
    protected Map<String, Map<Label, Set<Integer>>> _domainToLabelToECs;

    // ADD_BEGIN_JOURNAL
    /**
     * Domain name to the domain's EC partitioning (Technique 1: built on first sight,
     * then reused and incrementally updated by later computeLabels() calls).
     * Published by the EC workers, so it has to be a concurrent map (see the constructor).
     */
    protected Map<String, IncrementalECPartition> _domainToStandardECs;
    // END_BEGIN_JOURNAL

    /**
     * Domain name to BDDFactory (for BDD dynamic domains).
     */
    protected Map<String, BDDFactory> _domainToBDDFactory;

    /**
     * Domain name to the "true" static variable.
     */
    protected Map<String, Label> _domainToTrueVariable;

    /**
     * Domain name to mapping from object to static variable.
     */
    protected Map<String, Map<Object, Label>> _domainToObjectToLabel;

    /**
     * Process-wide cached parallel EC pool (created lazily, reused across calls).
     */
    private static ForkJoinPool _sharedPool;

    /**
     * Whether the incremental add-label metric is being collected ({@code -Dmcp.labelinc=true}).
     * When on, {@link #computeLabels()} times itself and keeps the elapsed time of the
     * most recent call that actually had new labels to absorb.
     */
    private static final boolean _labelIncMode =
            Boolean.parseBoolean(System.getProperty("mcp.labelinc", "false"));

    /**
     * Set by {@link #processDomain} when a domain had labels it had not processed yet,
     * i.e. when the current {@link #computeLabels()} call did real incremental work.
     */
    private static final java.util.concurrent.atomic.AtomicBoolean _incWorked =
            new java.util.concurrent.atomic.AtomicBoolean();

    /**
     * Elapsed nanoseconds of the most recent {@link #computeLabels()} call that did
     * incremental work, and the number of such calls since the last reset.
     */
    private static final java.util.concurrent.atomic.AtomicLong _incNanos =
            new java.util.concurrent.atomic.AtomicLong();
    private static final java.util.concurrent.atomic.AtomicInteger _incEvents =
            new java.util.concurrent.atomic.AtomicInteger();

    /**
     * Number of workers the cached pool was created with.
     */
    private static int _sharedPoolCores = -1;

    /**
     * Constructs an MCPLabels object.
     * Initializes all the internal maps and prepares the object for handling domain - related operations.
     */
    public MCPLabels() {
        _domainNames = new HashMap<>();
        _domainToLabels = new HashMap<>();
        // The next three are published from the EC worker pool (processDomain) and
        // read by the caller once pool.invokeAll() has returned, so they must be
        // concurrent. A plain HashMap can drop an entry when two workers resize it
        // at the same time; a domain missing from _domainToECs makes
        // MCPFactory.updates() sum too few bits into _numBits and then reserve
        // fewer variables than the domains it builds in the same call, which
        // fails in BDDUtils.bitvector with "Not enough variables to create
        // bitvector".
        _domainToLabelToECs = new ConcurrentHashMap<>();
        _domainToStandardECs = new ConcurrentHashMap<>();
        _domainToECs = new ConcurrentHashMap<>();
        _domainToTrueVariable = new HashMap<>();
        _domainToObjectToLabel = new HashMap<>();
        _domainToBDDFactory = new HashMap<>();
    }

    public HashMap<String, LabelType> getDomainNames() {
        return _domainNames;
    }

    /**
     * Computes the ECs for each domain and updates the relevant maps.
     * First, it creates true variables for each domain. Then, it adds all true variables to the domain's static variables.
     * For each domain, it creates a standard atomic predicate object based on the static variables and the true variable of the domain,
     * and stores the atomic predicate information in the corresponding maps.
     */
    public void computeLabels() {
        if (!_labelIncMode) {
            this.computeLabelsImpl();
            return;
        }
        // -Dmcp.labelinc=true: record the wall time of this call, but only publish it
        // if the call turned out to have new labels to absorb. Calls that find every
        // label already processed are skipped, so what the caller reads afterwards is
        // the cost of the one call that absorbed the newly added label — regardless of
        // which statement (and therefore which call) introduced it.
        _incWorked.set(false);
        long t0 = System.nanoTime();
        this.computeLabelsImpl();
        if (_incWorked.get()) {
            _incNanos.set(System.nanoTime() - t0);
            _incEvents.incrementAndGet();
        }
    }

    /** Resets the incremental add-label metric of {@link #computeLabels()}. */
    public static void resetIncrementalLabelMetric() {
        _incWorked.set(false);
        _incNanos.set(0L);
        _incEvents.set(0);
    }

    /** Number of {@link #computeLabels()} calls that absorbed new labels since the last reset. */
    public static int getIncrementalLabelEvents() {
        return _incEvents.get();
    }

    /** Milliseconds spent by the most recent {@link #computeLabels()} call that absorbed new labels. */
    public static double getIncrementalLabelMillis() {
        return _incNanos.get() / 1_000_000.0;
    }

    /**
     * The EC computation itself, without the add-label metric wrapping of
     * {@link #computeLabels()}.
     */
    private void computeLabelsImpl() {
        this.createTrueVariableForEachDomain();
        this.addAllTrueVariables();

        // Batch EC mode (-Dmcp.incremental=false): recompute all ECs from scratch
        // on every updates() call instead of incrementally reusing existing partitions.
        // ADD_BEGIN_JOURNAL
        // Dropping the partitions also drops the labels they had processed, so the
        // rebuilt partition starts from the current label set.
        // END_BEGIN_JOURNAL
        if (!getIncrementalMode()) {
            _domainToStandardECs.clear();
            _domainToLabelToECs.clear();
            _domainToECs.clear();
        }

        List<Map.Entry<String, Set<Label>>> entries = new ArrayList<>(_domainToLabels.entrySet());

        int cores = getEcCoreCount();
        if (cores == 0) {
            // Pure sequential: "Seq" baseline, no ForkJoin scheduling overhead.
            // (Only cores==0 is truly sequential; cores>=1 uses a dedicated pool,
            //  so mcp.cores=1 exercises the real ForkJoinPool(1) path.)
            for (Map.Entry<String, Set<Label>> entry : entries) {
                processDomain(entry);
            }
            return;
        }

        // Dedicated pool sized by -Dmcp.cores=N. NOTE: Collection.parallelStream()
        // always uses the shared common pool regardless of the calling context, so
        // we parallelize with explicit chunked tasks submitted to this pool.
        // The pool is cached and reused across computeLabels() calls: the
        // incremental EC path invokes computeLabels() once per statement, so
        // creating a pool per call would pay N pool constructions per policy
        // (batch mode only pays 1). ForkJoin worker threads are daemon, so a
        // cached pool never blocks JVM exit.
        ForkJoinPool pool = getSharedPool(cores);
        try {
            int n = entries.size();
            int chunk = Math.max(1, (n + cores - 1) / cores);
            List<Callable<Void>> tasks = new ArrayList<>();
            for (int i = 0; i < n; i += chunk) {
                final int from = i;
                final int to = Math.min(n, i + chunk);
                tasks.add(() -> {
                    for (int j = from; j < to; j++) {
                        processDomain(entries.get(j));
                    }
                    return null;
                });
            }
            List<Future<Void>> futures = pool.invokeAll(tasks);
            for (Future<Void> f : futures) {
                f.get();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Parallel EC computation interrupted", e);
        } catch (ExecutionException e) {
            throw new RuntimeException("Parallel EC computation failed", e.getCause());
        }
        // Pool is cached/shared; do not shutdown here.
    }

    /**
     * Returns a process-wide ForkJoinPool sized by {@code cores}, creating it
     * lazily and reusing it across all computeLabels() calls. A cached pool
     * removes the per-call pool construction/teardown cost that the incremental
     * EC path (which invokes computeLabels() once per statement) would otherwise
     * pay N times per policy.
     */
    private static synchronized ForkJoinPool getSharedPool(int cores) {
        if (_sharedPool == null || _sharedPoolCores != cores) {
            if (_sharedPool != null) {
                _sharedPool.shutdown();
            }
            _sharedPool = new ForkJoinPool(cores);
            _sharedPoolCores = cores;
        }
        return _sharedPool;
    }

    // ADD_BEGIN_JOURNAL
    /**
     * Computes the ECs for a single domain (one entry of the domain-to-labels map),
     * reusing the partition the previous call left behind.
     * <p>
     * A domain seen for the first time gets its partition built; a domain whose label
     * set has not changed since is left exactly as it was, and one that gained labels
     * has only those absorbed. Each domain key is handled by exactly one pool worker,
     * so the per-domain objects it mutates (the partition and the maps it publishes)
     * stay confined to that worker. The maps it publishes into are shared with the
     * other workers, which is why they are concurrent; distinct keys keep the entries
     * themselves from being overwritten by a concurrent worker.
     */
    private void processDomain(Map.Entry<String, Set<Label>> entry) {
        String k = entry.getKey();
        Set<Label> v = entry.getValue();

        IncrementalECPartition partition = _domainToStandardECs.get(k);
        if (partition == null) {
            // First time this domain is seen: build its partition from its labels.
            partition = new IncrementalECPartition(
                    ImmutableSet.copyOf(v),
                    _domainToTrueVariable.get(k));
            _domainToStandardECs.put(k, partition);
        } else if (partition.update(new HashSet<>(v)).affected()) {
            // Affected domain: the partition absorbed the labels this statement added.
            _incWorked.set(true);
        }

        // Republish the label-to-EC mapping and the active indices. Both are the
        // partition's own live objects, so an untouched domain republishes what was
        // already there.
        _domainToLabelToECs.put(k, partition.getECs());
        _domainToECs.put(k, new HashSet<>(partition.getActiveECIndices()));
    }
    // END_BEGIN_JOURNAL

    /**
     * Reads the EC parallel worker count from {@code -Dmcp.cores=N}.
     * <ul>
     *   <li>{@code N <= 0}: pure sequential, no thread pool (the "Seq" baseline).</li>
     *   <li>{@code N > 0}: dedicated ForkJoinPool with exactly N workers.</li>
     *   <li>Unset: defaults to {@code availableProcessors - 1} (preserves prior behavior).</li>
     * </ul>
     */
    private static int getEcCoreCount() {
        String v = System.getProperty("mcp.cores");
        if (v != null) {
            try {
                return Integer.parseInt(v.trim());
            } catch (NumberFormatException ignored) {
                // fall through to default
            }
        }
        return Math.max(1, Runtime.getRuntime().availableProcessors() - 1);
    }

    /**
     * Whether incremental EC is enabled: the MCP module's own {@code -Dmcp.incremental}
     * switch (default on) and the Incremental MCP stage selected on the command line
     * ({@code -i, --increment}, see {@link PipelineStages}). Setting either off forces
     * the batch (full-rebuild on every updates() call) EC engine.
     * <p>
     * The stage flag is read from {@link PipelineStages} rather than through
     * {@code org.iam.utils.Parameter} because this module sits below the refinery and
     * cannot see that class.
     */
    private static boolean getIncrementalMode() {
        return isEnabled(System.getProperty("mcp.incremental"))
                && PipelineStages.incremental();
    }

    /** A property that is absent is enabled; {@code "false"} or {@code "0"} disables it. */
    private static boolean isEnabled(String v) {
        return v == null || !(v.equalsIgnoreCase("false") || v.equals("0"));
    }

    /**
     * Adds a domain variable to the system.
     * If the mapping from domain name to object - static variable map does not exist, it initializes one.
     * If the given object does not have a corresponding static variable in the domain, it creates one.
     * Then, it adds the corresponding static variable to the domain.
     *
     * @param domainName The name of the domain to which the variable will be added.
     * @param type       The type of the static variable.
     * @param value      The value of the variable, which will be used to create the static variable.
     */
    public void addVar(String domainName, LabelType type, Object value) {
        if (!_domainToObjectToLabel.containsKey(domainName)) {
            _domainToObjectToLabel.put(domainName, new HashMap<>());
        }
        if (!_domainToObjectToLabel.get(domainName).containsKey(value)) {
            Label label = LabelFactory.createVar(type, value);
            _domainToObjectToLabel.get(domainName).put(value, label);
        }
        this.addLabel(domainName, type, _domainToObjectToLabel.get(domainName).get(value));
    }

    /**
     * Adds a domain variable to this class.
     * If the domain does not exist, it adds the domain name and its type to the domain names map.
     * If the domain is of PREFIX type, it initializes a BDDFactory for the domain.
     * It also adds the static variable to the set of static variables for the domain.
     *
     * @param domainName The name of the domain.
     * @param type       The type of the static variable in the domain.
     * @param label  The static variable to be added.
     */
    public void addLabel(String domainName, LabelType type, Label label) {
        if (!_domainNames.containsKey(domainName)) {
            if (type.equals(LabelType.PREFIX) || type.equals(LabelType.PREFIX_SET)) {
                BDDFactory bddFactory = JFactory.init(1000, 1000);
                bddFactory.setVarNum(32);
                bddFactory.setCacheRatio(64);
                _domainToBDDFactory.put(domainName, bddFactory);
            }
        }
        if (!_domainToLabels.containsKey(domainName)) {
            _domainToLabels.put(domainName, new HashSet<>());
        }
        _domainNames.put(domainName, type);
        if(type.equals(LabelType.PREFIX)) {
            ((PrefixLabel) label).setBddFactory(_domainToBDDFactory.get(domainName));
        }
        if(type.equals(LabelType.PREFIX_SET)) {
            ((PrefixSetLabel) label).setBddFactory(_domainToBDDFactory.get(domainName));
        }
        _domainToLabels.get(domainName).add(label);
    }

    /**
     * Retrieves the set of ECs for a given domain.
     *
     * @param domainName The name of the domain.
     * @return The set of ECs for the domain, or null if the domain does not exist.
     */
    public Set<Integer> getECs(String domainName) {
        return _domainToECs.get(domainName);
    }

    /**
     * Retrieves the set of ECs for a specific variable within a given domain.
     * First, it gets the corresponding static variable from the object - static variable map.
     * Then, it calls the method to get the ECs for the static variable.
     *
     * @param domainName The name of the domain.
     * @param var        The variable for which the ECs are to be retrieved.
     * @return The set of ECs for the variable in the domain, or null if the domain or variable does not exist.
     */
    public Set<Integer> getVarECs(String domainName, Object var) {
        return getLabelECs(domainName, this._domainToObjectToLabel.get(domainName).get(var));
    }

    /**
     * Retrieves the set of ECs for a specific static variable within a given domain.
     *
     * @param domainName The name of the domain.
     * @param var        The static variable.
     * @return The set of ECs for the static variable in the domain, or null if the domain or variable does not exist.
     */
    public Set<Integer> getLabelECs(String domainName, Label var) {
        return _domainToStandardECs.get(domainName)
                .getECs()
                .get(var);
    }

    /**
     * Gets the domain children nodes for a given domain.
     * It calculates the relationships between static variables in the domain based on the isContain method.
     *
     * @param domainName The name of the domain.
     * @return A map where keys are static variables and values are sets of their child static variables.
     */
    public HashMap<Object, HashSet<Object>> getDomainChildrenNodes(String domainName) {
        HashMap<Object, HashSet<Object>> nodeToChildren = new HashMap<>();
        Set<Label> vars = _domainToLabels.get(domainName);
        vars.forEach(v -> vars.forEach(k -> {
            if (this.isContain(domainName, v, k)) {
                nodeToChildren.computeIfAbsent(v.getValue(), key -> new HashSet<>()).add(k.getValue());
            }
        }));
        return nodeToChildren;
    }

    /**
     * Checks if one static variable contains another within a given domain.
     * It determines the containment relationship based on whether the ECs of one variable contain all the ECs of the other.
     *
     * @param domainName The name of the domain.
     * @param var1       The first static variable.
     * @param var2       The second static variable.
     * @return true if var1 contains var2, false otherwise.
     */
    public boolean isContain(String domainName, Label var1, Label var2) {
        return _domainToLabelToECs.get(domainName).get(var1)
                .containsAll(_domainToLabelToECs.get(domainName).get(var2));
    }

    /**
     * Adds all true variables to the corresponding domains.
     * Iterates over the map of true variables and adds each true variable to its corresponding domain.
     */
    private void addAllTrueVariables() {
        _domainToTrueVariable.forEach((k, v) -> addVar(k, _domainNames.get(k), v.getValue()));
    }

    /**
     * Creates a true variable for each domain based on its type.
     * It iterates over all the domain names and their types, and creates a corresponding true variable using the LabelFactory.
     */
    private void createTrueVariableForEachDomain() {
        _domainNames.forEach((k, type) -> {
            if (_domainToTrueVariable.containsKey(k)) {
                // True variables are deterministic per (domain, type); create them
                // once and reuse across computeLabels() calls. The incremental EC
                // path invokes computeLabels() once per statement, so without this
                // guard it would regenerate every true variable N times per policy
                // (batch mode only does it once).
                return;
            }
            switch (type) {
                case REGEXP:
                    _domainToTrueVariable.put(k,
                            LabelFactory.createVar(LabelType.REGEXP, ".*"));
                    break;
                case REGEXP_SET:
                    _domainToTrueVariable.put(k,
                            LabelFactory.createVar(LabelType.REGEXP_SET, ImmutableSet.of(".*")));
                    break;
                case RANGE:
                    _domainToTrueVariable.put(k,
                            LabelFactory.createVar(LabelType.RANGE, Range.atLeast(0)));
                    break;
                case RANGE_SET:
                    _domainToTrueVariable.put(k,
                            LabelFactory.createVar(LabelType.RANGE_SET, ImmutableSet.of(Range.atLeast(0))));
                    break;
                case INTEGER_SET:
                    // Here, we assume that the element is no more than 200, or else we could encode these elements with BDD
                    _domainToTrueVariable.put(k,
                            LabelFactory.createVar(LabelType.INTEGER_SET, IntegerSetLabel.getAllVariable(0, 200)));
                    break;
                case INTEGER_SET_SET:
                    _domainToTrueVariable.put(k,
                            LabelFactory.createVar(LabelType.INTEGER_SET_SET, ImmutableSet.of(IntegerSetLabel.getAllVariable(0, 1000))));
                    break;
                case PREFIX:
                    Label label1 = LabelFactory.createVar(LabelType.PREFIX, Prefix.parse("1.0.0.0/0"));
                    ((PrefixLabel) label1).setBddFactory(_domainToBDDFactory.get(k));
                    _domainToTrueVariable.put(k, label1);
                    break;
                case PREFIX_SET:
                    Label label2 = LabelFactory.createVar(LabelType.PREFIX_SET, ImmutableSet.of(Prefix.parse("1.0.0.0/0")));
                    ((PrefixSetLabel) label2).setBddFactory(_domainToBDDFactory.get(k));
                    _domainToTrueVariable.put(k, label2);
                    break;
            }
        });
    }
}
