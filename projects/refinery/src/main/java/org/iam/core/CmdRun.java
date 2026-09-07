package org.iam.core;
import org.iam.intent.JsonIntent;
import org.iam.intent.MCPIntent;
import org.iam.utils.FileUtil;
import org.iam.utils.LoggerUtil;
import org.iam.utils.Parameter;
import org.iam.utils.ResultsAnalyzer;
import org.iam.policy.model.MCPPolicy;
import org.apache.commons.cli.*;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;

/**
 * Command-line entry point for running AccessRefinery and Zelkova batch processing.
 * <p>
 * Parses command-line arguments, sets parameters, and invokes mining or checking routines
 * for input files or directories.
 * </p>
 *
 * <ul>
 *   <li>-h, --help: Show help information</li>
 *   <li>-m, --mining: Enable mining mode (findings extraction)</li>
 *   <li>-r, --reducing: Enable reduction of findings</li>
 *   <li>-f, --file: Specify the input path for constraint files</li>
 *   <li>-s, --sat: Use SAT as the solving core (default is BDD)</li>
 *   <li>--round: Set the number of mining rounds</li>
 *   <li>--zelkova: Run Zelkova mode</li>
 *   <li>--rest: Enable REST mode</li>
 *   <li>--merge: Merge intents in output</li>
 * </ul>
 *
 * @author
 * @since 2025-02-28
 */
public class CmdRun {
    public static void run(String[] args) {
        Parameter.isTimeLog = true;
        Parameter.LOGGER = LoggerUtil.configureLogging(System.getProperty("user.dir") + "/accessrefinery.log");
        LoggerUtil.modifyLoggerLevel(Parameter.LOGGER, Level.INFO);

        Options options = new Options();
        options.addOption("h", "help", false, "Show help information");
        options.addOption("m", "mine", false, "Enable mining mode (extract findings)");
        options.addOption("r", "reduce", false, "Enable reduction of findings");
        options.addOption("f", "file", true, "Input path for constraint files");
        options.addOption("s", "sat", false, "Use SAT as solving core (default is BDD)");
        options.addOption(null, "round", true, "Number of mining rounds");
        options.addOption(null, "zelkova", false, "Run Zelkova mode");
        options.addOption(null, "rest", false, "Enable REST mode");
        options.addOption(null, "merge", false, "Merge intents in output");

        CommandLineParser parser = new DefaultParser();
        try {
            CommandLine cmd = parser.parse(options, args);

            if (cmd.hasOption("h")) {
                HelpFormatter formatter = new HelpFormatter();
                formatter.printHelp("the help of accessrefinery", options);
                return;
            } 

            if (cmd.hasOption("s")) {
                Parameter.isBDD = false;
            } else {
                Parameter.isBDD = true;
            }

            if (cmd.hasOption("round")) {
                Parameter.round = Integer.parseInt(cmd.getOptionValue("round"));
            }
            
            if (cmd.hasOption("r")) {
                Parameter.isReduced = true;
            }

            if (cmd.hasOption("rest")) {
                Parameter.isRestMode = true;
            }

            if (cmd.hasOption("merge")) {
                Parameter.isMerged = true;
            }

            if (cmd.hasOption("m") && cmd.hasOption("f")) {
                String filePath = cmd.getOptionValue("f");
                runBatchAccessRefinery(filePath);
            } else if (cmd.hasOption("zelkova") && cmd.hasOption("f")) {
                String filePath = cmd.getOptionValue("f");
                runBatchZelkova(filePath);
            }

        } catch (ParseException | IOException e) {
            Parameter.LOGGER.severe("Parsing failed.  Reason: " + e.getMessage());
        }
    }

    static int policiesIdx = 0;
    public static void runBatchAccessRefinery(String input) throws IOException {
        Path inputFoldPath = Paths.get(input);
        Path outputFoldPath = FileUtil.replaceSecondLastLevel(inputFoldPath);
        FileUtil.createDirectoryIfNotExists(outputFoldPath);
        Parameter.LOGGER.info("----------[ AccessRefinery Mode ]-------------");
        Parameter.LOGGER.info("logger path: " + LoggerUtil.getLogFilePath());
        Parameter.LOGGER.info("input  path: " + inputFoldPath);
        Parameter.LOGGER.info("output path: " + outputFoldPath);
        List<String> fileNames = FileUtil.getFileNames(inputFoldPath);
        ResultsAnalyzer resultsAnalyzer = new ResultsAnalyzer();
        resultsAnalyzer.writeHeaderToFile(outputFoldPath.resolve("summary.txt").toString());

        // Cross-policy incremental batch: the loop is ROUND-OUTER, POLICY-INNER.
        // Each round is one complete cross-policy sweep (policies 1..N in order),
        // sharing a SINGLE MCPFactory across policies so that policy k+1 only
        // incrementally adds its new statement's labels to the EC state built by
        // policies 1..k. The factory is rebuilt at the start of every round, so
        // each round independently re-measures the incremental EC cost, and the
        // per-policy times below are the mean over Parameter.round fresh sweeps.
        // (This keeps the cross-policy benefit while making round=10 a fair,
        //  non-diluted comparison against batch mode.)
        int round = Parameter.round;
        // -Dinc.independent=true: each policy gets its own fresh MCPFactory, so no
        // EC/BDD state accumulates across policies ("各数据无关联"). Default (false)
        // keeps the original cross-policy shared-factory behaviour.
        boolean independent = Boolean.parseBoolean(System.getProperty("inc.independent", "false"));
        Map<String, double[][]> acc = new LinkedHashMap<>();   // [round][labels,ops,rriOps,rriIlp]
        Map<String, int[]> meta = new LinkedHashMap<>();     // [stmt,mci,rri,mciRound]
        Map<String, HashSet<MCPIntent>> findingsByFile = new LinkedHashMap<>();
        for (String fileName : fileNames) {
            acc.put(fileName, new double[round][4]);
            meta.put(fileName, new int[4]);
        }

        for (int r = 0; r < round; r++) {
            MCPFactory mcpFactory;
            if(Parameter.isBDD) {
                mcpFactory = new MCPFactory(MCPFactory.MCPType.BDD);
            } else {
                mcpFactory = new MCPFactory(MCPFactory.MCPType.SAT);
            }
            if (!independent) {
                // cross-policy: one shared factory drives all policies in this round
                MCPPolicy.setMCPFactory(mcpFactory);
            }

            for (String fileName : fileNames) {
                if (independent) {
                    // independent mode: fresh factory per policy, no cross-policy state
                    MCPFactory pf = Parameter.isBDD
                            ? new MCPFactory(MCPFactory.MCPType.BDD)
                            : new MCPFactory(MCPFactory.MCPType.SAT);
                    MCPPolicy.setMCPFactory(pf);
                }
                Path inputFilePath = inputFoldPath.resolve(fileName);
                Parameter.timeLog = outputFoldPath.resolve(FileUtil.changeToCsvWithTime(fileName)).toString();

                resultsAnalyzer.initializes();
                AccessRefinery miner = new AccessRefinery();
                HashSet<MCPIntent> findings = miner.running(inputFilePath, resultsAnalyzer);
                resultsAnalyzer.calculateAverage();   // averages now = this round's values

                double[][] a = acc.get(fileName);
                a[r][0] = resultsAnalyzer.getMCILabelsTimeAverage();
                a[r][1] = resultsAnalyzer.getMCIOperationsTimeAverage();
                a[r][2] = resultsAnalyzer.getRRIOperationsTimeAverage();
                a[r][3] = resultsAnalyzer.getRRIILPSolvingTimeAverage();

                int[] m = meta.get(fileName);
                m[0] = resultsAnalyzer.getNumberStatement();
                m[1] = resultsAnalyzer.getNumberIntentsMCI();
                m[2] = resultsAnalyzer.getNumberIntentsRRI();
                m[3] = resultsAnalyzer.getMCISolvingRoundAverage();
                findingsByFile.put(fileName, findings);
            }
        }

        String summaryPath = outputFoldPath.resolve("summary.txt").toString();
        for (String fileName : fileNames) {
            double[][] a = acc.get(fileName);
            int[] m = meta.get(fileName);
            double[] labelsA = new double[round];
            double[] opsA = new double[round];
            double[] rriA = new double[round];
            double[] ilpA = new double[round];
            for (int r = 0; r < round; r++) {
                labelsA[r] = a[r][0];
                opsA[r] = a[r][1];
                rriA[r] = a[r][2];
                ilpA[r] = a[r][3];
            }
            double labels = ResultsAnalyzer.trimmedMean(labelsA);
            double ops = ResultsAnalyzer.trimmedMean(opsA);
            double rriOps = ResultsAnalyzer.trimmedMean(rriA);
            double rriIlp = ResultsAnalyzer.trimmedMean(ilpA);
            double total = labels + ops + rriOps + rriIlp;
            try (java.io.PrintWriter w = new java.io.PrintWriter(new java.io.FileWriter(summaryPath, true))) {
                w.printf("%d\t%d\t%d\t%d\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f%n",
                        m[0], m[1], m[2], m[3], total, labels, ops, rriOps, rriIlp);
            }
            Path outputFindingPath = outputFoldPath.resolve(FileUtil.changeToJsonWithFindings(fileName));
            JsonIntent jsonFindings = new JsonIntent(inputFoldPath.resolve(fileName).toString(), findingsByFile.get(fileName));
            JsonIntent.printToFile(jsonFindings, outputFindingPath);
        }
    }

    public static void runBatchZelkova(String input) throws IOException {
        Path inputFoldPath = Paths.get(input);
        Path outputFoldPath = FileUtil.replaceSecondLastLevel(inputFoldPath);
        FileUtil.createDirectoryIfNotExists(outputFoldPath);
        Parameter.LOGGER.info("----------[ Zelkova Mode ]-------------");
        Parameter.LOGGER.info("Logger path: " + LoggerUtil.getLogFilePath());
        Parameter.LOGGER.info("Input  path: " + inputFoldPath);
        List<String> fileNames = FileUtil.getFileNames(inputFoldPath);

        for(String fileName : fileNames) {
            Parameter.LOGGER.info("----------< " + ++policiesIdx + "th policy - " + fileName + " >-----------");
            Path inputFilePath = inputFoldPath.resolve(fileName);

            Zelkova checker = new Zelkova();
            String sat = checker.isSatisfiable(inputFilePath) ? "sat" : "unsat";
            Parameter.LOGGER.info("Policy " + fileName + " is " + sat + " : " + checker.getTime().getSingleRoundTotalTime() + "ms");

            Path outputFindingPath = outputFoldPath.resolve(FileUtil.changeToDot(fileName));
            checker.printMCPPolicy(outputFindingPath);
        }
    }
}
