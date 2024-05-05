//package com.paulissoft.pato.jdbc;

package com.example.springboot;

import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import java.util.Vector;
import java.util.concurrent.TimeUnit;
//import org.junit.jupiter.api.extension.ExtendWith;
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
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
//import org.springframework.test.context.ContextConfiguration;
//import org.springframework.test.context.TestPropertySource;
//import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.context.ApplicationContext;

import lombok.extern.slf4j.Slf4j;

@Slf4j
// JMH annotations
@State(Scope.Benchmark)
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MICROSECONDS)
// Spring annotations
public class HikariTest extends AbstractBenchmark {

    public HikariTest() {
    }

    // private static final String[] schemas = new String[] {"boauth", "bocsconf", "bodomain", "boocpi", "boocpp15j", "boopapij"};

    @State(Scope.Benchmark)
    public static class BenchmarkState {

        private final int[] logicalConnections = new int[] {20076, 10473, 10494, 14757, 19117, 14987};

        public final HikariDataSource[] dataSources = new HikariDataSource[logicalConnections.length];
        
        @Param({"10000"})
        public int divideLogicalConnectionsBy;

        public List<Integer> testList = new Vector(1000, 1000);

        @Setup(Level.Trial)
        public void setUp() {
            final ApplicationContext context = SpringContext.getApplicationContext();

            log.info("context: {}", context);
            
            // get instance of MainSpringClass (Spring Managed class)
            dataSources[0] = (HikariDataSource) context.getBean("authDataSource1");      
            dataSources[1] = (HikariDataSource) context.getBean("configDataSource1");
            dataSources[2] = (HikariDataSource) context.getBean("domainDataSource1");
            dataSources[3] = (HikariDataSource) context.getBean("ocpiDataSource1");
            dataSources[4] = (HikariDataSource) context.getBean("ocppDataSource1");
            dataSources[5] = (HikariDataSource) context.getBean("operatorDataSource1");

            final int[] logicalConnections = new int[BenchmarkState.logicalConnections.length];
            int totalLogicalConnections = 0;
            int idx;
            
            for (idx = 0; idx < logicalConnections.length; idx++) {
                logicalConnections[idx] = BenchmarkState.logicalConnections[idx] / divideLogicalConnectionsBy;

                log.info("# logical connections for index {}: {}", idx, logicalConnections[idx]);
                            
                assert logicalConnections[idx] > 0;
                totalLogicalConnections += logicalConnections[idx];    
            }

            log.info("# logical connections: {}", totalLogicalConnections);

            while (totalLogicalConnections > 0) {
                do {
                    idx = getRandomNumber(0, logicalConnections.length);
                } while (logicalConnections[idx] == 0);

                assert logicalConnections[idx] > 0;

                logicalConnections[idx]--;
                totalLogicalConnections--;

                log.info("adding index ", idx);
                
                testList.add(idx);
            }

            log.info("# indexes: {}", testList.size());
        }
    }

    // https://www.baeldung.com/java-generating-random-numbers-in-range
    private static int getRandomNumber(int min, int max) {
        return (int) ((Math.random() * (max - min)) + min);
    }
    
    @Benchmark
    @BenchmarkMode(Mode.SingleShotTime)
    public void connectAll(Blackhole bh,
                           BenchmarkState bs) throws SQLException {
        bs.testList.parallelStream().forEach(idx -> { connect(bh, bs.dataSources, idx); });        
        // bs.testList.stream().forEach(idx -> { connect(bh, dataSources, idx); });        
    }

    private void connect(final Blackhole bh, final HikariDataSource[] dataSources, final int idx) {
        log.info("connect({}, {})", dataSources, idx);

        assert idx >= 0 && idx < dataSources.length : "Index (" + idx + ") must be between 0 and " + dataSources.length;
        assert dataSources[idx] != null : "Data source for index (" + idx + ") must not be null";

        Connection conn = null;

        try {
            log.info("data source: {}", dataSources[idx]);
            
            conn = dataSources[idx].getConnection();

            assert conn != null : "Connection should not be null";
            assert conn.getSchema() != null : "Connection schema should not be null";

            log.info("schema: {}", conn.getSchema());

            bh.consume(conn.getSchema());
        } catch (SQLException ex1) {
            // System.err.println(ex1.getMessage());
            throw new RuntimeException(ex1.getMessage());
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                } catch (SQLException ex2) {
                    throw new RuntimeException(ex2.getMessage());
                }
            }
        }
    }
}
