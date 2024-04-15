package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
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
        CombiPoolDataSource.clear();
    }

    @Test
    void testPoolDataSourceConfigurationDomain() {
        final PoolDataSourceConfiguration poolDataSourceConfiguration = domainDataSourceOracle.getPoolDataSourceConfiguration();
        
        log.debug("poolDataSourceConfiguration: {}", poolDataSourceConfiguration.toString());
        
        assertNull(poolDataSourceConfiguration.getDriverClassName());
        assertEquals("jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1", poolDataSourceConfiguration.getUrl());
        assertEquals("bc_proxy[bodomain]", poolDataSourceConfiguration.getUsername());
        assertEquals("bc_proxy", poolDataSourceConfiguration.getPassword());
        assertEquals(CombiPoolDataSourceOracle.class, poolDataSourceConfiguration.getType());
        assertEquals("PoolDataSourceConfigurationOracle(super=PoolDataSourceConfiguration(driverClassName=null, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bc_proxy[bodomain], password=bc_proxy, " + 
                     "type=class com.paulissoft.pato.jdbc.CombiPoolDataSourceOracle), connectionPoolName=OraclePool-boopapij-bodomain, " +
                     "initialPoolSize=0, minPoolSize=10, maxPoolSize=20, connectionFactoryClassName=oracle.jdbc.pool.OracleDataSource, " +
                     "validateConnectionOnBorrow=true, abandonedConnectionTimeout=120, timeToLiveConnectionTimeout=120, " +
                     "inactiveConnectionTimeout=0, timeoutCheckInterval=30, maxStatements=10, connectionWaitTimeout=3, " +
                     "maxConnectionReuseTime=0, secondsToTrustIdleConnection=120, connectionValidationTimeout=15)",
                     poolDataSourceConfiguration.toString());
    }
    
    @Test
    void testPoolDataSourceConfigurationOperator() {
        final PoolDataSourceConfiguration poolDataSourceConfiguration = operatorDataSourceOracle.getPoolDataSourceConfiguration();
        
        log.debug("poolDataSourceConfiguration: {}", poolDataSourceConfiguration.toString());
        
        assertNull(poolDataSourceConfiguration.getDriverClassName());
        assertEquals("jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1", poolDataSourceConfiguration.getUrl());
        assertEquals("bc_proxy[boopapij]", poolDataSourceConfiguration.getUsername());
        assertEquals("bc_proxy", poolDataSourceConfiguration.getPassword());
        assertEquals(CombiPoolDataSourceOracle.class, poolDataSourceConfiguration.getType());
        assertEquals("PoolDataSourceConfigurationOracle(super=PoolDataSourceConfiguration(driverClassName=null, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bc_proxy[boopapij], password=bc_proxy, " + 
                     "type=class com.paulissoft.pato.jdbc.CombiPoolDataSourceOracle), connectionPoolName=OraclePool-boopapij, " +
                     "initialPoolSize=0, minPoolSize=10, maxPoolSize=20, connectionFactoryClassName=oracle.jdbc.pool.OracleDataSource, " +
                     "validateConnectionOnBorrow=true, abandonedConnectionTimeout=120, timeToLiveConnectionTimeout=120, " +
                     "inactiveConnectionTimeout=0, timeoutCheckInterval=30, maxStatements=10, connectionWaitTimeout=3, " +
                     "maxConnectionReuseTime=0, secondsToTrustIdleConnection=120, connectionValidationTimeout=15)",
                     poolDataSourceConfiguration.toString());
    }
    
    @Test
    void testPoolDataSource() {
        // the combined pool data source
        for (int nr = 0; nr < 2; nr++) {
            final SimplePoolDataSourceOracle simplePoolDataSourceOracle =
                nr == 0 ? domainDataSourceOracle.getPoolDataSource() : operatorDataSourceOracle.getPoolDataSource();
            
            assertEquals("OraclePool-boopapij-bodomain", simplePoolDataSourceOracle.getConnectionPoolName());
            assertEquals(0, simplePoolDataSourceOracle.getInitialPoolSize());
            assertEquals(2 * 10, simplePoolDataSourceOracle.getMinPoolSize());
            assertEquals(2 * 20, simplePoolDataSourceOracle.getMaxPoolSize());
            assertEquals("oracle.jdbc.pool.OracleDataSource", simplePoolDataSourceOracle.getConnectionFactoryClassName());
            assertEquals(true, simplePoolDataSourceOracle.getValidateConnectionOnBorrow());
            assertEquals(120, simplePoolDataSourceOracle.getAbandonedConnectionTimeout());
            assertEquals(120, simplePoolDataSourceOracle.getTimeToLiveConnectionTimeout());
            assertEquals(0, simplePoolDataSourceOracle.getInactiveConnectionTimeout());
            assertEquals(30, simplePoolDataSourceOracle.getTimeoutCheckInterval());
            assertEquals(10, simplePoolDataSourceOracle.getMaxStatements());
            assertEquals(3, simplePoolDataSourceOracle.getConnectionWaitTimeout());
            assertEquals(0, simplePoolDataSourceOracle.getMaxConnectionReuseTime());
            assertEquals(120, simplePoolDataSourceOracle.getSecondsToTrustIdleConnection());
            assertEquals(15, simplePoolDataSourceOracle.getConnectionValidationTimeout());
        }
    }
}
