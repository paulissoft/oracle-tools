package com.paulissoft.pato.jdbc.jmh;

import java.sql.SQLException;
import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.TearDown;
import org.openjdk.jmh.infra.Blackhole;

import lombok.extern.slf4j.Slf4j;

@Slf4j
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
