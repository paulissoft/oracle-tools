package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
//import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import javax.sql.DataSource;
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
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;


@Slf4j
@ExtendWith(SpringExtension.class)
@EnableConfigurationProperties({PoolDataSourceConfiguration.class,
            PoolDataSourceConfiguration.class,
            PoolDataSourceConfigurationHikari.class,
            DataSourceProperties.class})
@ContextConfiguration(classes = ConfigurationFactory.class)
@TestPropertySource("classpath:application-test.properties")
public class CheckConnectionUnitTest {

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
    @Qualifier("app-config-datasource-oracle")
    private PoolDataSourceConfigurationOracle poolAppConfigDataSourceConfigurationOracle;

    @Autowired
    @Qualifier("app-ocpi-datasource-oracle")
    private PoolDataSourceConfigurationOracle poolAppOcpiDataSourceConfigurationOracle;

    @Autowired
    @Qualifier("app-domain-datasource-oracle")
    private PoolDataSourceConfigurationOracle poolAppDomainDataSourceConfigurationOracle;

    @Autowired
    @Qualifier("operatorDataSourceProperties")
    private DataSourceProperties dataSourceProperties;

    @Autowired
    @Qualifier("operatorDataSource")
    private DataSource dataSource;
    
    @BeforeAll
    static void clear() {
        SmartPoolDataSource.clear();
    }

    //=== Hikari ===

    @Test
    void testConnection() throws SQLException {
        final String rex = "^Smart pool data source \\(.+\\) must be open.$";
        IllegalStateException thrown;
        Connection conn1, conn2, conn3, conn4, conn5, conn6;
        
        log.debug("testConnection()");

        // config
        poolAppConfigDataSourceConfigurationHikari.copyFrom(poolAppConfigDataSourceConfiguration);
        poolAppConfigDataSourceConfigurationOracle.copyFrom(poolAppConfigDataSourceConfiguration);

        // ocpi
        poolAppOcpiDataSourceConfigurationHikari.copyFrom(poolAppOcpiDataSourceConfiguration);
        poolAppOcpiDataSourceConfigurationOracle.copyFrom(poolAppOcpiDataSourceConfiguration);

        // domain
        poolAppDomainDataSourceConfigurationHikari.copyFrom(poolAppDomainDataSourceConfiguration);
        poolAppDomainDataSourceConfigurationOracle.copyFrom(poolAppDomainDataSourceConfiguration);

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

            // these two will be combined too
            final SmartPoolDataSource pds4 = SmartPoolDataSource.build(poolAppConfigDataSourceConfigurationOracle);

            if (i >= 2) { conn4 = pds4.getConnection(); if (i == 3) { conn4.close(); } }
            
            final SmartPoolDataSource pds5 = SmartPoolDataSource.build(poolAppOcpiDataSourceConfigurationOracle);

            if (i >= 2) { conn5 = pds5.getConnection(); if (i == 3) { conn5.close(); } }
            
            final SmartPoolDataSource pds6 = SmartPoolDataSource.build(poolAppDomainDataSourceConfigurationOracle);

            if (i >= 2) { conn6 = pds6.getConnection(); if (i == 3) { conn6.close(); } }            

            log.debug("pds4.getCommonPoolDataSource(): {}", pds4.getCommonPoolDataSource());
            log.debug("pds5.getCommonPoolDataSource(): {}", pds5.getCommonPoolDataSource());
            log.debug("pds6.getCommonPoolDataSource(): {}", pds6.getCommonPoolDataSource());

            assertTrue(pds4.getCommonPoolDataSource() == pds5.getCommonPoolDataSource());
            assertTrue(pds4.getCommonPoolDataSource() == pds6.getCommonPoolDataSource());

            // Hikari != Oracle
            assertFalse(pds1.getCommonPoolDataSource() == pds4.getCommonPoolDataSource());
            assertFalse(pds3.getCommonPoolDataSource() == pds6.getCommonPoolDataSource());

            switch(i) {
            case 0:
            case 1:
                assertEquals(poolAppConfigDataSourceConfigurationOracle.getInitialPoolSize() +
                             poolAppOcpiDataSourceConfigurationOracle.getInitialPoolSize() +
                             poolAppDomainDataSourceConfigurationOracle.getInitialPoolSize(),
                             pds4.getCommonPoolDataSource().getInitialPoolSize());

                assertEquals(poolAppConfigDataSourceConfigurationOracle.getMinPoolSize() +
                             poolAppOcpiDataSourceConfigurationOracle.getMinPoolSize() +
                             poolAppDomainDataSourceConfigurationOracle.getMinPoolSize(),
                             pds4.getCommonPoolDataSource().getMinPoolSize());

                assertEquals(poolAppConfigDataSourceConfigurationOracle.getMaxPoolSize() +
                             poolAppOcpiDataSourceConfigurationOracle.getMaxPoolSize() +
                             poolAppDomainDataSourceConfigurationOracle.getMaxPoolSize(),
                             pds4.getCommonPoolDataSource().getMaxPoolSize());

                assertEquals("OraclePool-bocsconf-boocpi-bodomain",
                             pds4.getCommonPoolDataSource().getPoolName());
                assertEquals(pds4.getCommonPoolDataSource().getPoolName(),
                             pds5.getCommonPoolDataSource().getPoolName());
                assertEquals(pds4.getCommonPoolDataSource().getPoolName(),
                             pds6.getCommonPoolDataSource().getPoolName());
                break;
                
            case 2:
            case 3:
                assertEquals(poolAppConfigDataSourceConfigurationOracle.getInitialPoolSize(),
                             pds4.getCommonPoolDataSource().getInitialPoolSize());
                assertEquals(poolAppOcpiDataSourceConfigurationOracle.getInitialPoolSize(),
                             pds5.getCommonPoolDataSource().getInitialPoolSize());
                assertEquals(poolAppDomainDataSourceConfigurationOracle.getInitialPoolSize(),
                             pds6.getCommonPoolDataSource().getInitialPoolSize());

                assertEquals(poolAppConfigDataSourceConfigurationOracle.getMinPoolSize(),
                             pds4.getCommonPoolDataSource().getMinPoolSize());
                assertEquals(poolAppOcpiDataSourceConfigurationOracle.getMinPoolSize(),
                             pds5.getCommonPoolDataSource().getMinPoolSize());
                assertEquals(poolAppDomainDataSourceConfigurationOracle.getMinPoolSize(),
                             pds6.getCommonPoolDataSource().getMinPoolSize());

                assertEquals(poolAppConfigDataSourceConfigurationOracle.getMaxPoolSize(),
                             pds4.getCommonPoolDataSource().getMaxPoolSize());
                assertEquals(poolAppOcpiDataSourceConfigurationOracle.getMaxPoolSize(),
                             pds5.getCommonPoolDataSource().getMaxPoolSize());
                assertEquals(poolAppDomainDataSourceConfigurationOracle.getMaxPoolSize(),
                             pds6.getCommonPoolDataSource().getMaxPoolSize());

                assertEquals("OraclePool-bocsconf",
                             pds4.getCommonPoolDataSource().getPoolName());
                assertEquals("OraclePool-boocpi",
                             pds5.getCommonPoolDataSource().getPoolName());
                assertEquals("OraclePool-bodomain",
                             pds6.getCommonPoolDataSource().getPoolName());
                break;
            }
            
            // get some connections
            for (int j = 0; j < 2; j++) {
                assertNotNull(conn1 = pds1.getConnection());
                assertNotNull(conn2 = pds2.getConnection());
                assertNotNull(conn3 = pds3.getConnection());
                assertNotNull(conn4 = pds4.getConnection());
                assertNotNull(conn5 = pds5.getConnection());
                assertNotNull(conn6 = pds6.getConnection());

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

                assertEquals(3, pds4.getCommonPoolDataSource().getActiveConnections());
                assertEquals(pds4.getCommonPoolDataSource().getActiveConnections() +
                             pds4.getCommonPoolDataSource().getIdleConnections(),
                             pds4.getCommonPoolDataSource().getTotalConnections());                             

                assertEquals(conn4.unwrap(OracleConnection.class).getClass(),
                             conn5.unwrap(Connection.class).getClass());
                assertEquals(conn4.unwrap(OracleConnection.class).getClass(),
                             conn6.unwrap(Connection.class).getClass());

                conn1.close();
                conn2.close();
                conn3.close();
                conn4.close();
                conn5.close();
                conn6.close();
            }

            // close pds6
            assertFalse(pds6.isClosed());
            pds6.close();
            assertTrue(pds6.isClosed());
            assertFalse(pds6.getCommonPoolDataSource().isClosed()); // must close pds4/pds5 too

            thrown = assertThrows(IllegalStateException.class, () -> pds6.getConnection());
            assertTrue(thrown.getMessage().matches(rex));

            // close pds5
            assertFalse(pds5.isClosed());
            pds5.close();
            assertTrue(pds5.isClosed());
            assertFalse(pds5.getCommonPoolDataSource().isClosed()); // must close pds4 too

            thrown = assertThrows(IllegalStateException.class, () -> pds5.getConnection());
            assertTrue(thrown.getMessage().matches(rex));

            // close pds4
            assertFalse(pds4.isClosed());
            pds4.close();
            assertTrue(pds4.isClosed());
            assertTrue(pds4.getCommonPoolDataSource().isClosed()); // done

            thrown = assertThrows(IllegalStateException.class, () -> pds4.getConnection());
            assertTrue(thrown.getMessage().matches(rex));

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
    void testConnectionMyHikariDataSource() throws SQLException {
        log.debug("testConnectionMyHikariDataSource()");

        final MyHikariDataSource ds = (MyHikariDataSource) dataSource;

        assertEquals("jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1", ds.getJdbcUrl());
        assertEquals("bc_proxy[boopapij]", ds.getUsername());
        assertEquals("bc_proxy", ds.getPassword());
        assertEquals(60, ds.getMinimumIdle());
        assertEquals(60, ds.getMaximumPoolSize());
        assertEquals("HikariPool-boopapij", ds.getPoolName());
    }
}
