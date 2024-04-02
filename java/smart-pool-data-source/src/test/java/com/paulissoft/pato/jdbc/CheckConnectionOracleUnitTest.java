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
            DataSourceProperties.class,
            MyDomainDataSourceOracle.class,
            MyOperatorDataSourceOracle.class})
@ContextConfiguration(classes = ConfigurationFactoryOracle.class)
@TestPropertySource("classpath:application-test.properties")
public class CheckConnectionOracleUnitTest {

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
    private MyDomainDataSourceOracle domainDataSourceOracle;
    
    @Autowired
    private MyOperatorDataSourceOracle operatorDataSourceOracle;
    
    @BeforeAll
    static void clear() {
        SmartPoolDataSource.clear();
        CombiPoolDataSource.clear();
    }

    @Test
    void testConnection() throws SQLException {
        final String rex = "^Smart pool data source \\(.+\\) must be open.$";
        IllegalStateException thrown;
        Connection conn4, conn5, conn6;
        
        log.debug("testConnection()");

        // config
        poolAppConfigDataSourceConfigurationOracle.copyFrom(poolAppConfigDataSourceConfiguration);

        // ocpi
        poolAppOcpiDataSourceConfigurationOracle.copyFrom(poolAppOcpiDataSourceConfiguration);

        // domain
        poolAppDomainDataSourceConfigurationOracle.copyFrom(poolAppDomainDataSourceConfiguration);

        for (int i = 0; i < 2; i++) {
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
                assertNotNull(conn4 = pds4.getConnection());
                assertNotNull(conn5 = pds5.getConnection());
                assertNotNull(conn6 = pds6.getConnection());

                assertEquals(3, pds4.getCommonPoolDataSource().getActiveConnections());
                assertEquals(pds4.getCommonPoolDataSource().getActiveConnections() +
                             pds4.getCommonPoolDataSource().getIdleConnections(),
                             pds4.getCommonPoolDataSource().getTotalConnections());

                assertEquals(conn4.unwrap(OracleConnection.class).getClass(),
                             conn5.unwrap(Connection.class).getClass());
                assertEquals(conn4.unwrap(OracleConnection.class).getClass(),
                             conn6.unwrap(Connection.class).getClass());

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
        }
    }

    @Test
    void testConnectionOracle() throws SQLException {
        log.debug("testConnectionOracle()");

        assertNotEquals(domainDataSourceOracle, operatorDataSourceOracle);

        assertNotEquals(domainDataSourceOracle.isParentPoolDataSource(), operatorDataSourceOracle.isParentPoolDataSource());

        final CombiPoolDataSourceOracle parent = domainDataSourceOracle.isParentPoolDataSource() ? domainDataSourceOracle : operatorDataSourceOracle;

        final CombiPoolDataSourceOracle child = !domainDataSourceOracle.isParentPoolDataSource() ? domainDataSourceOracle : operatorDataSourceOracle;

        for (int nr = 1; nr <= 2; nr++) {
            try (final CombiPoolDataSourceOracle ds = (nr == 1 ? parent : child)) {
                log.debug("round #{}; ds.getPoolDataSourceConfiguration(): {}", nr, ds.getPoolDataSourceConfiguration());
                
                assertEquals(CombiPoolDataSource.State.OPEN, ds.getState());
                assertEquals("jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1", ds.getURL());
                assertEquals(parent.getUser(), ds.getUser());
                assertEquals(ds == domainDataSourceOracle ? "bc_proxy[bodomain]" : "bc_proxy[boopapij]", ds.getUsername());
                assertEquals(parent.getPassword(), ds.getPassword());

                assertEquals(10, ds.getMinPoolSize());
                assertEquals(parent.getMinPoolSize() + child.getMinPoolSize(), ds.getPoolDataSource().getMinPoolSize());

                assertEquals(20, ds.getMaxPoolSize());
                assertEquals(parent.getMaxPoolSize() + child.getMaxPoolSize(), ds.getPoolDataSource().getMaxPoolSize());
                                
                assertEquals(ds == domainDataSourceOracle ? "OraclePool-bodomain" : "OraclePool-boopapij", ds.getConnectionPoolName());
                assertEquals("OraclePool-bodomain-boopapij", ds.getPoolDataSource().getConnectionPoolName());

                final Connection conn = ds.getConnection();

                assertNotNull(conn);
                assertEquals(ds == domainDataSourceOracle ? "BODOMAIN" : "BOOPAPIJ", conn.getSchema());
                
                conn.close();
            }
        }
    }
}
