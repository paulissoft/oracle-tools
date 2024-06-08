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
public class CheckOverflowHikariUnitTest {

    @Autowired
    @Qualifier("configDataSource3")
    private OverflowPoolDataSourceHikari configDataSourceHikari;

    //=== Hikari ===

    @Test
    void testConnection() throws SQLException {
        final String rex = "^You can only get a connection when the pool state is OPEN but it is CLOSED.$";
        IllegalStateException thrown;
        Connection conn;
        
        log.debug("testConnection()");

        final OverflowPoolDataSourceHikari pds = configDataSourceHikari;

        // get some connections
        for (int j = 0; j < 2; j++) {
            assertNotNull(conn = pds.getConnection());
            assertTrue(pds.isOpen());

            assertTrue(pds.getActiveConnections() >= 1);
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
        final String rex = "^HikariPool-bocsconf - Connection is not available, request timed out after \\d+ms.$";
        SQLTransientConnectionException thrown;
        
        log.debug("testConnectionsWithoutOverflow()");

        final OverflowPoolDataSourceHikari pds = configDataSourceHikari;

        // set max to min to be able to get the SQL error on timeout
        pds.setMaximumPoolSize(pds.getMinimumIdle());
        pds.setConnectionTimeout(1000); // just 1 second for a timeout

        assertEquals(pds.getMinimumIdle(), pds.getMaximumPoolSize());

        final PoolDataSourceConfigurationHikari pdsConfigBefore =
            (PoolDataSourceConfigurationHikari) pds.get();

        // create all connections possible in the normal pool data source
        for (int j = 0; j < pds.getMinimumIdle(); j++) {
            assertNotNull(pds.getConnection());
        }

        assertEquals(pds.getMinimumIdle(), pds.getActiveConnections());
        assertEquals(0, pds.getIdleConnections());
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
        final String rex = "^HikariPool-\\s+ - Connection is not available, request timed out after \\d+ms.$";
        SQLTransientConnectionException thrown;
        
        log.debug("testConnectionsWithOverflow()");

        final OverflowPoolDataSourceHikari pds = configDataSourceHikari;

        // set max to min + 1 to be able to get the SQL error on timeout
        pds.setMaximumPoolSize(pds.getMinimumIdle() + 2);
        pds.setConnectionTimeout(1000); // just 1 second for a timeout

        assertNotEquals(pds.getMinimumIdle(), pds.getMaximumPoolSize());

        final PoolDataSourceConfigurationHikari pdsConfigBefore =
            (PoolDataSourceConfigurationHikari) pds.get();

        // create all connections possible in the normal pool data source
        for (int j = 0; j < pds.getMinimumIdle(); j++) {
            assertNotNull(pds.getConnection());
        }

        assertEquals(pds.getMinimumIdle(), pds.getActiveConnections());
        assertEquals(0, pds.getIdleConnections());
        assertEquals(pds.getActiveConnections() +
                     pds.getIdleConnections(),
                     pds.getTotalConnections());

        final PoolDataSourceConfigurationHikari pdsConfigAfter =
            (PoolDataSourceConfigurationHikari) pds.get();

        assertEquals(pdsConfigBefore, pdsConfigAfter);

        // moving to overflow now: get all connections but one
        for (int j = pds.getMinimumIdle(); j < pds.getMaximumPoolSize() - 1; j++) {
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
