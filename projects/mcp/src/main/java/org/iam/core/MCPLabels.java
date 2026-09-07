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
     * Domain name to set of EC indices.
     */
    protected Map<String, Set<Integer>> _domainToECs;

    /**
     * Domain name to set of static variables.
     */
    protected Map<String, Set<Label>> _domainToLabels;

    /**
     * Domain name to mapping from static variable to its EC indices.
     */
    protected Map<String, Map<Label, Set<Integer>>> _domainToLabelToECs;

    /**
     * Domain name to EC engine (ECEngine supporting first-time and incremental updates).
     */
    protected Map<String, ECEngine> _domainToStandardECs;

    /**
     * Tracks which labels have already been processed by the incremental EC engine per domain.
     * Used to detect new labels on subsequent computeLabels() calls.
     */
    protected Map<String, Set<Label>> _domainToProcessedLabels;

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
        _domainToLabelToECs = new HashMap<>();
        _domainToStandardECs = new HashMap<>();
        _domainToProcessedLabels = new HashMap<>();
        _domainToECs = new HashMap<>();
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
        this.createTrueVariableForEachDomain();
        this.addAllTrueVariables();

        // Batch EC mode (-Dmcp.incremental=false): recompute all ECs from scratch
        // on every updates() call instead of incrementally reusing existing engines.
        if (!getIncrementalMode()) {
            _domainToStandardECs.clear();
            _domainToLabelToECs.clear();
            _domainToECs.clear();
            _domainToProcessedLabels.clear();
        }

        // Initialize processed-labels tracking for all domains sequentially.
        for (String domainName : _domainToLabels.keySet()) {
            _domainToProcessedLabels.computeIfAbsent(domainName, x -> new HashSet<>());
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

    /**
     * Computes the ECs for a single domain (one entry of the domain-to-labels map).
     * Each domain is stored under its own distinct key, so concurrent execution
     * from pool workers is safe.
     */
    private void processDomain(Map.Entry<String, Set<Label>> entry) {
        String k = entry.getKey();
        Set<Label> v = entry.getValue();

        ECEngine existingEngine = _domainToStandardECs.get(k);
        Set<Label> processedLabels = _domainToProcessedLabels.get(k);

        if (existingEngine == null) {
            // First time: create a new incremental engine (batch init internally)
            ECEngine incrementalECs = new ECEngine(
                    ImmutableSet.copyOf(v),
                    _domainToTrueVariable.get(k));

            _domainToLabelToECs.put(k, incrementalECs.getECs());
            _domainToStandardECs.put(k, incrementalECs);
            _domainToECs.put(k,
                    new HashSet<>(incrementalECs.getActiveECIndices()));
            processedLabels.addAll(v);
        } else {
            // Incremental: add only new labels not yet processed
            Set<Label> unprocessedLabels = new HashSet<>(v);
            unprocessedLabels.removeAll(processedLabels);
            if (!unprocessedLabels.isEmpty()) {
                for (Label newLabel : unprocessedLabels) {
                    existingEngine.addLabel(newLabel);
                }
                _domainToLabelToECs.put(k, existingEngine.getECs());
                processedLabels.addAll(unprocessedLabels);
            }
            // Refresh the full EC index set with persistent indices
            _domainToECs.put(k,
                    new HashSet<>(existingEngine.getActiveECIndices()));
        }
    }

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
     * Reads whether incremental EC is enabled from {@code -Dmcp.incremental}.
     * Defaults to {@code true}; set to {@code false} to force the batch
     * (full-rebuild on every updates() call) EC engine.
     */
    private static boolean getIncrementalMode() {
        String v = System.getProperty("mcp.incremental");
        if (v != null) {
            return !(v.equalsIgnoreCase("false") || v.equals("0"));
        }
        return true;
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
