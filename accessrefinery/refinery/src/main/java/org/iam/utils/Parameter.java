package org.iam.utils;

import org.iam.core.PipelineStages;

import java.util.logging.Logger;

/**
 * Global parameters and flags for controlling AccessRefinery behavior.
 * <p>
 * This class holds static configuration options and runtime flags
 * used throughout the application.
 * </p>
 */
public class Parameter {
    /** Enable or disable time logging. */
    public static boolean   isTimeLog      =   false;
    /** Logger instance for findings and general logging. */
    public static Logger    LOGGER         =   Logger.getLogger("Findings AccessRefinery");
    /** Stores time log information as a string. */
    public static String    timeLog        =   "";
    /** Treat the list of values as a whole label, e.g., IAM:[User1, User2]. */
    public static boolean   isSplitLabel   =   true;
    /** If true, use the whole space minus the finding when mining findings. */
    public static boolean   isRestMode     =   false;
    /** Whether to reduce the findings. */
    public static boolean   isReduced      =   false;
    /** Whether to merge results or findings. */
    public static boolean   isMerged       =   false;
    /** Current round or iteration count. */
    public static int       round          =   1;
    /** Enable or disable BDD (Binary Decision Diagram) mode. */
    public static boolean   isBDD          =   true;

    // ── Optimization stages, as selected on the command line ───────────────
    // The three stages of the pipeline can be exercised from a single build:
    //   Original        = java -jar target/accessrefinery-1.0.jar -m -r ...
    //   Pruning Reducer = ... -p
    //   Incremental MCP = ... -p -i
    // The MiningOptimized configuration the archive also carries is the mining half
    // of that last one, and is selected by -o on its own.
    // Nothing is on by default; CmdRun sets the switches in
    // org.iam.core.PipelineStages, which is where the three flags below read them.

    /** The essential-finding pre-filter in the intent reducer ({@code -p, --pruning}). */
    public static boolean isOptPruner() { return PipelineStages.pruner(); }

    /** The miner's refinement-DAG node construction and BFS early-exit ({@code -o} or {@code -i}). */
    public static boolean isOptRefinement() { return PipelineStages.refinement(); }

    /** The incremental EC engine and cross-policy shared MCPFactory ({@code -i, --increment}). */
    public static boolean isOptIncremental() { return PipelineStages.incremental(); }

    // ── Incremental add-label measurement ──────────────────────────────────
    // -Dmcp.labelinc=true replaces the MCILabelsTimeAverage window with the cost
    // of the single computeLabels() call that absorbs newly added labels, instead
    // of the whole parse + preprocessing + label-tree window. It measures the
    // incremental engine on a policy whose labels have already been processed;
    // off by default, so the archived summaries keep their usual meaning.

    /** -Dmcp.labelinc=true: report the one computeLabels() call that absorbs new labels. */
    public static boolean isLabelInc() {
        String v = System.getProperty("mcp.labelinc");
        return v != null && (v.equalsIgnoreCase("true") || v.equals("1"));
    }
}