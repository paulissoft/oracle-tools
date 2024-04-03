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
public class CheckConnectionHikariUnitTest {

    /*
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
    */
        
    @Autowired
    @Qualifier("configDataSourceProperties")
    private DataSourceProperties configDataSourceProperties;
        
    @Autowired
    @Qualifier("ocpiDataSourceProperties")
    private DataSourceProperties ocpiDataSourceProperties;
        
    @Autowired
    @Qualifier("domainDataSourceProperties")
    private DataSourceProperties domainDataSourceProperties;
        
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
        // poolAppConfigDataSourceConfigurationHikari.copyFrom(poolAppConfigDataSourceConfiguration);

        // ocpi
        // poolAppOcpiDataSourceConfigurationHikari.copyFrom(poolAppOcpiDataSourceConfiguration);

        for (int i = 0; i < 4; i++) {
            log.debug("round #{}", i);
            
            // these two will be combined
            final SmartPoolDataSourceHikari pds1 =
                configDataSourceProperties
                .initializeDataSourceBuilder()
                .type(SmartPoolDataSourceHikari.class)
                .build();

            log.debug("pds1.getPoolDataSource() (#1): {}", pds1.getPoolDataSource());

            assertFalse(pds1.isOpen());

            // first getConnection() will open the pool data source
            if (i >= 2) { conn1 = pds1.getConnection(); if (i == 3) { conn1.close(); } assertTrue(pds1.isOpen()); }

            log.debug("pds1.getPoolDataSource() (#2): {}", pds1.getPoolDataSource());
            
            final SmartPoolDataSourceHikari pds2 =
                ocpiDataSourceProperties
                .initializeDataSourceBuilder()
                .type(SmartPoolDataSourceHikari.class)
                .build();

            log.debug("pds1.getPoolDataSource() (#3): {}", pds1.getPoolDataSource());

            assertFalse(pds2.isOpen());

            // first getConnection() will open the pool data source
            if (i >= 2) { conn2 = pds2.getConnection(); if (i == 3) { conn2.close(); } assertTrue(pds2.isOpen()); }

            log.debug("pds1.getPoolDataSource() (#4): {}", pds1.getPoolDataSource());

            final SmartPoolDataSourceHikari pds3 =
                domainDataSourceProperties
                .initializeDataSourceBuilder()
                .type(SmartPoolDataSourceHikari.class)
                .build();

            log.debug("pds1.getPoolDataSource() (#5): {}", pds1.getPoolDataSource());

            assertFalse(pds3.isOpen());

            // first getConnection() will open the pool data source
            if (i >= 2) { conn3 = pds3.getConnection(); if (i == 3) { conn3.close(); } assertTrue(pds3.isOpen()); }

            log.debug("pds1.getPoolDataSource() (#6): {}", pds1.getPoolDataSource());

            switch(i) {
            case 0:
            case 1:
                log.debug("pds1.getPoolDataSource(): {}", pds1.getPoolDataSource().toString());
                log.debug("pds2.getPoolDataSource(): {}", pds2.getPoolDataSource().toString());
                
                assertTrue(pds1.getPoolDataSource() == pds2.getPoolDataSource());            
                assertEquals("HikariPool-bocsconf-boocpi",
                             pds1.getPoolDataSource().getPoolName());
                assertEquals(pds1.getPoolDataSource().getPoolName(),
                             pds2.getPoolDataSource().getPoolName());
                break;

            case 2:
            case 3:
                log.debug("pds1.getPoolDataSource(): {}", pds1.getPoolDataSource().toString());
                log.debug("pds2.getPoolDataSource(): {}", pds2.getPoolDataSource().toString());
                
                // pool sizes are incorporated into common pool data source
                assertTrue(pds1.getPoolDataSource() == pds2.getPoolDataSource());
                assertEquals("HikariPool-bocsconf",
                             pds1.getPoolDataSource().getPoolName());
                assertEquals("HikariPool-boocpi",
                             pds2.getPoolDataSource().getPoolName());
                break;
            }

            // get some connections
            for (int j = 0; j < 2; j++) {
                assertNotNull(conn1 = pds1.getConnection());
                assertNotNull(conn2 = pds2.getConnection());

                log.debug("round #{}; pds3.isOpen(): {}", i, pds3.isOpen());

                assertNotNull(conn3 = pds3.getConnection(), "Can not get a connection for round " + i);
                assertTrue(pds3.isOpen());

                assertEquals(2, pds1.getActiveConnections());
                assertEquals(pds1.getActiveConnections() +
                             pds1.getIdleConnections(),
                             pds1.getTotalConnections());

                assertTrue(pds3.isOpen());
                assertEquals(1, pds3.getActiveConnections());
                assertEquals(pds3.getActiveConnections() +
                             pds3.getIdleConnections(),
                             pds3.getTotalConnections());
                assertTrue(pds3.isOpen());

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
