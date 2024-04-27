package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
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
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.test.context.junit4.SpringRunner;

//@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryHikari.class})
@TestPropertySource("classpath:application-test.properties")

@SpringBootTest
@State(Scope.Benchmark)
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MICROSECONDS)
@RunWith(SpringRunner.class)
public class HikariBenchmark {

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
        HikariBenchmark.authDataSourceHikari = authDataSourceHikari;
    }

    @Autowired
    void setConfigDataSourceHikari(@Qualifier("configDataSource1") HikariDataSource configDataSourceHikari) {
        HikariBenchmark.configDataSourceHikari = configDataSourceHikari;
    }

    @Autowired
    void setDomainDataSourceHikari(@Qualifier("domainDataSource1") HikariDataSource domainDataSourceHikari) {
        HikariBenchmark.domainDataSourceHikari = domainDataSourceHikari;
    }

    @Autowired
    void setOcpiDataSourceHikari(@Qualifier("ocpiDataSource1") HikariDataSource ocpiDataSourceHikari) {
        HikariBenchmark.ocpiDataSourceHikari = ocpiDataSourceHikari;
    }

    @Autowired
    void setOcppDataSourceHikari(@Qualifier("ocppDataSource1") HikariDataSource ocppDataSourceHikari) {
        HikariBenchmark.ocppDataSourceHikari = ocppDataSourceHikari;
    }

    @Autowired
    void setOperatorDataSourceHikari(@Qualifier("operatorDataSource1") HikariDataSource operatorDataSourceHikari) {
        HikariBenchmark.operatorDataSourceHikari = operatorDataSourceHikari;
    }

    private int getRandomNumber(int min, int max) {
        return (int) ((Math.random() * (max - min)) + min);
    }
    
    @Benchmark
    public void connectAll(Blackhole bh) throws SQLException {
        final int[] logicalConnections = new int[HikariBenchmark.logicalConnections.length];
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
            logicalConnections[idx] = HikariBenchmark.logicalConnections[idx] / divideLogicalConnectionsBy;
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
