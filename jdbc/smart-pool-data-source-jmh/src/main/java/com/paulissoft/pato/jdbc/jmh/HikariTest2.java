package com.paulissoft.pato.jdbc.jmh;

import java.sql.SQLException;
import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.Level;
import org.openjdk.jmh.annotations.TearDown;
import org.openjdk.jmh.infra.Blackhole;

import lombok.extern.slf4j.Slf4j;

@Slf4j
public class HikariTest2 extends BenchmarkTestBase {

    final static private String dataSourceClassName = com.paulissoft.pato.jdbc.CombiPoolDataSourceHikari.class.getName();

    public static String getDataSourceClassName() {
        return dataSourceClassName;
    }

    @Override
    @TearDown(Level.Trial)
    public void tearDown() throws Exception {
        super.tearDown();
    }    
    
    @Benchmark
    public void connectAllCombi(Blackhole bh,
                                BenchmarkState bs) throws SQLException {
        connectAll(bh, bs, dataSourceClassName);
    }
}
