package com.paulissoft.pato.jdbc.jmh;

import java.sql.SQLException;
import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.Level;
import org.openjdk.jmh.annotations.TearDown;
import org.openjdk.jmh.infra.Blackhole;

import lombok.extern.slf4j.Slf4j;

@Slf4j
public class OracleTest3 extends BenchmarkTest {

    @Override
    @TearDown(Level.Trial)
    public void tearDown() throws Exception {
        super.tearDown();
    }    
    
    @Benchmark
    public void connectAllSmart(Blackhole bh,
                                BenchmarkState bs) throws SQLException {
        connectAll(bh, bs, com.paulissoft.pato.jdbc.SmartPoolDataSourceOracle.class.getName());
    }
}
