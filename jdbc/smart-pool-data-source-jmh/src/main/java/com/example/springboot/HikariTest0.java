//package com.paulissoft.pato.jdbc;

package com.example.springboot;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.concurrent.TimeUnit;
import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.BenchmarkMode;
import org.openjdk.jmh.annotations.Mode;
import org.openjdk.jmh.annotations.OutputTimeUnit;
import org.openjdk.jmh.annotations.Scope;
import org.openjdk.jmh.annotations.State;
import org.openjdk.jmh.infra.Blackhole;

import lombok.extern.slf4j.Slf4j;

@Slf4j
// JMH annotations
@State(Scope.Benchmark)
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MICROSECONDS)
public class HikariTest0 {

    @Benchmark
    public void connectAllBasic(Blackhole bh,
                                BenchmarkState bs) throws SQLException {
        bs.testList.parallelStream().forEach(idx -> {
                try (final Connection conn = bs.dataSources[0][0][idx].getConnection()) {
                    bh.consume(conn.getSchema());
                } catch (SQLException ex1) {
                    throw new RuntimeException(ex1.getMessage());
                }});
    }
}
