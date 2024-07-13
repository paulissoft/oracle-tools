package com.paulissoft.pato.jdbc.jmh;

import java.text.DecimalFormat;
import java.util.Collection;
import java.util.Collections;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.openjdk.jmh.results.RunResult;
import org.openjdk.jmh.runner.RunnerException;
import org.springframework.boot.test.context.SpringBootTest;


@SpringBootTest
class ApplicationTests {

    private static final DecimalFormat df = new DecimalFormat("0.000");

    // # Benchmark: com.paulissoft.pato.jdbc.jmh.HikariTest0.connectAllBasic
    private static double REFERENCE_SCORE_HIKARI = 14.606; // not final since overridden in executeHikariTest0
    
    // # Benchmark: com.paulissoft.pato.jdbc.jmh.OracleTest0.connectAllBasic
    private static double REFERENCE_SCORE_ORACLE = 14.025; // not final since overridden in executeOracleTest0

    private static final double MAX_DEVIATION = 0.1;

    @Test
    void executeHikariTest0() throws RunnerException {
        checkHikariTest(HikariTest0.getDataSourceClassName(), HikariTest0.class.getSimpleName());
    }

    @Test
    void executeHikariTest1() throws RunnerException {
        checkHikariTest(HikariTest1.getDataSourceClassName(), HikariTest1.class.getSimpleName());
    }

    @Test
    void executeHikariTest2() throws RunnerException {
        checkHikariTest(HikariTest2.getDataSourceClassName(), HikariTest2.class.getSimpleName());
    }
    
    @Test
    void executeOracleTest0() throws RunnerException {
        checkOracleTest(OracleTest0.getDataSourceClassName(), OracleTest0.class.getSimpleName());
    }

    @Test
    void executeOracleTest1() throws RunnerException {
        checkOracleTest(OracleTest1.getDataSourceClassName(), OracleTest1.class.getSimpleName());
    }

    @Test
    void executeOracleTest2() throws RunnerException {
        checkOracleTest(OracleTest2.getDataSourceClassName(), OracleTest2.class.getSimpleName());
    }

    private void checkHikariTest(final String dataSourceClassName, final String simpleTestClassName) throws RunnerException {
        final int classIndex = BenchmarkState.getClassIndex(dataSourceClassName);
        final Collection<RunResult> runResults = BenchmarkTestRunner.execute(Collections.singletonList(simpleTestClassName));

        Assertions.assertEquals(BenchmarkState.getCount(classIndex), BenchmarkState.getOk(classIndex), "all operations should be OK");
                    
        if (simpleTestClassName.endsWith("0")) {
            Assertions.assertEquals(1, runResults.size());
            setReferenceScoreHikari(runResults.iterator().next());
        } else {
            Assertions.assertFalse(runResults.isEmpty());
            for(RunResult runResult : runResults) {
                assertDeviationWithin(runResult, REFERENCE_SCORE_HIKARI, MAX_DEVIATION);
            }
        }
    }

    private void checkOracleTest(final String dataSourceClassName, final String simpleTestClassName) throws RunnerException {
        final int classIndex = BenchmarkState.getClassIndex(dataSourceClassName);
        final Collection<RunResult> runResults = BenchmarkTestRunner.execute(Collections.singletonList(simpleTestClassName));

        Assertions.assertEquals(BenchmarkState.getCount(classIndex), BenchmarkState.getOk(classIndex), "all operations should be OK");
        
        if (simpleTestClassName.endsWith("0")) {
            Assertions.assertEquals(1, runResults.size());
            setReferenceScoreOracle(runResults.iterator().next());
        } else {
            Assertions.assertFalse(runResults.isEmpty());
            for(RunResult runResult : runResults) {
                assertDeviationWithin(runResult, REFERENCE_SCORE_ORACLE, MAX_DEVIATION * (simpleTestClassName.endsWith("3") ? 3 : 1));
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
            String.format("Score = %.3f; reference score = %.3f; deviation (%s) exceeds maximum allowed deviation (%s) and score > reference score",
                          score,
                          referenceScore,
                          df.format(deviation * 100) + " %",
                          df.format(maxDeviation * 100) + " %");

        Assertions.assertTrue(score <= referenceScore || deviation < maxDeviation, errorMessage);
    }
}
