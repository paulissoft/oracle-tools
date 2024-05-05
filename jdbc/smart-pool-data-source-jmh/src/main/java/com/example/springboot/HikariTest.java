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

    private static final int[] logicalConnections = new int[] {20076, 10473, 10494, 14757, 19117, 14987};
        
    @Param({"10000"})
    public int divideLogicalConnectionsBy;

    public List<Integer> testList = new Vector(1000, 1000);

    @Setup(Level.Trial)
    public void setUp() {
        final int[] logicalConnections = new int[HikariTest.logicalConnections.length];
        int totalLogicalConnections = 0;
        int idx;
            
        for (idx = 0; idx < logicalConnections.length; idx++) {
            logicalConnections[idx] = HikariTest.logicalConnections[idx] / divideLogicalConnectionsBy;
            assert logicalConnections[idx] > 0;
            totalLogicalConnections += logicalConnections[idx];    
        }

        while (totalLogicalConnections > 0) {
            do {
                idx = getRandomNumber(0, logicalConnections.length);
            } while (logicalConnections[idx] == 0);

            assert logicalConnections[idx] > 0;

            logicalConnections[idx]--;
            totalLogicalConnections--;

            testList.add(idx);
        }
    }

    @State(Scope.Benchmark)
    public static class BenchmarkState {

        @Autowired
        @Qualifier("authDataSource1")
        private static HikariDataSource authDataSourceHikari;

        /*        
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
        */
        
        @Setup(Level.Trial)
        public void setUp() {
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
            { bs.authDataSourceHikari/*,
              bs.configDataSourceHikari,
              bs.domainDataSourceHikari,
              bs.ocpiDataSourceHikari,
              bs.ocppDataSourceHikari,
              bs.operatorDataSourceHikari*/ };

        assert bs.authDataSourceHikari != null;

        testList.parallelStream().forEach(idx -> {
                try (final Connection conn = dataSources[idx].getConnection()) {
                    bh.consume(conn.getSchema());
                } catch (SQLException ex) {
                    throw new RuntimeException(ex.getMessage());
                }});        
    }    
}