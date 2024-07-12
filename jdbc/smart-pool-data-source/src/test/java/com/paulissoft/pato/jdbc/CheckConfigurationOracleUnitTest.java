package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
//import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@ExtendWith(SpringExtension.class)
@EnableConfigurationProperties({MyDomainDataSourceOracle.class, MyOperatorDataSourceOracle.class})
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryOracle.class})
@TestPropertySource("classpath:application-test.properties")
public class CheckConfigurationOracleUnitTest {

    @Autowired
    private MyDomainDataSourceOracle domainDataSourceOracle;
    
    @Autowired
    private MyOperatorDataSourceOracle operatorDataSourceOracle;

    @BeforeAll
    static void clear() {
        PoolDataSourceStatistics.clear();
    }

    @Test
    void testPoolDataSourceConfigurationDomain() {
        PoolDataSourceConfiguration poolDataSourceConfiguration = domainDataSourceOracle.getPoolDataSource().get();
        
        log.debug("poolDataSourceConfiguration: {}", poolDataSourceConfiguration.toString());
        assertNull(poolDataSourceConfiguration.getDriverClassName());
        assertEquals("jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1", poolDataSourceConfiguration.getUrl());
        assertEquals("bodomain", poolDataSourceConfiguration.getUsername());
        // get() always returns null for these items
        assertNull(poolDataSourceConfiguration.getPassword());
        assertNull(poolDataSourceConfiguration.getPoolName());
        assertEquals(SimplePoolDataSourceOracle.class, poolDataSourceConfiguration.getType());
        assertEquals("PoolDataSourceConfigurationOracle(super=PoolDataSourceConfiguration(driverClassName=null, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bodomain, password=null, " + 
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceOracle), connectionPoolName=null, " +
                     "initialPoolSize=0, minPoolSize=9, maxPoolSize=9, connectionFactoryClassName=oracle.jdbc.pool.OracleDataSource, " +
                     "validateConnectionOnBorrow=false, abandonedConnectionTimeout=0, timeToLiveConnectionTimeout=0, " +
                     "inactiveConnectionTimeout=0, timeoutCheckInterval=30, maxStatements=10, connectionWaitDurationInMillis=0, " +
                     "maxConnectionReuseTime=0, secondsToTrustIdleConnection=0, connectionValidationTimeout=15)",
                     poolDataSourceConfiguration.toString());

        // the overflow
        poolDataSourceConfiguration = domainDataSourceOracle.getPoolDataSourceOverflow().get();

        assertEquals("PoolDataSourceConfigurationOracle(super=PoolDataSourceConfiguration(driverClassName=null, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bodomain, password=null, " + 
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceOracle), connectionPoolName=null, " +
                     "initialPoolSize=0, minPoolSize=0, maxPoolSize=14, connectionFactoryClassName=oracle.jdbc.pool.OracleDataSource, " +
                     "validateConnectionOnBorrow=false, abandonedConnectionTimeout=0, timeToLiveConnectionTimeout=0, " +
                     "inactiveConnectionTimeout=0, timeoutCheckInterval=30, maxStatements=10, connectionWaitDurationInMillis=0, " +
                     "maxConnectionReuseTime=0, secondsToTrustIdleConnection=0, connectionValidationTimeout=15)",
                     poolDataSourceConfiguration.toString());

        // overall
        poolDataSourceConfiguration = operatorDataSourceOracle.get();

        assertEquals("PoolDataSourceConfigurationOracle(super=PoolDataSourceConfiguration(driverClassName=null, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bodomain[boopapij], password=null, " + 
                     "type=class com.paulissoft.pato.jdbc.MyOperatorDataSourceOracle), connectionPoolName=null, " +
                     "initialPoolSize=0, minPoolSize=9, maxPoolSize=23, connectionFactoryClassName=oracle.jdbc.pool.OracleDataSource, " +
                     "validateConnectionOnBorrow=false, abandonedConnectionTimeout=0, timeToLiveConnectionTimeout=0, " +
                     "inactiveConnectionTimeout=0, timeoutCheckInterval=30, maxStatements=10, connectionWaitDurationInMillis=0, " +
                     "maxConnectionReuseTime=0, secondsToTrustIdleConnection=0, connectionValidationTimeout=15)",
                     poolDataSourceConfiguration.toString());
    }
    
    @Test
    void testPoolDataSourceConfigurationOperator() {
        PoolDataSourceConfiguration poolDataSourceConfiguration = operatorDataSourceOracle.getPoolDataSource().get();
        
        log.debug("poolDataSourceConfiguration: {}", poolDataSourceConfiguration.toString());
        
        assertNull(poolDataSourceConfiguration.getDriverClassName());
        assertEquals("jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1", poolDataSourceConfiguration.getUrl());
        assertEquals("bodomain[boopapij]", poolDataSourceConfiguration.getUsername());
        // get() always returns null for these items
        assertNull(poolDataSourceConfiguration.getPassword());
        assertNull(poolDataSourceConfiguration.getPoolName());
        assertEquals(SimplePoolDataSourceOracle.class, poolDataSourceConfiguration.getType());
        assertEquals("PoolDataSourceConfigurationOracle(super=PoolDataSourceConfiguration(driverClassName=null, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bodomain[boopapij], password=null, " + 
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceOracle), connectionPoolName=null, " +
                     "initialPoolSize=0, minPoolSize=9, maxPoolSize=9, connectionFactoryClassName=oracle.jdbc.pool.OracleDataSource, " +
                     "validateConnectionOnBorrow=false, abandonedConnectionTimeout=0, timeToLiveConnectionTimeout=0, " +
                     "inactiveConnectionTimeout=0, timeoutCheckInterval=30, maxStatements=10, connectionWaitDurationInMillis=0, " +
                     "maxConnectionReuseTime=0, secondsToTrustIdleConnection=0, connectionValidationTimeout=15)",
                     poolDataSourceConfiguration.toString());

        // the overflow
        poolDataSourceConfiguration = operatorDataSourceOracle.getPoolDataSourceOverflow().get();

        assertEquals("PoolDataSourceConfigurationOracle(super=PoolDataSourceConfiguration(driverClassName=null, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bodomain, password=null, " + 
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceOracle), connectionPoolName=null, " +
                     "initialPoolSize=0, minPoolSize=0, maxPoolSize=14, connectionFactoryClassName=oracle.jdbc.pool.OracleDataSource, " +
                     "validateConnectionOnBorrow=false, abandonedConnectionTimeout=0, timeToLiveConnectionTimeout=0, " +
                     "inactiveConnectionTimeout=0, timeoutCheckInterval=30, maxStatements=10, connectionWaitDurationInMillis=0, " +
                     "maxConnectionReuseTime=0, secondsToTrustIdleConnection=0, connectionValidationTimeout=15)",
                     poolDataSourceConfiguration.toString());

        // overall
        poolDataSourceConfiguration = operatorDataSourceOracle.get();

        assertEquals("PoolDataSourceConfigurationOracle(super=PoolDataSourceConfiguration(driverClassName=null, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bodomain[boopapij], password=null, " + 
                     "type=class com.paulissoft.pato.jdbc.MyOperatorDataSourceOracle), connectionPoolName=null, " +
                     "initialPoolSize=0, minPoolSize=9, maxPoolSize=23, connectionFactoryClassName=oracle.jdbc.pool.OracleDataSource, " +
                     "validateConnectionOnBorrow=false, abandonedConnectionTimeout=0, timeToLiveConnectionTimeout=0, " +
                     "inactiveConnectionTimeout=0, timeoutCheckInterval=30, maxStatements=10, connectionWaitDurationInMillis=0, " +
                     "maxConnectionReuseTime=0, secondsToTrustIdleConnection=0, connectionValidationTimeout=15)",
                     poolDataSourceConfiguration.toString());
    }
}
