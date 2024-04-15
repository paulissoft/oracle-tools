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
@EnableConfigurationProperties({MyDomainDataSourceOracle.class, MyOperatorDataSourceOracle.class})
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryOracle.class})
@TestPropertySource("classpath:application-test.properties")
public class CheckConnectionOracleUnitTest {

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
    private MyDomainDataSourceOracle domainDataSourceOracle;
    
    @Autowired
    private MyOperatorDataSourceOracle operatorDataSourceOracle;
    
    @BeforeAll
    static void clear() {
        PoolDataSourceStatistics.clear();
        CombiPoolDataSource.clear();
    }

    @Test
    void testConnection() throws SQLException {
        final String rex = "^Smart pool data source \\(.+\\) must be open.$";
        IllegalStateException thrown;
        Connection conn4, conn5, conn6;
        
        log.debug("testConnection()");

        for (int i = 0; i < 2; i++) {
            // these two will be combined
            final SmartPoolDataSourceOracle pds4 =
                configDataSourceProperties
                .initializeDataSourceBuilder()
                .type(SmartPoolDataSourceOracle.class)
                .build();

            if (i >= 2) { conn4 = pds4.getConnection(); if (i == 3) { conn4.close(); } }
            
            final SmartPoolDataSourceOracle pds5 =
                ocpiDataSourceProperties
                .initializeDataSourceBuilder()
                .type(SmartPoolDataSourceOracle.class)
                .build();

            if (i >= 2) { conn5 = pds5.getConnection(); if (i == 3) { conn5.close(); } }
            
            final SmartPoolDataSourceOracle pds6 =
                domainDataSourceProperties
                .initializeDataSourceBuilder()
                .type(SmartPoolDataSourceOracle.class)
                .build();

            if (i >= 2) { conn6 = pds6.getConnection(); if (i == 3) { conn6.close(); } }            

            // first getConnection() (i >= 2) will open the pool data source
            switch(i) {
            case 0:
                // the first to create will become the parent
                assertTrue(pds4.isParentPoolDataSource());
                assertFalse(pds5.isParentPoolDataSource());
                assertFalse(pds6.isParentPoolDataSource());

                // all share the same common pool data source
                assertTrue(pds4.getPoolDataSource() == pds5.getPoolDataSource());
                assertTrue(pds4.getPoolDataSource() == pds6.getPoolDataSource());

                // fall thru
            case 1:
                assertFalse(pds4.isOpen());
                assertFalse(pds5.isOpen());
                assertFalse(pds6.isOpen());
                break;
                
            case 2:
            case 3:
                log.debug("pds4.getPoolDataSourceConfiguration(): {}", pds4.getPoolDataSourceConfiguration());
                log.debug("pds5.getPoolDataSourceConfiguration(): {}", pds5.getPoolDataSourceConfiguration());
                log.debug("pds6.getPoolDataSourceConfiguration(): {}", pds6.getPoolDataSourceConfiguration());

                assertTrue(pds4.isOpen());
                assertTrue(pds5.isOpen());
                assertTrue(pds6.isOpen());
                break;
            }
            
            // get some connections
            for (int j = 0; j < 2; j++) {
                assertNotNull(conn4 = pds4.getConnection());
                assertNotNull(conn5 = pds5.getConnection());
                assertNotNull(conn6 = pds6.getConnection());

                assertEquals(1, pds4.getActiveConnections());
                assertEquals(pds4.getActiveConnections() +
                             pds4.getIdleConnections(),
                             pds4.getTotalConnections());

                assertEquals(1, pds5.getActiveConnections());
                assertEquals(pds5.getActiveConnections() +
                             pds5.getIdleConnections(),
                             pds5.getTotalConnections());

                assertEquals(1, pds6.getActiveConnections());
                assertEquals(pds6.getActiveConnections() +
                             pds6.getIdleConnections(),
                             pds6.getTotalConnections());

                assertEquals(conn4.unwrap(OracleConnection.class).getClass(),
                             conn5.unwrap(Connection.class).getClass());
                assertEquals(conn4.unwrap(OracleConnection.class).getClass(),
                             conn6.unwrap(Connection.class).getClass());

                conn4.close();
                conn5.close();
                conn6.close();
            }

            // close pds6
            assertTrue(pds6.isOpen());
            pds6.close();
            assertFalse(pds6.isOpen());

            thrown = assertThrows(IllegalStateException.class, () -> pds6.getConnection());
            assertTrue(thrown.getMessage().matches(rex));

            // close pds5
            assertTrue(pds5.isOpen());
            pds5.close();
            assertFalse(pds5.isOpen());

            thrown = assertThrows(IllegalStateException.class, () -> pds5.getConnection());
            assertTrue(thrown.getMessage().matches(rex));

            // close pds4
            assertTrue(pds4.isOpen());
            pds4.close();
            assertFalse(pds4.isOpen());

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
                
                assertEquals(ds == domainDataSourceOracle ? "bc_proxy[bodomain]" : "bc_proxy[boopapij]", ds.getUsername());
                assertEquals(parent.getUser(), ds.getPoolDataSource().getUser());

                assertEquals("bc_proxy", ds.getPassword());
                // NoSuchMethod this method is deprecated
                // assertEquals(parent.getPassword(), ds.getPoolDataSource().getPassword());

                assertEquals(10, ds.getMinPoolSize());
                assertEquals(parent.getMinPoolSize() + child.getMinPoolSize(), ds.getPoolDataSource().getMinPoolSize());

                assertEquals(20, ds.getMaxPoolSize());
                assertEquals(parent.getMaxPoolSize() + child.getMaxPoolSize(), ds.getPoolDataSource().getMaxPoolSize());
                                
                assertEquals(ds == domainDataSourceOracle ? "OraclePool-bodomain" : "OraclePool-bodomain-boopapij", ds.getConnectionPoolName());
                assertEquals("OraclePool-bodomain-boopapij", ds.getPoolDataSource().getConnectionPoolName());

                final Connection conn = ds.getConnection();

                assertNotNull(conn);
                assertEquals(ds == domainDataSourceOracle ? "BODOMAIN" : "BOOPAPIJ", conn.getSchema());
                
                conn.close();
            }
        }
    }
}
