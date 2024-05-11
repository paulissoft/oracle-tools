//package com.paulissoft.pato.jdbc;

package com.paulissoft.pato.jdbc.jmh;

import java.util.List;
import org.openjdk.jmh.results.format.ResultFormatType;
import org.openjdk.jmh.runner.Runner;
import org.openjdk.jmh.runner.RunnerException;
import org.openjdk.jmh.runner.options.Options;
import org.openjdk.jmh.runner.options.ChainedOptionsBuilder;
import org.openjdk.jmh.runner.options.OptionsBuilder;

public class BenchmarkTestRunner {

    private final static Integer MEASUREMENT_ITERATIONS = 3;
    
    private final static Integer WARMUP_ITERATIONS = 3;

    public static void execute(final List<String> jmhFilter) throws RunnerException {
        final String resultFile = "results.txt"; // or "/dev/null"
        final ChainedOptionsBuilder chainedOptionsBuilder = new OptionsBuilder()
            .warmupIterations(WARMUP_ITERATIONS)
            .measurementIterations(MEASUREMENT_ITERATIONS)
            // do not use forking or the benchmark methods will not see references stored within its class
            .forks(0)
            // do not use multiple threads
            .threads(1)
            .shouldDoGC(true)
            .resultFormat(ResultFormatType.JSON)
            .result(resultFile)
            .shouldFailOnError(false)
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
