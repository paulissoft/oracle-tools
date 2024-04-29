package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.sql.SQLException;
import org.junit.runner.RunWith;
import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.BenchmarkMode;
import org.openjdk.jmh.annotations.Mode;
import org.openjdk.jmh.annotations.OutputTimeUnit;
import org.openjdk.jmh.annotations.Param;
import org.openjdk.jmh.annotations.Scope;
import org.openjdk.jmh.annotations.State;
import java.util.concurrent.TimeUnit;
import org.openjdk.jmh.infra.Blackhole;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit4.SpringRunner;

//@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryHikari.class})
@TestPropertySource("classpath:application-test.properties")

@SpringBootTest
@State(Scope.Benchmark)
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MICROSECONDS)
@RunWith(SpringRunner.class)
public class HikariTest extends AbstractBenchmark {

    private static final String[] schemas = new String[] {"boauth", "bocsconf", "boocpi", "boopapij", "bodomain", "boocpp15j"};

    private static final int[] logicalConnections = new int[] {20076, 10473, 10494, 14757, 19117, 14987};
        
    private static HikariDataSource authDataSourceHikari;
        
    private static HikariDataSource configDataSourceHikari;
    
    private static HikariDataSource domainDataSourceHikari;
    
    private static HikariDataSource ocpiDataSourceHikari;
    
    private static HikariDataSource ocppDataSourceHikari;
    
    private static HikariDataSource operatorDataSourceHikari;

    @Param({"10000"})
    public int divideLogicalConnectionsBy;
    
    @Autowired
    void setAuthDataSourceHikari(@Qualifier("authDataSource1") HikariDataSource authDataSourceHikari) {
        HikariTest.authDataSourceHikari = authDataSourceHikari;
    }

    @Autowired
    void setConfigDataSourceHikari(@Qualifier("configDataSource1") HikariDataSource configDataSourceHikari) {
        HikariTest.configDataSourceHikari = configDataSourceHikari;
    }

    @Autowired
    void setDomainDataSourceHikari(@Qualifier("domainDataSource1") HikariDataSource domainDataSourceHikari) {
        HikariTest.domainDataSourceHikari = domainDataSourceHikari;
    }

    @Autowired
    void setOcpiDataSourceHikari(@Qualifier("ocpiDataSource1") HikariDataSource ocpiDataSourceHikari) {
        HikariTest.ocpiDataSourceHikari = ocpiDataSourceHikari;
    }

    @Autowired
    void setOcppDataSourceHikari(@Qualifier("ocppDataSource1") HikariDataSource ocppDataSourceHikari) {
        HikariTest.ocppDataSourceHikari = ocppDataSourceHikari;
    }

    @Autowired
    void setOperatorDataSourceHikari(@Qualifier("operatorDataSource1") HikariDataSource operatorDataSourceHikari) {
        HikariTest.operatorDataSourceHikari = operatorDataSourceHikari;
    }

    private int getRandomNumber(int min, int max) {
        return (int) ((Math.random() * (max - min)) + min);
    }
    
    @Benchmark
    public void connectAll(Blackhole bh) throws SQLException {
        final int[] logicalConnections = new int[HikariTest.logicalConnections.length];
        final HikariDataSource[] dataSources = new HikariDataSource[]
            { authDataSourceHikari,
              configDataSourceHikari,
              domainDataSourceHikari,
              ocpiDataSourceHikari,
              ocppDataSourceHikari,
              operatorDataSourceHikari };
        int totalLogicalConnections = 0;
        int idx;
        
        for (idx = 0; idx < logicalConnections.length; idx++) {
            logicalConnections[idx] = HikariTest.logicalConnections[idx] / divideLogicalConnectionsBy;
            totalLogicalConnections += logicalConnections[idx];    
        }

        while (totalLogicalConnections > 0) {
            do {
                idx = getRandomNumber(0, logicalConnections.length);
            } while (logicalConnections[idx] == 0);

            try (final Connection conn = dataSources[idx].getConnection()) {
                bh.consume(conn.getSchema());
            }
            
            logicalConnections[idx]--;
            totalLogicalConnections--;
        }
    }    
}
