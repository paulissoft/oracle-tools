package com.paulissoft.pato.jdbc.jmh;

import java.util.Arrays;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.openjdk.jmh.runner.RunnerException;

@SpringBootTest
class ApplicationTests {

    @Test
    void executeHikariTest0() throws RunnerException {
        BenchmarkTestRunner.execute(Arrays.asList(HikariTest0.class.getSimpleName())); // all tests
    }

    @Test
    void executeHikariTest1() throws RunnerException {
        BenchmarkTestRunner.execute(Arrays.asList(HikariTest1.class.getSimpleName())); // all tests
    }

    @Test
    void executeHikariTest2() throws RunnerException {
        BenchmarkTestRunner.execute(Arrays.asList(HikariTest2.class.getSimpleName())); // all tests
    }

    @Test
    void executeHikariTest3() throws RunnerException {
        BenchmarkTestRunner.execute(Arrays.asList(HikariTest3.class.getSimpleName())); // all tests
    }

    @Test
    void executeOracleTest0() throws RunnerException {
        BenchmarkTestRunner.execute(Arrays.asList(OracleTest0.class.getSimpleName())); // all tests
    }

    @Test
    void executeOracleTest1() throws RunnerException {
        BenchmarkTestRunner.execute(Arrays.asList(OracleTest1.class.getSimpleName())); // all tests
    }

    @Test
    void executeOracleTest2() throws RunnerException {
        BenchmarkTestRunner.execute(Arrays.asList(OracleTest2.class.getSimpleName())); // all tests
    }

    @Test
    void executeOracleTest3() throws RunnerException {
        BenchmarkTestRunner.execute(Arrays.asList(OracleTest3.class.getSimpleName())); // all tests
    }
}
