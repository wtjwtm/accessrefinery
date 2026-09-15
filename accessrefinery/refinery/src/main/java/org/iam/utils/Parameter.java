package org.iam.utils;

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

    // ── BR → AR → AM → AI optimization switches ────────────────────────────
    // Each stage of the pipeline can be turned off with -Dopt.<stage>=false so
    // that all four stages can be exercised from a single build:
    //   BR = all three off, AR = opt.ai/am off, AM = opt.ai off, AI = default.
    // All default to true, i.e. leaving them unset gives the fully optimized
    // (AI) pipeline.

    /** -Dopt.ar: essential-finding pre-filter in the intent reducer. */
    public static boolean isOptAR() { return boolProp("opt.ar"); }

    /** -Dopt.am: incremental node computation and BFS early-exit in the miner. */
    public static boolean isOptAM() { return boolProp("opt.am"); }

    /** -Dopt.ai: incremental EC engine and cross-policy shared MCPFactory. */
    public static boolean isOptAI() { return boolProp("opt.ai"); }

    // ── Incremental add-label measurement ──────────────────────────────────
    // -Dmcp.labelinc=true replaces the MCILabelsTimeAverage window with the cost
    // of the single computeLabels() call that absorbs newly added labels, instead
    // of the whole parse + preprocessing + label-tree window. Used by
    // tools/accessrefinery/running_rw_label_inc.sh to measure the incremental
    // engine on the RW corpus; off by default, so the archived summaries keep
    // their usual meaning.

    /** -Dmcp.labelinc=true: report the one computeLabels() call that absorbs new labels. */
    public static boolean isLabelInc() {
        String v = System.getProperty("mcp.labelinc");
        return v != null && (v.equalsIgnoreCase("true") || v.equals("1"));
    }

    /** Reads a boolean system property; absent, "false" or "0" means disabled. */
    private static boolean boolProp(String key) {
        String v = System.getProperty(key);
        return v == null || !(v.equalsIgnoreCase("false") || v.equals("0"));
    }
}