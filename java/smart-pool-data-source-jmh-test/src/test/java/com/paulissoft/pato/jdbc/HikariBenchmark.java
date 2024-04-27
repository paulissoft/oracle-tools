package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.zaxxer.hikari.HikariDataSource;
import java.util.Arrays;
import java.util.List;
import java.sql.Connection;
import java.sql.SQLException;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.openjdk.jmh.annotations.Param;
import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.State;
import org.openjdk.jmh.annotations.Scope;

@Slf4j
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryHikari.class})
@TestPropertySource("classpath:application-test.properties")
@State(Scope.Benchmark)
public class HikariBenchmark {

    @Param({"10000"})
    public int divideLogicalConnectionsBy;
    
    private static final String[] schemas = new String[] {"boauth", "bocsconf", "boocpi", "boopapij", "bodomain", "boocpp15j"};
    private static final int[] logicalConnections = new int[] {20076, 10473, 10494, 14757, 19117, 14987};
    
    @Qualifier("authDataSource1")
    private static HikariDataSource authDataSourceHikari;
    
    @Qualifier("configDataSource1")
    private static HikariDataSource configDataSourceHikari;

    @Qualifier("domainDataSource1")
    private static HikariDataSource domainDataSourceHikari;

    @Qualifier("ocpiDataSource1")
    private static HikariDataSource ocpiDataSourceHikari;

    @Qualifier("ocppDataSource1")
    private static HikariDataSource ocppDataSourceHikari;

    @Qualifier("operatorDataSource1")
    private static HikariDataSource operatorDataSourceHikari;

    @Autowired
    void setAuthDataSourceHikari(HikariDataSource authDataSourceHikari) {
        HikariBenchmark.authDataSourceHikari = authDataSourceHikari;
    }

    @Autowired
    void setConfigDataSourceHikari(HikariDataSource configDataSourceHikari) {
        HikariBenchmark.configDataSourceHikari = configDataSourceHikari;
    }

    @Autowired
    void setDomainDataSourceHikari(HikariDataSource domainDataSourceHikari) {
        HikariBenchmark.domainDataSourceHikari = domainDataSourceHikari;
    }

    @Autowired
    void setOcpiDataSourceHikari(HikariDataSource ocpiDataSourceHikari) {
        HikariBenchmark.ocpiDataSourceHikari = ocpiDataSourceHikari;
    }

    @Autowired
    void setOcppDataSourceHikari(HikariDataSource ocppDataSourceHikari) {
        HikariBenchmark.ocppDataSourceHikari = ocppDataSourceHikari;
    }

    @Autowired
    void setOperatorDataSourceHikari(HikariDataSource operatorDataSourceHikari) {
        HikariBenchmark.operatorDataSourceHikari = operatorDataSourceHikari;
    }

    private int getRandomNumber(int min, int max) {
        return (int) ((Math.random() * (max - min)) + min);
    }
    
    @Benchmark
    public void connectAll() {
        final int[] logicalConnections = new int[HikariBenchmark.logicalConnections.length];
        int totalLogicalConnections = 0;
        
        for (int idx = 0; idx < logicalConnections.length; idx++) {
            logicalConnections[idx] = HikariBenchmark.logicalConnections[idx] / divideLogicalConnectionsBy;
            totalLogicalConnections += logicalConnections[idx];
        }        
    }    
}
