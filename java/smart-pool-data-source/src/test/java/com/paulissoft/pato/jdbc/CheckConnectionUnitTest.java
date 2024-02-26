package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
//import static org.junit.jupiter.api.Assertions.assertNotEquals;
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
@EnableConfigurationProperties({PoolDataSourceConfiguration.class, PoolDataSourceConfiguration.class, PoolDataSourceConfigurationHikari.class})
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
        poolAppConfigDataSourceConfigurationHikari.copy(poolAppConfigDataSourceConfiguration);
        poolAppConfigDataSourceConfigurationOracle.copy(poolAppConfigDataSourceConfiguration);

        // ocpi
        poolAppOcpiDataSourceConfigurationHikari.copy(poolAppOcpiDataSourceConfiguration);
        poolAppOcpiDataSourceConfigurationOracle.copy(poolAppOcpiDataSourceConfiguration);

        // domain
        poolAppDomainDataSourceConfigurationHikari.copy(poolAppDomainDataSourceConfiguration);
        poolAppDomainDataSourceConfigurationOracle.copy(poolAppDomainDataSourceConfiguration);

        for (int i = 0; i < 2; i++) {
            // these two will be combined
            final SmartPoolDataSource pds1 = SmartPoolDataSource.build(poolAppConfigDataSourceConfigurationHikari);
            final SmartPoolDataSource pds2 = SmartPoolDataSource.build(poolAppOcpiDataSourceConfigurationHikari);
            final SmartPoolDataSource pds3 = SmartPoolDataSource.build(poolAppDomainDataSourceConfigurationHikari);

            // do not use assertEquals(pds1.getCommonPoolDataSource(), pds2.getCommonPoolDataSource()) since equals() is overridden
            assertTrue(pds1.getCommonPoolDataSource() == pds2.getCommonPoolDataSource());
            assertFalse(pds1.getCommonPoolDataSource() == pds3.getCommonPoolDataSource());

            assertEquals(poolAppConfigDataSourceConfigurationHikari.getMinimumIdle() +
                         poolAppOcpiDataSourceConfigurationHikari.getMinimumIdle(),
                         pds1.getMinPoolSize());

            assertEquals(poolAppConfigDataSourceConfigurationHikari.getMaximumPoolSize() +
                         poolAppOcpiDataSourceConfigurationHikari.getMaximumPoolSize(),
                         pds1.getMaxPoolSize());

            assertEquals(poolAppDomainDataSourceConfigurationHikari.getMinimumIdle(),
                         pds3.getMinPoolSize());

            assertEquals(poolAppDomainDataSourceConfigurationHikari.getMaximumPoolSize(),
                         pds3.getMaxPoolSize());

            assertEquals(pds1.getPoolName(), "HikariPool-bocsconf-boocpi");
            assertEquals(pds1.getPoolName(), pds2.getPoolName());
            assertEquals(pds3.getPoolName(), "HikariPool-bodomain");

            // these two will be combined too
            final SmartPoolDataSource pds4 = SmartPoolDataSource.build(poolAppConfigDataSourceConfigurationOracle);
            final SmartPoolDataSource pds5 = SmartPoolDataSource.build(poolAppOcpiDataSourceConfigurationOracle);
            final SmartPoolDataSource pds6 = SmartPoolDataSource.build(poolAppDomainDataSourceConfigurationOracle);

            assertTrue(pds4.getCommonPoolDataSource() == pds5.getCommonPoolDataSource());
            assertTrue(pds4.getCommonPoolDataSource() == pds6.getCommonPoolDataSource());

            // Hikari != Oracle
            assertFalse(pds1.getCommonPoolDataSource() == pds4.getCommonPoolDataSource());
            assertFalse(pds3.getCommonPoolDataSource() == pds6.getCommonPoolDataSource());

            assertEquals(pds4.getInitialPoolSize(),
                         poolAppConfigDataSourceConfigurationOracle.getInitialPoolSize() +
                         poolAppOcpiDataSourceConfigurationOracle.getInitialPoolSize() +
                         poolAppDomainDataSourceConfigurationOracle.getInitialPoolSize());

            assertEquals(pds4.getMinPoolSize(),
                         poolAppConfigDataSourceConfigurationOracle.getMinPoolSize() +
                         poolAppOcpiDataSourceConfigurationOracle.getMinPoolSize() +
                         poolAppDomainDataSourceConfigurationOracle.getMinPoolSize());

            assertEquals(pds4.getMaxPoolSize(),
                         poolAppConfigDataSourceConfigurationOracle.getMaxPoolSize() +
                         poolAppOcpiDataSourceConfigurationOracle.getMaxPoolSize() +
                         poolAppDomainDataSourceConfigurationOracle.getMaxPoolSize());

            assertEquals(pds4.getPoolName(), "OraclePool-bocsconf-boocpi-bodomain");
            assertEquals(pds4.getPoolName(), pds5.getPoolName());
            assertEquals(pds4.getPoolName(), pds6.getPoolName());
            
            // get some connections
            for (int j = 0; j < 2; j++) {
                assertNotNull(conn1 = pds1.getConnection());
                assertNotNull(conn2 = pds2.getConnection());
                assertNotNull(conn3 = pds3.getConnection());
                assertNotNull(conn4 = pds4.getConnection());
                assertNotNull(conn5 = pds5.getConnection());
                assertNotNull(conn6 = pds6.getConnection());

                assertEquals(2, pds1.getActiveConnections());
                assertEquals(pds1.getTotalConnections(), pds1.getActiveConnections() + pds1.getIdleConnections());

                assertEquals(1, pds3.getActiveConnections());
                assertEquals(pds3.getTotalConnections(), pds3.getActiveConnections() + pds3.getIdleConnections());

                assertEquals(conn1.unwrap(OracleConnection.class).getClass(), conn2.unwrap(Connection.class).getClass());
                assertEquals(conn1.unwrap(OracleConnection.class).getClass(), conn3.unwrap(Connection.class).getClass());

                assertEquals(3, pds4.getActiveConnections());
                assertEquals(pds4.getTotalConnections(), pds4.getActiveConnections() + pds4.getIdleConnections());

                assertEquals(conn4.unwrap(OracleConnection.class).getClass(), conn5.unwrap(Connection.class).getClass());
                assertEquals(conn4.unwrap(OracleConnection.class).getClass(), conn6.unwrap(Connection.class).getClass());

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
}
