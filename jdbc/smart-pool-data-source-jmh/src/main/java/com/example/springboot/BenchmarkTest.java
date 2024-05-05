//package com.paulissoft.pato.jdbc;

package com.example.springboot;

import java.util.List;
import org.openjdk.jmh.results.format.ResultFormatType;
import org.openjdk.jmh.runner.Runner;
import org.openjdk.jmh.runner.RunnerException;
import org.openjdk.jmh.runner.options.Options;
import org.openjdk.jmh.runner.options.ChainedOptionsBuilder;
import org.openjdk.jmh.runner.options.OptionsBuilder;

public class BenchmarkTest {

    private final static Integer MEASUREMENT_ITERATIONS = 3;
    
    private final static Integer WARMUP_ITERATIONS = 3;

    public static void executeJmhRunner(final List<String> jmhFilter) throws RunnerException {
        final ChainedOptionsBuilder chainedOptionsBuilder = new OptionsBuilder()
            .warmupIterations(WARMUP_ITERATIONS)
            .measurementIterations(MEASUREMENT_ITERATIONS)
            // do not use forking or the benchmark methods will not see references stored within its class
            .forks(0)
            // do not use multiple threads
            .threads(1)
            .shouldDoGC(true)
            .shouldFailOnError(true)
            .resultFormat(ResultFormatType.JSON)
            .result("/dev/null") // set this to a valid filename if you want reports
            .shouldFailOnError(true)
            .jvmArgs("-server")
            .jvmArgs("-ea");

        if (jmhFilter != null && jmhFilter.size() > 0) {
            // set the class name regex for benchmarks to search for to the current class 
            jmhFilter.forEach(i -> { chainedOptionsBuilder.include("\\." + i + "\\."); });
        } else {
            chainedOptionsBuilder.include("\\..*\\.");
        }
        
        final Options opt = chainedOptionsBuilder.build();

        new Runner(opt).run();
    }
}
