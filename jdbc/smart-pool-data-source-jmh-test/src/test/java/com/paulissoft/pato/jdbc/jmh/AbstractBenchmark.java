package com.paulissoft.pato.jdbc.jmh;

import java.util.Arrays;

import org.junit.Test;
import org.openjdk.jmh.results.format.ResultFormatType;
import org.openjdk.jmh.runner.Runner;
import org.openjdk.jmh.runner.RunnerException;
import org.openjdk.jmh.runner.options.Options;
import org.openjdk.jmh.runner.options.OptionsBuilder;

public class BenchmarkTest extends BenchmarkTestRunner {

    public BenchmarkTest() {
    }

    @Test
    public void executeAll() throws RunnerException {
        BenchmarkTestRunner.execute(); // all tests
    }
}
