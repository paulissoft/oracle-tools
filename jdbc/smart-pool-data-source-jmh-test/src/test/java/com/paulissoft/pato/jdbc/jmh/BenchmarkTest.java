package com.paulissoft.pato.jdbc.jmh;

//import java.util.Arrays;

import org.junit.Test;
import org.openjdk.jmh.runner.RunnerException;

public class BenchmarkTest extends BenchmarkTestRunner {

    public BenchmarkTest() {
    }

    @Test
    public void executeAll() throws RunnerException {
        BenchmarkTestRunner.execute(null); // all tests
    }
}
