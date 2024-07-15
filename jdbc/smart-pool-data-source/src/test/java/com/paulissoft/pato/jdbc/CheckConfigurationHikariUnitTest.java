package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
//import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

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
    }

    @Test
    void testPoolDataSourceConfigurationDomain() {
        domainDataSourceHikari.open(); // lazy initialization
        operatorDataSourceHikari.open(); // lazy initialization
        
        PoolDataSourceConfiguration poolDataSourceConfiguration = domainDataSourceHikari.getPoolDataSource().get();
        
        log.debug("poolDataSourceConfiguration: {}", poolDataSourceConfiguration.toString());
        
        assertEquals("oracle.jdbc.OracleDriver", poolDataSourceConfiguration.getDriverClassName());
        assertEquals("jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1", poolDataSourceConfiguration.getUrl());
        assertEquals("bodomain", poolDataSourceConfiguration.getUsername());
        // get() always returns null for these items
        assertNull(poolDataSourceConfiguration.getPassword());
        assertNull(poolDataSourceConfiguration.getPoolName());
        assertEquals(SimplePoolDataSourceHikari.class, poolDataSourceConfiguration.getType());
        assertEquals("PoolDataSourceConfigurationHikari(super=PoolDataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bodomain, password=null, " + 
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari), poolName=null, " +
                     "maximumPoolSize=9, minimumIdle=9, dataSourceClassName=null, autoCommit=true, connectionTimeout=250, " + 
                     "idleTimeout=600000, maxLifetime=1800000, connectionTestQuery=select 1 from dual, initializationFailTimeout=1, " +
                     "isolateInternalQueries=false, allowPoolSuspension=false, readOnly=false, registerMbeans=false, " +
                     "validationTimeout=5000, leakDetectionThreshold=0)",
                     poolDataSourceConfiguration.toString());

        // the overflow
        poolDataSourceConfiguration = domainDataSourceHikari.getPoolDataSourceOverflow().get();
        
        assertEquals("PoolDataSourceConfigurationHikari(super=PoolDataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bodomain, password=null, " + 
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari), poolName=null, " +
                     "maximumPoolSize=14, minimumIdle=0, dataSourceClassName=null, autoCommit=true, connectionTimeout=2750, " + 
                     "idleTimeout=10000, maxLifetime=30000, connectionTestQuery=select 1 from dual, initializationFailTimeout=1, " +
                     "isolateInternalQueries=false, allowPoolSuspension=false, readOnly=false, registerMbeans=false, " +
                     "validationTimeout=5000, leakDetectionThreshold=0)",
                     poolDataSourceConfiguration.toString());

        // overall
        poolDataSourceConfiguration = domainDataSourceHikari.get();

        assertEquals("PoolDataSourceConfigurationHikari(super=PoolDataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bodomain, password=null, " + 
                     "type=class com.paulissoft.pato.jdbc.MyDomainDataSourceHikari), poolName=null, " +
                     "maximumPoolSize=23, minimumIdle=9, dataSourceClassName=null, autoCommit=true, connectionTimeout=3000, " + 
                     "idleTimeout=600000, maxLifetime=1800000, connectionTestQuery=select 1 from dual, initializationFailTimeout=1, " +
                     "isolateInternalQueries=false, allowPoolSuspension=false, readOnly=false, registerMbeans=false, " +
                     "validationTimeout=5000, leakDetectionThreshold=0)",
                     poolDataSourceConfiguration.toString());
    }
    
    @Test
    void testPoolDataSourceConfigurationOperator() {
        domainDataSourceHikari.open(); // lazy initialization
        operatorDataSourceHikari.open(); // lazy initialization
        
        PoolDataSourceConfiguration poolDataSourceConfiguration = operatorDataSourceHikari.getPoolDataSource().get();
        
        log.debug("poolDataSourceConfiguration: {}", poolDataSourceConfiguration.toString());
        
        assertEquals("oracle.jdbc.OracleDriver", poolDataSourceConfiguration.getDriverClassName());
        assertEquals("jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1", poolDataSourceConfiguration.getUrl());
        assertEquals("bodomain[boopapij]", poolDataSourceConfiguration.getUsername());
        // get() always returns null for these items
        assertNull(poolDataSourceConfiguration.getPassword());
        assertNull(poolDataSourceConfiguration.getPoolName());
        assertEquals(SimplePoolDataSourceHikari.class, poolDataSourceConfiguration.getType());
        assertEquals("PoolDataSourceConfigurationHikari(super=PoolDataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bodomain[boopapij], password=null, " + 
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari), poolName=null, " +
                     "maximumPoolSize=9, minimumIdle=9, dataSourceClassName=null, autoCommit=true, connectionTimeout=250, " + 
                     "idleTimeout=600000, maxLifetime=1800000, connectionTestQuery=select 1 from dual, initializationFailTimeout=1, " +
                     "isolateInternalQueries=false, allowPoolSuspension=false, readOnly=false, registerMbeans=false, " +
                     "validationTimeout=5000, leakDetectionThreshold=0)",
                     poolDataSourceConfiguration.toString());

        // the overflow
        poolDataSourceConfiguration = operatorDataSourceHikari.getPoolDataSourceOverflow().get();
        
        assertEquals("PoolDataSourceConfigurationHikari(super=PoolDataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bodomain, password=null, " + 
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari), poolName=null, " +
                     "maximumPoolSize=14, minimumIdle=0, dataSourceClassName=null, autoCommit=true, connectionTimeout=2750, " + 
                     "idleTimeout=10000, maxLifetime=30000, connectionTestQuery=select 1 from dual, initializationFailTimeout=1, " +
                     "isolateInternalQueries=false, allowPoolSuspension=false, readOnly=false, registerMbeans=false, " +
                     "validationTimeout=5000, leakDetectionThreshold=0)",
                     poolDataSourceConfiguration.toString());

        // overall
        poolDataSourceConfiguration = operatorDataSourceHikari.get();

        assertEquals("PoolDataSourceConfigurationHikari(super=PoolDataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bodomain[boopapij], password=null, " + 
                     "type=class com.paulissoft.pato.jdbc.MyOperatorDataSourceHikari), poolName=null, " +
                     "maximumPoolSize=23, minimumIdle=9, dataSourceClassName=null, autoCommit=true, connectionTimeout=3000, " + 
                     "idleTimeout=600000, maxLifetime=1800000, connectionTestQuery=select 1 from dual, initializationFailTimeout=1, " +
                     "isolateInternalQueries=false, allowPoolSuspension=false, readOnly=false, registerMbeans=false, " +
                     "validationTimeout=5000, leakDetectionThreshold=0)",
                     poolDataSourceConfiguration.toString());
    }
}
