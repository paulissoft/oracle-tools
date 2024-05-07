//package com.paulissoft.pato.jdbc;

package com.example.springboot;

//import java.sql.Connection;
import java.sql.SQLException;
import java.util.concurrent.TimeUnit;
import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.BenchmarkMode;
import org.openjdk.jmh.annotations.Mode;
import org.openjdk.jmh.annotations.OutputTimeUnit;
import org.openjdk.jmh.annotations.Scope;
import org.openjdk.jmh.annotations.State;
import org.openjdk.jmh.infra.Blackhole;
import org.openjdk.jmh.annotations.TearDown;

import lombok.extern.slf4j.Slf4j;

@Slf4j
// JMH annotations
@State(Scope.Benchmark)
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MICROSECONDS)
public class HikariTest0 extends BenchmarkTest {

    @Override
    @TearDown
    public void tearDown() throws Exception {
        super.tearDown();
    }    
    
    @Benchmark
    public void connectAllBasic(Blackhole bh,
                                BenchmarkState bs) throws SQLException {
        connectAll(bh, bs, com.zaxxer.hikari.HikariDataSource.class.getName());
    }
}
