package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLTransientConnectionException;
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
@EnableConfigurationProperties({MyDomainDataSourceHikari.class, MyOperatorDataSourceHikari.class}) // keep it like that
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryHikari.class})
@TestPropertySource("classpath:application-test.properties")
public class CheckSmartHikariUnitTest {

    static final String REX_POOL_CLOSED = "^You can only get a connection when the pool state is OPEN but it is CLOSED.$";
    
    static final String REX_CONNECTION_TIMEOUT = SmartPoolDataSourceHikari.REX_CONNECTION_TIMEOUT;
    
    @Autowired
    @Qualifier("authDataSourceHikari1")
    private SmartPoolDataSourceHikari dataSourceHikariConfiguration;

    @Autowired
    @Qualifier("authDataSourceHikari2")
    private SmartPoolDataSourceHikari dataSourceHikari; // min/max pool size the same (without overflow)

    @Autowired
    @Qualifier("authDataSourceHikari3")
    private SmartPoolDataSourceHikari dataSourceHikariWithoutOverflow; // min/max pool size the same (without overflow)

    @Autowired
    @Qualifier("configDataSourceHikari3")
    private SmartPoolDataSourceHikari dataSourceHikariWithOverflow; // min/max pool size NOT the same (with overflow)

    @BeforeAll
    static void clear() {
        PoolDataSourceStatistics.clear();
    }

    //=== Hikari ===

    @Test
    void testPoolDataSourceConfiguration() throws SQLException {
        dataSourceHikariConfiguration.getConnection(); // must get a connection to stop initializing phase
        
        final PoolDataSourceConfigurationHikari poolDataSourceConfiguration =
            (PoolDataSourceConfigurationHikari) dataSourceHikariConfiguration.get();
        
        log.debug("poolDataSourceConfiguration: {}", poolDataSourceConfiguration.toString());
        
        assertEquals("PoolDataSourceConfigurationHikari(super=PoolDataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=bc_proxy[boauth], password=null, " + 
                     "type=class com.paulissoft.pato.jdbc.SmartPoolDataSourceHikari), poolName=null, " +
                     "maximumPoolSize=9, minimumIdle=9, dataSourceClassName=null, autoCommit=true, connectionTimeout=3000, " + 
                     "idleTimeout=600000, maxLifetime=1800000, connectionTestQuery=select 1 from dual, initializationFailTimeout=1, " +
                     "isolateInternalQueries=false, allowPoolSuspension=false, readOnly=false, registerMbeans=false, " +
                     "validationTimeout=5000, leakDetectionThreshold=0)",
                     poolDataSourceConfiguration.toString());
    }

    @Test
    void testConnection() throws SQLException {
        final String rex = REX_POOL_CLOSED;
        IllegalStateException thrown;
        Connection conn;
        
        log.debug("testConnection()");

        final SmartPoolDataSourceHikari pds = dataSourceHikari;

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

        thrown = assertThrows(IllegalStateException.class, () -> pds.getConnection());
        assertTrue(thrown.getMessage().matches(rex));
    }

    @Test
    void testConnectionsWithoutOverflow() throws SQLException {
        final String rex = REX_CONNECTION_TIMEOUT;
        SQLTransientConnectionException thrown;
        
        log.debug("testConnectionsWithoutOverflow()");

        final SmartPoolDataSourceHikari pds = dataSourceHikariWithoutOverflow;

        assertFalse(pds.hasOverflow());
        assertEquals(pds.getMinimumIdle(), pds.getMaximumPoolSize());

        final PoolDataSourceConfigurationHikari pdsConfigBefore =
            (PoolDataSourceConfigurationHikari) pds.get();

        // create all connections possible in the normal pool data source
        for (int j = 0; j < pds.getMinimumIdle(); j++) {
            assertNotNull(pds.getConnection());
        }

        assertTrue(pds.getMinimumIdle() <= pds.getTotalConnections()); // Hikari is not very reliable with active/idle/total connections
        assertEquals(pds.getActiveConnections() +
                     pds.getIdleConnections(),
                     pds.getTotalConnections());

        final PoolDataSourceConfigurationHikari pdsConfigAfter =
            (PoolDataSourceConfigurationHikari) pds.get();

        assertEquals(pdsConfigBefore, pdsConfigAfter);

        thrown = assertThrows(SQLTransientConnectionException.class, () -> {
                assertNotNull(pds.getConnection());
            });

        log.debug("message: {}", thrown.getMessage());
        
        assertTrue(thrown.getMessage().matches(rex));

        // close pds
        pds.close();
    }

    @Test
    void testConnectionsWithOverflow() throws SQLException {
        final String rex = REX_CONNECTION_TIMEOUT;
        SQLTransientConnectionException thrown;
        
        log.debug("testConnectionsWithOverflow()");

        final SmartPoolDataSourceHikari pds = dataSourceHikariWithOverflow;

        assertTrue(pds.hasOverflow());
        assertNotEquals(pds.getMinimumIdle(), pds.getMaximumPoolSize());

        final PoolDataSourceConfigurationHikari pdsConfigBefore =
            (PoolDataSourceConfigurationHikari) pds.getPoolDataSource().get();

        pds.getConnection().close(); // warm up: the first connection is via the overflow
        
        // create all connections possible in the normal pool data source
        for (int j = 0; j < pds.getMinimumIdle(); j++) {
            assertNotNull(pds.getConnection());
        }

        assertTrue(pds.getMinimumIdle() <= pds.getTotalConnections()); // Hikari is not very reliable with active/idle/total connections
        assertEquals(pds.getActiveConnections() +
                     pds.getIdleConnections(),
                     pds.getTotalConnections());

        final PoolDataSourceConfigurationHikari pdsConfigAfter =
            (PoolDataSourceConfigurationHikari) pds.getPoolDataSource().get();

        log.debug("pdsConfigAfter: {}", pdsConfigAfter);

        // because it is with overflow, the maximum pool size and connection timeout have been changed
        assertNotEquals(pdsConfigBefore, pdsConfigAfter);

        // reset the maximum pool size and connection timeout for the comparison
        pdsConfigAfter.setMaximumPoolSize(pdsConfigBefore.getMaximumPoolSize());
        pdsConfigAfter.setConnectionTimeout(pdsConfigBefore.getConnectionTimeout());
        
        assertEquals(pdsConfigBefore, pdsConfigAfter);

        // moving to overflow now: get all connections
        for (int j = pds.getMinimumIdle(); j < pds.getMaximumPoolSize(); j++) {
            assertNotNull(pds.getConnection());
        }

        // now it should fail
        thrown = assertThrows(SQLTransientConnectionException.class, () -> {
                assertNotNull(pds.getConnection());
            });

        log.debug("message: {}", thrown.getMessage());
        
        assertTrue(thrown.getMessage().matches(rex));

        // close pds
        pds.close();
    }
}
