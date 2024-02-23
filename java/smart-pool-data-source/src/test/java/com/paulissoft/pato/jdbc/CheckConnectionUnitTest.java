package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
//import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.sql.SQLException;
import java.sql.Connection;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import lombok.extern.slf4j.Slf4j;

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
    @Qualifier("app-config-datasource-hikari")
    private PoolDataSourceConfigurationHikari poolAppConfigDataSourceConfigurationHikari;

    @Autowired
    @Qualifier("app-ocpi-datasource-hikari")
    private PoolDataSourceConfigurationHikari poolAppOcpiDataSourceConfigurationHikari;

    @Autowired
    @Qualifier("app-config-datasource-oracle")
    private PoolDataSourceConfigurationOracle poolAppConfigDataSourceConfigurationOracle;

    @Autowired
    @Qualifier("app-ocpi-datasource-oracle")
    private PoolDataSourceConfigurationOracle poolAppOcpiDataSourceConfigurationOracle;

    @BeforeAll
    static void clear() {
        SmartPoolDataSource.clear();
    }

    //=== Hikari ===

    @Test
    void testConnection() throws SQLException {
        final String rex = "^Smart pool data source \\(.+\\) must be open.$";
        IllegalStateException thrown;
        Connection conn1, conn2, conn3, conn4;
        
        log.debug("testConnection()");

        // config
        poolAppConfigDataSourceConfigurationHikari.copy(poolAppConfigDataSourceConfiguration);
        poolAppConfigDataSourceConfigurationOracle.copy(poolAppConfigDataSourceConfiguration);

        // ocpi
        poolAppOcpiDataSourceConfigurationHikari.copy(poolAppOcpiDataSourceConfiguration);
        poolAppOcpiDataSourceConfigurationOracle.copy(poolAppOcpiDataSourceConfiguration);

        for (int i = 0; i < 2; i++) {
            // these two will be combined
            final SmartPoolDataSource pds1 = SmartPoolDataSource.build(poolAppConfigDataSourceConfigurationHikari);
            final SmartPoolDataSource pds2 = SmartPoolDataSource.build(poolAppOcpiDataSourceConfigurationHikari);

            // do not use assertEquals(pds1.getCommonPoolDataSource(), pds2.getCommonPoolDataSource()) since equals() is overridden
            assertTrue(pds1.getCommonPoolDataSource() != pds2.getCommonPoolDataSource()); // GJP 2023-02-23

            assertEquals(pds1.getMinPoolSize(),
                         poolAppConfigDataSourceConfigurationHikari.getMinimumIdle());

            assertEquals(pds2.getMaxPoolSize(),
                         poolAppOcpiDataSourceConfigurationHikari.getMaximumPoolSize());

            assertEquals(pds1.getPoolName(), "HikariPool-bocsconf");
            assertEquals(pds2.getPoolName(), "HikariPool-boocpi");

            // these two will be combined too
            final SmartPoolDataSource pds3 = SmartPoolDataSource.build(poolAppConfigDataSourceConfigurationOracle);
            final SmartPoolDataSource pds4 = SmartPoolDataSource.build(poolAppOcpiDataSourceConfigurationOracle);

            assertTrue(pds3.getCommonPoolDataSource() == pds4.getCommonPoolDataSource());

            // Hikari != Oracle
            assertFalse(pds1.getCommonPoolDataSource() == pds3.getCommonPoolDataSource());

            assertEquals(pds3.getInitialPoolSize(),
                         poolAppConfigDataSourceConfigurationOracle.getInitialPoolSize() +
                         poolAppOcpiDataSourceConfigurationOracle.getInitialPoolSize());

            assertEquals(pds3.getMinPoolSize(),
                         poolAppConfigDataSourceConfigurationOracle.getMinPoolSize() +
                         poolAppOcpiDataSourceConfigurationOracle.getMinPoolSize());

            assertEquals(pds3.getMaxPoolSize(),
                         poolAppConfigDataSourceConfigurationOracle.getMaxPoolSize() +
                         poolAppOcpiDataSourceConfigurationOracle.getMaxPoolSize());

            assertEquals(pds3.getPoolName(), "OraclePool-bocsconf-boocpi");
            assertEquals(pds3.getPoolName(), pds4.getPoolName());
            
            // get some connections
            for (int j = 0; j < 2; j++) {
                assertNotNull(conn1 = pds1.getConnection());
                assertNotNull(conn2 = pds2.getConnection());
                assertNotNull(conn3 = pds3.getConnection());
                assertNotNull(conn4 = pds4.getConnection());

                assertEquals(2, pds1.getActiveConnections());
                assertEquals(pds1.getTotalConnections(), pds1.getActiveConnections() + pds1.getIdleConnections());

                assertEquals(2, pds4.getActiveConnections());
                assertEquals(pds4.getTotalConnections(), pds4.getActiveConnections() + pds4.getIdleConnections());
                
                conn1.close();
                conn2.close();
                conn3.close();
                conn4.close();
            }

            // close pds4
            assertFalse(pds4.isClosed());
            pds4.close();
            assertTrue(pds4.isClosed());
            assertFalse(pds4.getCommonPoolDataSource().isClosed()); // must close pds3 too

            thrown = assertThrows(IllegalStateException.class, () -> pds4.getConnection());
            assertTrue(thrown.getMessage().matches(rex));

            // close pds3
            assertFalse(pds3.isClosed());
            pds3.close();
            assertTrue(pds3.isClosed());
            assertTrue(pds4.getCommonPoolDataSource().isClosed()); // done

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
            assertTrue(pds2.getCommonPoolDataSource().isClosed()); // done

            thrown = assertThrows(IllegalStateException.class, () -> pds1.getConnection());
            assertTrue(thrown.getMessage().matches(rex));
        }
    }
}
