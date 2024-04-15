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
import oracle.jdbc.OracleConnection;
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
@EnableConfigurationProperties({MyDomainDataSourceHikari.class, MyOperatorDataSourceHikari.class})
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryHikari.class})
@TestPropertySource("classpath:application-test.properties")
public class CheckConnectionHikariUnitTest {

    @Autowired
    @Qualifier("configDataSource")
    private CombiPoolDataSourceHikari configDataSourceHikari;

    @Autowired
    @Qualifier("ocpiDataSource")
    private CombiPoolDataSourceHikari ocpiDataSourceHikari;

    @Autowired
    @Qualifier("ocppDataSource")
    private CombiPoolDataSourceHikari ocppDataSourceHikari;

    @Autowired
    private MyDomainDataSourceHikari domainDataSourceHikari;
    
    @Autowired
    private MyOperatorDataSourceHikari operatorDataSourceHikari;
    
    @BeforeAll
    static void clear() {
        PoolDataSourceStatistics.clear();
        CombiPoolDataSource.clear();
    }

    //=== Hikari ===

    @Test
    void testConnection() throws SQLException {
        final String rex = "^Smart pool data source \\(.+\\) must be open.$";
        IllegalStateException thrown;
        Connection conn1, conn2, conn3;
        
        log.debug("testConnection()");

        for (int i = 0; i < 4; i++) {
            log.debug("round #{}", i);
            
            // these two will be combined
            final CombiPoolDataSourceHikari pds1 = configDataSourceHikari;

            if (i >= 2) { conn1 = pds1.getConnection(); if (i == 3) { conn1.close(); } }

            final CombiPoolDataSourceHikari pds2 = ocpiDataSourceHikari;

            if (i >= 2) { conn2 = pds2.getConnection(); if (i == 3) { conn2.close(); } }

            final CombiPoolDataSourceHikari pds3 = ocppDataSourceHikari;

            if (i >= 2) { conn3 = pds3.getConnection(); if (i == 3) { conn3.close(); } }

            // first getConnection() (i >= 2) will open the pool data source
            switch(i) {
            case 0:
                // the first to create will become the parent
                assertTrue(pds1.isParentPoolDataSource());
                assertFalse(pds2.isParentPoolDataSource());
                assertFalse(pds3.isParentPoolDataSource());

                // all share the same common pool data source
                assertTrue(pds1.getPoolDataSource() == pds2.getPoolDataSource());
                assertTrue(pds1.getPoolDataSource() == pds3.getPoolDataSource());
                
                // fall thru
            case 1:
                assertFalse(pds1.isOpen());
                assertFalse(pds2.isOpen());
                assertFalse(pds3.isOpen());
                break;

            case 2:
            case 3:
                log.debug("pds1.getPoolDataSourceConfiguration(): {}", pds1.getPoolDataSourceConfiguration());
                log.debug("pds2.getPoolDataSourceConfiguration(): {}", pds2.getPoolDataSourceConfiguration());
                log.debug("pds3.getPoolDataSourceConfiguration(): {}", pds3.getPoolDataSourceConfiguration());

                assertTrue(pds1.isOpen());
                assertTrue(pds2.isOpen());
                assertTrue(pds3.isOpen());
                break;
            }

            // get some connections
            for (int j = 0; j < 2; j++) {
                assertNotNull(conn1 = pds1.getConnection());
                assertNotNull(conn2 = pds2.getConnection());
                assertNotNull(conn3 = pds3.getConnection());

                assertEquals(1, pds1.getActiveConnections());
                assertEquals(pds1.getActiveConnections() +
                             pds1.getIdleConnections(),
                             pds1.getTotalConnections());

                assertEquals(1, pds2.getActiveConnections());
                assertEquals(pds2.getActiveConnections() +
                             pds2.getIdleConnections(),
                             pds2.getTotalConnections());

                assertEquals(1, pds3.getActiveConnections());
                assertEquals(pds3.getActiveConnections() +
                             pds3.getIdleConnections(),
                             pds3.getTotalConnections());

                assertEquals(conn1.unwrap(OracleConnection.class).getClass(),
                             conn2.unwrap(Connection.class).getClass());
                assertEquals(conn1.unwrap(OracleConnection.class).getClass(),
                             conn3.unwrap(Connection.class).getClass());

                conn1.close();
                conn2.close();
                conn3.close();
            }

            // close pds3
            assertTrue(pds3.isOpen());
            pds3.close();
            assertFalse(pds3.isOpen());

            thrown = assertThrows(IllegalStateException.class, () -> pds3.getConnection());
            assertTrue(thrown.getMessage().matches(rex));

            // close pds2
            assertTrue(pds2.isOpen());
            pds2.close();
            assertFalse(pds2.isOpen());

            thrown = assertThrows(IllegalStateException.class, () -> pds2.getConnection());
            assertTrue(thrown.getMessage().matches(rex));

            // close pds1
            assertTrue(pds1.isOpen());
            pds1.close();
            assertFalse(pds1.isOpen());

            thrown = assertThrows(IllegalStateException.class, () -> pds1.getConnection());
            assertTrue(thrown.getMessage().matches(rex));
        }
    }

    @Test
    void testConnectionHikari() throws SQLException {
        log.debug("testConnectionHikari()");

        assertNotEquals(domainDataSourceHikari, operatorDataSourceHikari);

        assertNotEquals(domainDataSourceHikari.isParentPoolDataSource(), operatorDataSourceHikari.isParentPoolDataSource());

        final CombiPoolDataSourceHikari parent = domainDataSourceHikari.isParentPoolDataSource() ? domainDataSourceHikari : operatorDataSourceHikari;

        final CombiPoolDataSourceHikari child = !domainDataSourceHikari.isParentPoolDataSource() ? domainDataSourceHikari : operatorDataSourceHikari;

        for (int nr = 1; nr <= 2; nr++) {
            try (final CombiPoolDataSourceHikari ds = (nr == 1 ? parent : child)) {                
                log.debug("round #{}; ds.getPoolDataSourceConfiguration(): {}", nr, ds.getPoolDataSourceConfiguration());
                
                assertEquals(CombiPoolDataSource.State.OPEN, ds.getState());
                
                assertEquals("jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1", ds.getUrl());
                
                assertEquals(ds == domainDataSourceHikari ? "bc_proxy[bodomain]" : "bc_proxy[boopapij]", ds.getUsername());
                assertEquals(parent.getUsername(), ds.getPoolDataSource().getUsername());
                
                assertEquals("bc_proxy", ds.getPassword());
                assertEquals(parent.getPassword(), ds.getPoolDataSource().getPassword());

                assertEquals(60, ds.getMinimumIdle());
                assertEquals(parent.getMinimumIdle() + child.getMinimumIdle(), ds.getPoolDataSource().getMinimumIdle());

                assertEquals(60, ds.getMaximumPoolSize());
                assertEquals(parent.getMaximumPoolSize() + child.getMaximumPoolSize(), ds.getPoolDataSource().getMaximumPoolSize());

                assertEquals(ds == domainDataSourceHikari ? "HikariPool-bodomain" : "HikariPool-bodomain-boopapij", ds.getPoolName());
                assertEquals("HikariPool-bodomain-boopapij", ds.getPoolDataSource().getPoolName());

                final Connection conn = ds.getConnection();

                assertNotNull(conn);
                assertEquals(ds == domainDataSourceHikari ? "BODOMAIN" : "BOOPAPIJ", conn.getSchema());

                conn.close();
            }
        }
    }
}
