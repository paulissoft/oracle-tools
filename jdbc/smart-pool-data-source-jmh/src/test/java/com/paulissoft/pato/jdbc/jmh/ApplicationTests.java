package com.paulissoft.pato.jdbc.jmh;

import java.text.DecimalFormat;
import java.util.Arrays;
import java.util.Collection;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.openjdk.jmh.results.RunResult;
import org.openjdk.jmh.runner.RunnerException;
import org.springframework.boot.test.context.SpringBootTest;


@SpringBootTest
class ApplicationTests {

    private static DecimalFormat df = new DecimalFormat("0.000");

    // # Benchmark: com.paulissoft.pato.jdbc.jmh.HikariTest0.connectAllBasic
    private static double REFERENCE_SCORE_HIKARI = 14.606; // not final since overridden in executeHikariTest0
    
    // # Benchmark: com.paulissoft.pato.jdbc.jmh.OracleTest0.connectAllBasic
    private static double REFERENCE_SCORE_ORACLE = 14.025; // not final since overridden in executeOracleTest0

    private static double MAX_DEVIATION = 0.05;

    @Test
    void executeHikariTest0() throws RunnerException {
        final Collection<RunResult> runResults = BenchmarkTestRunner.execute(Arrays.asList(HikariTest0.class.getSimpleName()));
        
        Assertions.assertEquals(1, runResults.size());
        setReferenceScoreHikari(runResults.iterator().next());
    }

    @Test
    void executeHikariTest1() throws RunnerException {
        final Collection<RunResult> runResults = BenchmarkTestRunner.execute(Arrays.asList(HikariTest1.class.getSimpleName()));

        Assertions.assertFalse(runResults.isEmpty());
        for(RunResult runResult : runResults) {
            assertDeviationWithin(runResult, REFERENCE_SCORE_HIKARI, MAX_DEVIATION);
        }
    }

    @Test
    void executeHikariTest2() throws RunnerException {
        final Collection<RunResult> runResults = BenchmarkTestRunner.execute(Arrays.asList(HikariTest2.class.getSimpleName()));

        Assertions.assertFalse(runResults.isEmpty());
        for(RunResult runResult : runResults) {
            assertDeviationWithin(runResult, REFERENCE_SCORE_HIKARI, MAX_DEVIATION);
        }
    }
    
    @Test
    void executeHikariTest3() throws RunnerException {
        final Collection<RunResult> runResults = BenchmarkTestRunner.execute(Arrays.asList(HikariTest3.class.getSimpleName()));

        Assertions.assertFalse(runResults.isEmpty());
        for(RunResult runResult : runResults) {
            assertDeviationWithin(runResult, REFERENCE_SCORE_HIKARI, MAX_DEVIATION);
        }
    }

    @Test
    void executeOracleTest0() throws RunnerException {
        final Collection<RunResult> runResults = BenchmarkTestRunner.execute(Arrays.asList(OracleTest0.class.getSimpleName()));

        Assertions.assertEquals(1, runResults.size());
        setReferenceScoreOracle(runResults.iterator().next());
    }

    @Test
    void executeOracleTest1() throws RunnerException {
        final Collection<RunResult> runResults = BenchmarkTestRunner.execute(Arrays.asList(OracleTest1.class.getSimpleName()));

        Assertions.assertFalse(runResults.isEmpty());
        for(RunResult runResult : runResults) {
            assertDeviationWithin(runResult, REFERENCE_SCORE_ORACLE, MAX_DEVIATION);
        }
    }

    @Test
    void executeOracleTest2() throws RunnerException {
        final Collection<RunResult> runResults = BenchmarkTestRunner.execute(Arrays.asList(OracleTest2.class.getSimpleName()));

        Assertions.assertFalse(runResults.isEmpty());
        for(RunResult runResult : runResults) {
            assertDeviationWithin(runResult, REFERENCE_SCORE_ORACLE, MAX_DEVIATION);
        }
    }

    @Test
    void executeOracleTest3() throws RunnerException {
        final Collection<RunResult> runResults = BenchmarkTestRunner.execute(Arrays.asList(OracleTest3.class.getSimpleName()));

        Assertions.assertFalse(runResults.isEmpty());
        for(RunResult runResult : runResults) {
            assertDeviationWithin(runResult, REFERENCE_SCORE_ORACLE, MAX_DEVIATION);
        }
    }

    private static void setReferenceScoreHikari(RunResult result) {
        REFERENCE_SCORE_HIKARI = result.getPrimaryResult().getScore();
    }
    
    private static void setReferenceScoreOracle(RunResult result) {
        REFERENCE_SCORE_ORACLE = result.getPrimaryResult().getScore();
    }
    
    private static void assertDeviationWithin(RunResult result, double referenceScore, double maxDeviation) {
        final double score = result.getPrimaryResult().getScore();
        final double deviation = Math.abs(score/referenceScore - 1);
        final String deviationString = df.format(deviation * 100) + "%";
        final String maxDeviationString = df.format(maxDeviation * 100) + "%";
        final String errorMessage = "Deviation " + deviationString + " exceeds maximum allowed deviation " + maxDeviationString;

        Assertions.assertTrue(deviation < maxDeviation, errorMessage);
    }
}
