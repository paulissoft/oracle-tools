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
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;

@Slf4j
@ExtendWith(SpringExtension.class)
@EnableConfigurationProperties({PoolDataSourceConfiguration.class,
            PoolDataSourceConfiguration.class,
            PoolDataSourceConfigurationHikari.class,
            DataSourceProperties.class,
            MyDomainDataSourceHikari.class,
            MyOperatorDataSourceHikari.class})
@ContextConfiguration(classes = ConfigurationFactoryHikari.class)
@TestPropertySource("classpath:application-test.properties")
public class CheckConnectionUnitTestHikari {

    @Autowired
    @Qualifier("app-config-datasource")
    private PoolDataSourceConfiguration poolAppConfigDataSourceConfiguration;

    @Autowired
    @Qualifier("app-ocpi-datasource")
    private PoolDataSourceConfiguration poolAppOcpiDataSourceConfiguration;

    @Autowired
    @Qualifier("app-domain-datasource")
    private PoolDataSourceConfiguration poolAppDomainDataSourceConfiguration;

    @Autowired
    @Qualifier("app-config-datasource-hikari")
    private PoolDataSourceConfigurationHikari poolAppConfigDataSourceConfigurationHikari;

    @Autowired
    @Qualifier("app-ocpi-datasource-hikari")
    private PoolDataSourceConfigurationHikari poolAppOcpiDataSourceConfigurationHikari;

    @Autowired
    @Qualifier("app-domain-datasource-hikari")
    private PoolDataSourceConfigurationHikari poolAppDomainDataSourceConfigurationHikari;

    @Autowired
    @Qualifier("operatorDataSourceProperties")
    private DataSourceProperties dataSourceProperties;

    @Autowired
    private MyDomainDataSourceHikari domainDataSourceHikari;
    
    @Autowired
    private MyOperatorDataSourceHikari operatorDataSourceHikari;
    
    @BeforeAll
    static void clear() {
        SmartPoolDataSource.clear();
        CombiPoolDataSource.clear();
    }

    //=== Hikari ===

    @Test
    void testConnection() throws SQLException {
        final String rex = "^Smart pool data source \\(.+\\) must be open.$";
        IllegalStateException thrown;
        Connection conn1, conn2, conn3;
        
        log.debug("testConnection()");

        // config
        poolAppConfigDataSourceConfigurationHikari.copyFrom(poolAppConfigDataSourceConfiguration);

        // ocpi
        poolAppOcpiDataSourceConfigurationHikari.copyFrom(poolAppOcpiDataSourceConfiguration);

        // domain
        poolAppDomainDataSourceConfigurationHikari.copyFrom(poolAppDomainDataSourceConfiguration);

        for (int i = 0; i < 2; i++) {
            // these two will be combined
            final SmartPoolDataSource pds1 = SmartPoolDataSource.build(poolAppConfigDataSourceConfigurationHikari);

            log.debug("pds1.getCommonPoolDataSource() (#1): {}", pds1.getCommonPoolDataSource());

            if (i >= 2) { conn1 = pds1.getConnection(); if (i == 3) { conn1.close(); } }

            log.debug("pds1.getCommonPoolDataSource() (#2): {}", pds1.getCommonPoolDataSource());
            
            final SmartPoolDataSource pds2 = SmartPoolDataSource.build(poolAppOcpiDataSourceConfigurationHikari);

            log.debug("pds1.getCommonPoolDataSource() (#3): {}", pds1.getCommonPoolDataSource());

            if (i >= 2) { conn2 = pds2.getConnection(); if (i == 3) { conn2.close(); } }

            log.debug("pds1.getCommonPoolDataSource() (#4): {}", pds1.getCommonPoolDataSource());

            final SmartPoolDataSource pds3 = SmartPoolDataSource.build(poolAppDomainDataSourceConfigurationHikari);

            log.debug("pds1.getCommonPoolDataSource() (#5): {}", pds1.getCommonPoolDataSource());

            if (i >= 2) { conn3 = pds3.getConnection(); if (i == 3) { conn3.close(); } }

            log.debug("pds1.getCommonPoolDataSource() (#6): {}", pds1.getCommonPoolDataSource());

            log.debug("pds1.getCommonPoolDataSource(): {}", pds1.getCommonPoolDataSource());
            log.debug("pds2.getCommonPoolDataSource(): {}", pds2.getCommonPoolDataSource());
            log.debug("pds3.getCommonPoolDataSource(): {}", pds3.getCommonPoolDataSource());
            
            // do not use assertEquals(pds1.getCommonPoolDataSource(), pds2.getCommonPoolDataSource()) since equals() is overridden

            // pds3 is always different
            assertFalse(pds1.getCommonPoolDataSource() == pds3.getCommonPoolDataSource());
            
            assertEquals(poolAppDomainDataSourceConfigurationHikari.getMinimumIdle(),
                         pds3.getCommonPoolDataSource().getMinPoolSize());

            assertEquals(poolAppDomainDataSourceConfigurationHikari.getMaximumPoolSize(),
                         pds3.getCommonPoolDataSource().getMaxPoolSize());

            assertEquals("HikariPool-bodomain", pds3.getCommonPoolDataSource().getPoolName());
            
            switch(i) {
            case 0:
            case 1:
                assertTrue(pds1.getCommonPoolDataSource() == pds2.getCommonPoolDataSource());
            
                assertEquals(poolAppConfigDataSourceConfigurationHikari.getMinimumIdle() +
                             poolAppOcpiDataSourceConfigurationHikari.getMinimumIdle(),
                             pds1.getCommonPoolDataSource().getMinPoolSize());

                assertEquals(poolAppConfigDataSourceConfigurationHikari.getMaximumPoolSize() +
                             poolAppOcpiDataSourceConfigurationHikari.getMaximumPoolSize(),
                             pds2.getCommonPoolDataSource().getMaxPoolSize());

                assertEquals("HikariPool-bocsconf-boocpi",
                             pds1.getCommonPoolDataSource().getPoolName());
                assertEquals(pds1.getCommonPoolDataSource().getPoolName(),
                             pds2.getCommonPoolDataSource().getPoolName());
                break;

            case 2:
            case 3:
                // pool sizes are incorporated into common pool data source
                assertFalse(pds1.getCommonPoolDataSource() == pds2.getCommonPoolDataSource());

                assertEquals(poolAppConfigDataSourceConfigurationHikari.getMinimumIdle(),
                             pds1.getCommonPoolDataSource().getMinPoolSize());
                assertEquals(poolAppOcpiDataSourceConfigurationHikari.getMinimumIdle(),
                             pds2.getCommonPoolDataSource().getMinPoolSize());

                assertEquals(poolAppConfigDataSourceConfigurationHikari.getMaximumPoolSize(),
                             pds1.getCommonPoolDataSource().getMaxPoolSize());
                assertEquals(poolAppOcpiDataSourceConfigurationHikari.getMaximumPoolSize(),
                             pds2.getCommonPoolDataSource().getMaxPoolSize());

                assertEquals("HikariPool-bocsconf",
                             pds1.getCommonPoolDataSource().getPoolName());
                assertEquals("HikariPool-boocpi",
                             pds2.getCommonPoolDataSource().getPoolName());
                break;
            }

            // get some connections
            for (int j = 0; j < 2; j++) {
                assertNotNull(conn1 = pds1.getConnection());
                assertNotNull(conn2 = pds2.getConnection());
                assertNotNull(conn3 = pds3.getConnection());

                assertEquals(2, pds1.getCommonPoolDataSource().getActiveConnections());
                assertEquals(pds1.getCommonPoolDataSource().getActiveConnections() +
                             pds1.getCommonPoolDataSource().getIdleConnections(),
                             pds1.getCommonPoolDataSource().getTotalConnections());

                assertEquals(1, pds3.getCommonPoolDataSource().getActiveConnections());
                assertEquals(pds3.getCommonPoolDataSource().getActiveConnections() +
                             pds3.getCommonPoolDataSource().getIdleConnections(),
                             pds3.getCommonPoolDataSource().getTotalConnections());                             

                assertEquals(conn1.unwrap(OracleConnection.class).getClass(),
                             conn2.unwrap(Connection.class).getClass());
                assertEquals(conn1.unwrap(OracleConnection.class).getClass(),
                             conn3.unwrap(Connection.class).getClass());

                conn1.close();
                conn2.close();
                conn3.close();
            }

            // close pds3
            assertFalse(pds3.isClosed());
            pds3.close();
            assertTrue(pds3.isClosed());
            assertTrue(pds3.getCommonPoolDataSource().isClosed()); // one user: bodomain

            thrown = assertThrows(IllegalStateException.class, () -> pds3.getConnection());
            assertTrue(thrown.getMessage().matches(rex));

            // close pds2
            assertFalse(pds2.isClosed());
            pds2.close();
            assertTrue(pds2.isClosed());
            assertFalse(pds2.getCommonPoolDataSource().isClosed()); // must close pds1 too

            thrown = assertThrows(IllegalStateException.class, () -> pds2.getConnection());
            assertTrue(thrown.getMessage().matches(rex));

            // close pds1
            assertFalse(pds1.isClosed());
            pds1.close();
            assertTrue(pds1.isClosed());
            assertTrue(pds1.getCommonPoolDataSource().isClosed()); // done

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
                assertEquals("bc_proxy", ds.getPassword());
                assertEquals(60, ds.getMinimumIdle());
                assertEquals(2 * 60, ds.getCommonPoolDataSource().getMinimumIdle());
                assertEquals(60, ds.getMaximumPoolSize());
                assertEquals(2 * 60, ds.getCommonPoolDataSource().getMaximumPoolSize());
                assertEquals(ds == domainDataSourceHikari ? "HikariPool-bodomain" : "HikariPool-boopapij", ds.getPoolName());
                assertEquals("HikariPool-bodomain-boopapij", ds.getCommonPoolDataSource().getPoolName());

                final Connection conn = ds.getConnection();

                assertNotNull(conn);
                assertEquals(ds == domainDataSourceHikari ? "BODOMAIN" : "BOOPAPIJ", conn.getSchema());

                conn.close();
            }
        }
    }
}
