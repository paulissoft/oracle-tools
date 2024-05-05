//package com.paulissoft.pato.jdbc;

package com.example.springboot;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import java.util.Vector;
import java.util.concurrent.TimeUnit;
import javax.sql.DataSource;
import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.BenchmarkMode;
import org.openjdk.jmh.annotations.Level;
import org.openjdk.jmh.annotations.Mode;
import org.openjdk.jmh.annotations.OutputTimeUnit;
import org.openjdk.jmh.annotations.Param;
import org.openjdk.jmh.annotations.Scope;
import org.openjdk.jmh.annotations.Setup;
import org.openjdk.jmh.annotations.State;
import org.openjdk.jmh.infra.Blackhole;
import org.springframework.context.ApplicationContext;

import lombok.extern.slf4j.Slf4j;

@Slf4j
// JMH annotations
@State(Scope.Benchmark)
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MICROSECONDS)
public class HikariTest extends AbstractBenchmark {

    public HikariTest() {
    }

    // private static final String[] schemas = new String[] {"boauth", "bocsconf", "bodomain", "boocpi", "boocpp15j", "boopapij"};

    @State(Scope.Benchmark)
    public static class BenchmarkState {

        private final int[] logicalConnections = new int[] {20076, 10473, 10494, 14757, 19117, 14987};

        public final DataSource[][] dataSources = {
            { null, null, null, null, null, null },
            { null, null, null, null, null, null },
            { null, null, null, null, null, null },
            { null, null, null, null, null, null }
        };
        
        @Param({"10000"})
        public int divideLogicalConnectionsBy;

        public List<Integer> testList = new Vector(1000, 1000);

        @Setup(Level.Trial)
        public void setUp() {
            final ApplicationContext context = SpringContext.getApplicationContext();

            // get instance of MainSpringClass (Spring Managed class)
            int t;
            for (t = 0; t < 4; t++) {
                dataSources[t][0] = (DataSource) context.getBean("authDataSource" + t);      
                dataSources[t][1] = (DataSource) context.getBean("configDataSource" + t);
                dataSources[t][2] = (DataSource) context.getBean("domainDataSource" + t);
                dataSources[t][3] = (DataSource) context.getBean("ocpiDataSource" + t);
                dataSources[t][4] = (DataSource) context.getBean("ocppDataSource" + t);
                dataSources[t][5] = (DataSource) context.getBean("operatorDataSource" + t);
            }

            final int[] logicalConnections = new int[this.logicalConnections.length];
            int totalLogicalConnections = 0;
            int idx;
            
            for (idx = 0; idx < logicalConnections.length; idx++) {
                logicalConnections[idx] = this.logicalConnections[idx] / divideLogicalConnectionsBy;

                log.debug("# logical connections for index {}: {}", idx, logicalConnections[idx]);
                            
                assert logicalConnections[idx] > 0;
                totalLogicalConnections += logicalConnections[idx];    
            }

            log.debug("# logical connections: {}", totalLogicalConnections);

            while (totalLogicalConnections > 0) {
                do {
                    idx = getRandomNumber(0, logicalConnections.length);
                } while (logicalConnections[idx] == 0);

                assert logicalConnections[idx] > 0;

                logicalConnections[idx]--;
                totalLogicalConnections--;

                log.debug("adding index ", idx);
                
                testList.add(idx);
            }

            log.debug("# indexes: {}", testList.size());
        }
    }

    // https://www.baeldung.com/java-generating-random-numbers-in-range
    private static int getRandomNumber(int min, int max) {
        return (int) ((Math.random() * (max - min)) + min);
    }
    
    @Benchmark
    public void connectAllBasic(Blackhole bh,
                                BenchmarkState bs) throws SQLException {
        bs.testList.parallelStream().forEach(idx -> {
                try (final Connection conn = bs.dataSources[0][idx].getConnection()) {
                    bh.consume(conn.getSchema());
                } catch (SQLException ex1) {
                    throw new RuntimeException(ex1.getMessage());
                }});
    }

    //    @Benchmark
    public void connectAllSimple(Blackhole bh,
                                 BenchmarkState bs) throws SQLException {
        bs.testList.parallelStream().forEach(idx -> {
                try (final Connection conn = bs.dataSources[1][idx].getConnection()) {
                    bh.consume(conn.getSchema());
                } catch (SQLException ex1) {
                    throw new RuntimeException(ex1.getMessage());
                }});
    }

    //    @Benchmark
    public void connectAllCombi(Blackhole bh,
                                BenchmarkState bs) throws SQLException {
        bs.testList.parallelStream().forEach(idx -> {
                try (final Connection conn = bs.dataSources[2][idx].getConnection()) {
                    bh.consume(conn.getSchema());
                } catch (SQLException ex1) {
                    throw new RuntimeException(ex1.getMessage());
                }});
    }
    
    //    @Benchmark
    public void connectAllSmart(Blackhole bh,
                                BenchmarkState bs) throws SQLException {
        bs.testList.parallelStream().forEach(idx -> {
                try (final Connection conn = bs.dataSources[3][idx].getConnection()) {
                    bh.consume(conn.getSchema());
                } catch (SQLException ex1) {
                    throw new RuntimeException(ex1.getMessage());
                }});
    }
}
