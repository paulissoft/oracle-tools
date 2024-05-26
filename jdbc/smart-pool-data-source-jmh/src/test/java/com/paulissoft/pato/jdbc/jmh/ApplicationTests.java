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

    private static double MAX_DEVIATION = 0.1;

    @Test
    void executeHikariTest0() throws RunnerException {
        checkHikariTest(BenchmarkTestRunner.execute(Arrays.asList(HikariTest0.class.getSimpleName())), 0);
    }

    @Test
    void executeHikariTest1() throws RunnerException {
        checkHikariTest(BenchmarkTestRunner.execute(Arrays.asList(HikariTest1.class.getSimpleName())), 1);
    }

    @Test
    void executeHikariTest2() throws RunnerException {
        checkHikariTest(BenchmarkTestRunner.execute(Arrays.asList(HikariTest2.class.getSimpleName())), 2);
    }
    
    @Test
    void executeHikariTest3() throws RunnerException {
        checkHikariTest(BenchmarkTestRunner.execute(Arrays.asList(HikariTest3.class.getSimpleName())), 3);
    }

    @Test
    void executeOracleTest0() throws RunnerException {
        checkOracleTest(BenchmarkTestRunner.execute(Arrays.asList(OracleTest0.class.getSimpleName())), 0);
    }

    @Test
    void executeOracleTest1() throws RunnerException {
        checkOracleTest(BenchmarkTestRunner.execute(Arrays.asList(OracleTest1.class.getSimpleName())), 1);
    }

    @Test
    void executeOracleTest2() throws RunnerException {
        checkOracleTest(BenchmarkTestRunner.execute(Arrays.asList(OracleTest2.class.getSimpleName())), 2);
    }

    @Test
    void executeOracleTest3() throws RunnerException {
        checkOracleTest(BenchmarkTestRunner.execute(Arrays.asList(OracleTest3.class.getSimpleName())), 3);
    }

    private void checkHikariTest(final Collection<RunResult> runResults, final int classType) {
        if (classType == 0) {
            Assertions.assertEquals(1, runResults.size());
            setReferenceScoreHikari(runResults.iterator().next());
        } else {
            Assertions.assertFalse(runResults.isEmpty());
            for(RunResult runResult : runResults) {
                assertDeviationWithin(runResult, REFERENCE_SCORE_HIKARI, MAX_DEVIATION);
            }
        }
    }

    private void checkOracleTest(final Collection<RunResult> runResults, final int classType) {
        if (classType == 0) {
            Assertions.assertEquals(1, runResults.size());
            setReferenceScoreOracle(runResults.iterator().next());
        } else {
            Assertions.assertFalse(runResults.isEmpty());
            for(RunResult runResult : runResults) {
                assertDeviationWithin(runResult, REFERENCE_SCORE_ORACLE, MAX_DEVIATION * (classType == 3 ? 3 : 1));
            }
        }
    }
        
    private static void setReferenceScoreHikari(final RunResult result) {
        REFERENCE_SCORE_HIKARI = result.getPrimaryResult().getScore();
    }
    
    private static void setReferenceScoreOracle(final RunResult result) {
        REFERENCE_SCORE_ORACLE = result.getPrimaryResult().getScore();
    }
    
    private static void assertDeviationWithin(final RunResult result, final double referenceScore, final double maxDeviation) {
        final double score = result.getPrimaryResult().getScore();
        final double deviation = Math.abs(score/referenceScore - 1);
        final String errorMessage =
            String.format("Score = %.3f; reference score = %.3f; deviation (%s) exceeds maximum allowed deviation (%s)",
                          score,
                          referenceScore,
                          df.format(deviation * 100) + " %",
                          df.format(maxDeviation * 100) + " %");

        Assertions.assertTrue(deviation < maxDeviation, errorMessage);
    }
}
