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

        private static final int[] logicalConnections = new int[] {20076, 10473, 10494, 14757, 19117, 14987};
        
        @Param({"10000"})
        public int divideLogicalConnectionsBy;

        public List<Integer> testList = new Vector(1000, 1000);

        @Autowired
        @Qualifier("authDataSource1")
        private static HikariDataSource authDataSourceHikari;

        @Autowired
        @Qualifier("configDataSource1")
        private static HikariDataSource configDataSourceHikari;
    
        @Autowired
        @Qualifier("domainDataSource1")
        private static HikariDataSource domainDataSourceHikari;
    
        @Autowired
        @Qualifier("ocpiDataSource1")
        private static HikariDataSource ocpiDataSourceHikari;
    
        @Autowired
        @Qualifier("ocppDataSource1")
        private static HikariDataSource ocppDataSourceHikari;
    
        @Autowired
        @Qualifier("operatorDataSource1")
        private static HikariDataSource operatorDataSourceHikari;
        
        @Setup(Level.Trial)
        public void setUp() {
            final int[] logicalConnections = new int[BenchmarkState.logicalConnections.length];
            int totalLogicalConnections = 0;
            int idx;
            
            for (idx = 0; idx < logicalConnections.length; idx++) {
                logicalConnections[idx] = BenchmarkState.logicalConnections[idx] / divideLogicalConnectionsBy;

                System.out.println("# logical connections for index " + idx + ": " + logicalConnections[idx]);
                            
                assert logicalConnections[idx] > 0;
                totalLogicalConnections += logicalConnections[idx];    
            }

            System.out.println("# logical connections: " + totalLogicalConnections);

            while (totalLogicalConnections > 0) {
                do {
                    idx = getRandomNumber(0, logicalConnections.length);
                } while (logicalConnections[idx] == 0);

                assert logicalConnections[idx] > 0;

                logicalConnections[idx]--;
                totalLogicalConnections--;

                System.out.println("adding index " + idx);
                
                testList.add(idx);
            }

            System.out.println("# indexes: " + testList.size());
        }
        
        /*
        @Autowired
        void setAuthDataSourceHikari(@Qualifier("authDataSource1") HikariDataSource authDataSourceHikari) {
            this.authDataSourceHikari = authDataSourceHikari;
        }
        
        @Autowired
        void setConfigDataSourceHikari(@Qualifier("configDataSource1") HikariDataSource configDataSourceHikari) {
            this.configDataSourceHikari = configDataSourceHikari;
        }
    
        @Autowired
        void setDomainDataSourceHikari(@Qualifier("domainDataSource1") HikariDataSource domainDataSourceHikari) {
            this.domainDataSourceHikari = domainDataSourceHikari;
        }
    
        @Autowired
        void setOcpiDataSourceHikari(@Qualifier("ocpiDataSource1") HikariDataSource ocpiDataSourceHikari) {
            this.ocpiDataSourceHikari = ocpiDataSourceHikari;
        }

        @Autowired
        void setOcppDataSourceHikari(@Qualifier("ocppDataSource1") HikariDataSource ocppDataSourceHikari) {
            this.ocppDataSourceHikari = ocppDataSourceHikari;
        }

        @Autowired
        void setOperatorDataSourceHikari(@Qualifier("operatorDataSource1") HikariDataSource operatorDataSourceHikari) {
            this.operatorDataSourceHikari = operatorDataSourceHikari;
        }
        */
    }

    // https://www.baeldung.com/java-generating-random-numbers-in-range
    private static int getRandomNumber(int min, int max) {
        return (int) ((Math.random() * (max - min)) + min);
    }
    
    @Benchmark
    @BenchmarkMode(Mode.SingleShotTime)
    public void connectAll(Blackhole bh,
                           BenchmarkState bs) throws SQLException {
        final HikariDataSource[] dataSources = new HikariDataSource[]
            { bs.authDataSourceHikari,
              bs.configDataSourceHikari,
              bs.domainDataSourceHikari,
              bs.ocpiDataSourceHikari,
              bs.ocppDataSourceHikari,
              bs.operatorDataSourceHikari };

        assert bs.authDataSourceHikari != null : "Data source bs.authDataSourceHikari should not be null";
        assert bs.configDataSourceHikari != null : "Data source bs.configDataSourceHikari should not be null";
        assert bs.domainDataSourceHikari != null : "Data source bs.domainDataSourceHikari should not be null";
        assert bs.ocpiDataSourceHikari != null : "Data source bs.ocpiDataSourceHikari should not be null";
        assert bs.ocppDataSourceHikari != null : "Data source bs.ocppDataSourceHikari should not be null";
        assert bs.operatorDataSourceHikari != null : "Data source bs.operatorDataSourceHikari should not be null";

        // bs.testList.parallelStream().forEach(idx -> { connect(bh, dataSources, idx); });        
        bs.testList.stream().forEach(idx -> { connect(bh, dataSources, idx); });        
    }

    private void connect(final Blackhole bh, final HikariDataSource[] dataSources, final int idx) {
        System.out.println("connect(" + dataSources + ", " + idx + ")");
        System.out.println("#1");

        assert idx >= 0 && idx < dataSources.length : "Index (" + idx + ") must be between 0 and " + dataSources.length;
        System.out.println("#2");
        assert dataSources[idx] != null : "Data source for index (" + idx + ") must not be null";
        System.out.println("#3");

        Connection conn = null;

        System.out.println("#4");

        try {
            System.out.println("data source: " + (dataSources[idx] == null ? "null" : dataSources[idx].toString()));
            
            conn = dataSources[idx].getConnection();

            System.out.println("#5");

            System.out.println("conn: " + conn);

            System.out.println("#6");

            assert conn != null : "Connection should not be null";

            System.out.println("#7");

            assert conn.getSchema() != null : "Connection schema should not be null";

            System.out.println("#8");

            
            System.out.println("schema: " + conn.getSchema());

            System.out.println("#9");

            bh.consume(conn.getSchema());

            System.out.println("#10");

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
