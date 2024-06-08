package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
//import static org.junit.jupiter.api.Assertions.assertNull;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@ExtendWith(SpringExtension.class)
@EnableConfigurationProperties({MyDomainDataSourceHikari.class, MyOperatorDataSourceHikari.class})
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryHikari.class})
@TestPropertySource("classpath:application-test.properties")
public class CheckConfigurationHikariUnitTest {

    @Autowired
    private MyDomainDataSourceHikari domainDataSourceHikari;
    
    @Autowired
    private MyOperatorDataSourceHikari operatorDataSourceHikari;

    @BeforeAll
    static void clear() {
        PoolDataSourceStatistics.clear();
        CombiPoolDataSource.clear();
    }

    @Test
    void testPoolDataSourceConfigurationDomain() {
        final PoolDataSourceConfiguration poolDataSourceConfiguration = domainDataSourceHikari.getPoolDataSourceConfiguration();
        
        log.debug("poolDataSourceConfiguration: {}", poolDataSourceConfiguration.toString());
        
        assertNotEquals(operatorDataSourceHikari.isParentPoolDataSource(), domainDataSourceHikari.isParentPoolDataSource());
        assertEquals("oracle.jdbc.OracleDriver", poolDataSourceConfiguration.getDriverClassName());
        assertEquals("jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1", poolDataSourceConfiguration.getUrl());
        assertEquals("bodomain", poolDataSourceConfiguration.getUsername());
        assertEquals("bodomain", poolDataSourceConfiguration.getPassword());
        assertEquals(CombiPoolDataSourceHikari.class, poolDataSourceConfiguration.getType());
        assertEquals("PoolDataSourceConfigurationHikari(super=PoolDataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bodomain, password=bodomain, " + 
                     "type=class com.paulissoft.pato.jdbc.CombiPoolDataSourceHikari), poolName=HikariPool-bodomain, " +
                     "maximumPoolSize=20, minimumIdle=10, dataSourceClassName=null, autoCommit=true, connectionTimeout=30000, " + 
                     "idleTimeout=600000, maxLifetime=1800000, connectionTestQuery=select 1 from dual, initializationFailTimeout=1, " +
                     "isolateInternalQueries=false, allowPoolSuspension=false, readOnly=false, registerMbeans=false, " +
                     "validationTimeout=5000, leakDetectionThreshold=0)",
                     poolDataSourceConfiguration.toString());
    }
    
    @Test
    void testPoolDataSourceConfigurationOperator() {
        final PoolDataSourceConfiguration poolDataSourceConfiguration = operatorDataSourceHikari.getPoolDataSourceConfiguration();
        
        log.debug("poolDataSourceConfiguration: {}", poolDataSourceConfiguration.toString());
        
        assertEquals("oracle.jdbc.OracleDriver", poolDataSourceConfiguration.getDriverClassName());
        assertEquals("jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1", poolDataSourceConfiguration.getUrl());
        assertEquals("bodomain[boopapij]", poolDataSourceConfiguration.getUsername());
        assertEquals("bodomain", poolDataSourceConfiguration.getPassword());
        assertEquals(CombiPoolDataSourceHikari.class, poolDataSourceConfiguration.getType());
        assertEquals("PoolDataSourceConfigurationHikari(super=PoolDataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bodomain[boopapij], password=bodomain, " + 
                     "type=class com.paulissoft.pato.jdbc.CombiPoolDataSourceHikari), poolName=HikariPool-boopapij, " +
                     "maximumPoolSize=20, minimumIdle=10, dataSourceClassName=null, autoCommit=true, connectionTimeout=30000, " + 
                     "idleTimeout=600000, maxLifetime=1800000, connectionTestQuery=select 1 from dual, initializationFailTimeout=1, " +
                     "isolateInternalQueries=false, allowPoolSuspension=false, readOnly=false, registerMbeans=false, " +
                     "validationTimeout=5000, leakDetectionThreshold=0)",
                     poolDataSourceConfiguration.toString());
    }
    
    @Test
    void testPoolDataSource() {
        // the combined pool data source
        assertEquals(domainDataSourceHikari.getPoolDataSource(), operatorDataSourceHikari.getPoolDataSource());
        
        final SimplePoolDataSourceHikari simplePoolDataSourceHikari = domainDataSourceHikari.getPoolDataSource();
            
        assertEquals(domainDataSourceHikari.isParentPoolDataSource() ?
                     "HikariPool-bodomain-boopapij" :
                     "HikariPool-boopapij-bodomain",
                     simplePoolDataSourceHikari.getPoolName());
        assertEquals(2 * 20, simplePoolDataSourceHikari.getMaximumPoolSize());
        assertEquals(2 * 10, simplePoolDataSourceHikari.getMinimumIdle());
        assertEquals(null, simplePoolDataSourceHikari.getDataSourceClassName());
        assertEquals(true, simplePoolDataSourceHikari.isAutoCommit());
        assertEquals(30000, simplePoolDataSourceHikari.getConnectionTimeout());
        assertEquals(600000, simplePoolDataSourceHikari.getIdleTimeout());
        assertEquals(1800000, simplePoolDataSourceHikari.getMaxLifetime());
        assertEquals("select 1 from dual", simplePoolDataSourceHikari.getConnectionTestQuery());
        assertEquals(1, simplePoolDataSourceHikari.getInitializationFailTimeout());
        assertEquals(false, simplePoolDataSourceHikari.isIsolateInternalQueries());
        assertEquals(false, simplePoolDataSourceHikari.isAllowPoolSuspension());
        assertEquals(false, simplePoolDataSourceHikari.isReadOnly());
        assertEquals(false, simplePoolDataSourceHikari.isRegisterMbeans());
        assertEquals(5000, simplePoolDataSourceHikari.getValidationTimeout());
        assertEquals(0, simplePoolDataSourceHikari.getLeakDetectionThreshold());
    }
}
