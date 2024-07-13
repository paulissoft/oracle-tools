package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

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

@Slf4j
@ExtendWith(SpringExtension.class)
@EnableConfigurationProperties({MyDomainDataSourceOracle.class, MyOperatorDataSourceOracle.class}) // keep it like that
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryOracle.class})
@TestPropertySource("classpath:application-test.properties")
public class CheckSmartOracleUnitTest {

    static final String REX_POOL_CLOSED = "^You can only get a connection when the pool state is OPEN but it is CLOSED.$";
    
    static final String REX_CONNECTION_TIMEOUT = SmartPoolDataSourceOracle.REX_CONNECTION_TIMEOUT;

    // all data sources must have different pool names otherwise we risk UCP-0 (can not start pool)
    @Autowired
    @Qualifier("ocpiDataSourceOracle3")
    private SmartPoolDataSourceOracle dataSourceOracleConfiguration;

    @Autowired
    @Qualifier("ocppDataSourceOracle3")
    private SmartPoolDataSourceOracle dataSourceOracle;

    @Autowired
    @Qualifier("authDataSourceOracle1")
    private SmartPoolDataSourceOracle dataSourceOracleWithoutOverflow; // min/max pool size the same (without overflow)

    @Autowired
    @Qualifier("configDataSourceOracle3")
    private SmartPoolDataSourceOracle dataSourceOracleWithOverflow; // min/max pool size NOT the same (with overflow)

    @BeforeAll
    static void clear() {
        PoolDataSourceStatistics.clear();
    }

    //=== Oracle ===

    @Test
    void testPoolDataSourceConfiguration() throws SQLException {
        dataSourceOracleConfiguration.getConnection(); // must get a connection to stop initializing phase
        
        final PoolDataSourceConfigurationOracle poolDataSourceConfiguration =
            (PoolDataSourceConfigurationOracle) dataSourceOracleConfiguration.get();
        
        log.debug("poolDataSourceConfiguration: {}", poolDataSourceConfiguration.toString());
        
        assertEquals("PoolDataSourceConfigurationOracle(super=PoolDataSourceConfiguration(driverClassName=null, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bc_proxy[boocpi], password=null, " + 
                     "type=class com.paulissoft.pato.jdbc.SmartPoolDataSourceOracle), connectionPoolName=null, " +
                     "initialPoolSize=1, minPoolSize=1, maxPoolSize=4, connectionFactoryClassName=oracle.jdbc.pool.OracleDataSource, " +
                     "validateConnectionOnBorrow=true, abandonedConnectionTimeout=0, timeToLiveConnectionTimeout=0, " +
                     "inactiveConnectionTimeout=0, timeoutCheckInterval=30, maxStatements=10, connectionWaitDurationInMillis=0, " +
                     "maxConnectionReuseTime=0, secondsToTrustIdleConnection=120, connectionValidationTimeout=15)",
                     poolDataSourceConfiguration.toString());
    }

    @Test
    void testConnection() throws SQLException {
        final String rex = REX_POOL_CLOSED;
        IllegalStateException thrown;
        Connection conn;
        
        log.debug("testConnection()");

        final SmartPoolDataSourceOracle pds = dataSourceOracle;

        // get some connections
        for (int j = 0; j < 2; j++) {
            assertNotNull(conn = pds.getConnection());
            assertTrue(pds.isOpen());

            assertEquals(1, pds.getActiveConnections());
            assertEquals(0, pds.getIdleConnections());
            assertEquals(pds.getActiveConnections() +
                         pds.getIdleConnections(),
                         pds.getTotalConnections());

            conn.close();
        }

        // close pds
        assertTrue(pds.isOpen());
        pds.close();
        assertFalse(pds.isOpen());

        thrown = assertThrows(IllegalStateException.class, pds::getConnection);

        log.debug("message: {}", thrown.getMessage());
        
        assertTrue(thrown.getMessage().matches(rex));
    }

    @Test
    void testConnectionsWithoutOverflow() throws SQLException {
        final String rex = REX_CONNECTION_TIMEOUT;
        SQLException thrown;
        
        log.debug("testConnectionsWithoutOverflow()");

        final SmartPoolDataSourceOracle pds = dataSourceOracleWithoutOverflow;

        assertFalse(pds.hasOverflow());
        assertEquals(pds.getMinPoolSize(), pds.getMaxPoolSize());

        final PoolDataSourceConfigurationOracle pdsConfigBefore =
            (PoolDataSourceConfigurationOracle) pds.getPoolDataSource().get();

        // create all connections possible in the normal pool data source
        for (int j = 0; j < pds.getMinPoolSize(); j++) {
            assertNotNull(pds.getConnection());
            log.debug("[{}] pds.getActiveConnections(): {}", j, pds.getActiveConnections());
        }

        assertTrue(pds.getMinPoolSize() <= pds.getTotalConnections());
        assertEquals(pds.getActiveConnections() +
                     pds.getIdleConnections(),
                     pds.getTotalConnections());

        final PoolDataSourceConfigurationOracle pdsConfigAfter =
            (PoolDataSourceConfigurationOracle) pds.getPoolDataSource().get();

        assertEquals(pdsConfigBefore, pdsConfigAfter);

        thrown = assertThrows(SQLException.class, () -> assertNotNull(pds.getConnection()));

        log.debug("message: {}", thrown.getMessage());
        
        assertTrue(thrown.getMessage().matches(rex));

        // close pds
        pds.close();
    }

    @Test
    void testConnectionsWithOverflow() throws SQLException {
        final String rex = REX_CONNECTION_TIMEOUT;
        SQLException thrown;
        
        log.debug("testConnectionsWithOverflow()");

        final SmartPoolDataSourceOracle pds = dataSourceOracleWithOverflow;

        assertTrue(pds.hasOverflow());
        assertNotEquals(pds.getMinPoolSize(), pds.getMaxPoolSize());

        final PoolDataSourceConfigurationOracle pdsConfigBefore =
            (PoolDataSourceConfigurationOracle) pds.getPoolDataSource().get();

        pds.getConnection().close(); // warm up: the first connection may be via the overflow

        // create all connections possible in the normal pool data source
        for (int j = 0; j < pds.getMinPoolSize(); j++) {
            assertNotNull(pds.getConnection());
        }

        assertTrue(pds.getMinPoolSize() <= pds.getTotalConnections()); // Oracle is not very reliable with active/idle/total connections
        assertEquals(pds.getActiveConnections() +
                     pds.getIdleConnections(),
                     pds.getTotalConnections());

        final PoolDataSourceConfigurationOracle pdsConfigAfter =
            (PoolDataSourceConfigurationOracle) pds.getPoolDataSource().get();

        log.debug("pdsConfigAfter: {}", pdsConfigAfter);

        // because it is with overflow, the max pool size and connection wait timeout have been changed
        assertNotEquals(pdsConfigBefore, pdsConfigAfter);

        // reset the max pool size and connection wait timeout for the comparison
        pdsConfigAfter.setMaxPoolSize(pdsConfigBefore.getMaxPoolSize());
        pdsConfigAfter.setConnectionWaitDurationInMillis(pdsConfigBefore.getConnectionWaitDurationInMillis());
        
        assertEquals(pdsConfigBefore, pdsConfigAfter);

        // moving to overflow now: get all connections
        for (int j = pds.getMinPoolSize(); j < pds.getMaxPoolSize(); j++) {
            assertNotNull(pds.getConnection());
        }

        // now it should fail
        thrown = assertThrows(SQLException.class, () -> assertNotNull(pds.getConnection()));

        log.debug("message: {}", thrown.getMessage());
        
        assertTrue(thrown.getMessage().matches(rex));

        // close pds
        pds.close();
    }
}
