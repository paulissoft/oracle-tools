package com.paulissoft.pato.jdbc.jmh;

import java.sql.SQLException;
import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.TearDown;
import org.openjdk.jmh.infra.Blackhole;

import lombok.extern.slf4j.Slf4j;

@Slf4j
public class HikariTest1 extends BenchmarkTest {

    @Override
    @TearDown
    public void tearDown() throws Exception {
        super.tearDown();
    }    
    
    @Benchmark
    public void connectAllSimple(Blackhole bh,
                                BenchmarkState bs) throws SQLException {
        connectAll(bh, bs, com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari.class.getName());
    }
}
