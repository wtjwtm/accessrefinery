package org.iam.core;

/**
 * Which stages of the journal extension's optimization pipeline are enabled.
 * <p>
 * The pipeline has three stages, each removing the cost left by the previous one:
 * <ul>
 *   <li><b>Original</b> - the batch engine, no optimization.</li>
 *   <li><b>Pruning Reducer</b> - Original plus the essential-finding pre-filter in the
 *       intent reducer.</li>
 *   <li><b>Incremental MCP</b> - Pruning Reducer plus the miner's refinement-DAG node
 *       construction and BFS early-exit, the incremental EC engine and the cross-policy
 *       shared {@code MCPFactory}.</li>
 * </ul>
 * The three switches below are the optimizations those stages add, and
 * {@code org.iam.core.CmdRun} sets them from its command line: {@code -p/--pruning}
 * turns {@link #pruner()} on, {@code -i/--increment} turns {@link #refinement()} and
 * {@link #incremental()} on, and {@code -o/--mining-optimized} turns only
 * {@link #refinement()} on — the miner's search optimization by itself, the
 * {@code MiningOptimized} configuration of the archived measurements, which is not
 * one of the three stages. Nothing is on by default, so a run with no flag is the
 * Original stage and a run with {@code -p -i} is the fully optimized Incremental MCP
 * stage.
 * <p>
 * This class sits in the MCP module because the EC engine needs the incremental switch
 * too ({@code MCPLabels.getIncrementalMode()}) and that module sits below the refinery,
 * which owns {@code org.iam.utils.Parameter}. {@code Parameter} reads the switches from
 * here, so this is the single source of truth for both modules.
 */
public final class PipelineStages {

    private static boolean pruner;
    private static boolean refinement;
    private static boolean incremental;

    private PipelineStages() {
    }

    /** Whether the essential-finding pre-filter in the intent reducer is on ({@code -p}). */
    public static boolean pruner() {
        return pruner;
    }

    /** Whether the miner's refinement-DAG node construction and BFS early-exit is on ({@code -o} or {@code -i}). */
    public static boolean refinement() {
        return refinement;
    }

    /** Whether the incremental EC engine and cross-policy shared factory are on ({@code -i}). */
    public static boolean incremental() {
        return incremental;
    }

    /**
     * Selects the pipeline's stages from the command line, which is the only place they
     * are chosen.
     *
     * @param pruning          {@code -p/--pruning}: the essential-finding pre-filter in
     *                         the intent reducer.
     * @param miningOptimized  {@code -o/--mining-optimized}: the miner's refinement-DAG
     *                         node construction and BFS early-exit alone, without the
     *                         incremental EC engine below it.
     * @param incrementalMCP   {@code -i/--increment}: those two mining optimizations
     *                         together with the incremental EC engine and the
     *                         cross-policy shared factory.
     */
    public static void setStages(boolean pruning, boolean miningOptimized, boolean incrementalMCP) {
        pruner = pruning;
        refinement = miningOptimized || incrementalMCP;
        incremental = incrementalMCP;
    }
}
