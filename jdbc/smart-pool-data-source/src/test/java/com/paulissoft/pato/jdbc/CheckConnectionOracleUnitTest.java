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
@EnableConfigurationProperties({MyDomainDataSourceOracle.class, MyOperatorDataSourceOracle.class})
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryOracle.class})
@TestPropertySource("classpath:application-test.properties")
public class CheckConnectionOracleUnitTest {

    @Autowired
    @Qualifier("configDataSource1")
    private CombiPoolDataSourceOracle configDataSourceOracle;

    @Autowired
    @Qualifier("ocpiDataSource1")
    private CombiPoolDataSourceOracle ocpiDataSourceOracle;

    @Autowired
    @Qualifier("ocppDataSource1")
    private CombiPoolDataSourceOracle ocppDataSourceOracle;
        
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
        final String rex = "^You can only get a connection when the pool state is OPEN or CLOSING but it is CLOSED.$";
        IllegalStateException thrown;
        Connection conn1, conn2, conn3;
        
        log.debug("testConnection()");

        final CombiPoolDataSourceOracle pds1 = configDataSourceOracle;
        final CombiPoolDataSourceOracle pds2 = ocpiDataSourceOracle;
        final CombiPoolDataSourceOracle pds3 = ocppDataSourceOracle;

        // the first to create will become the parent
        assertTrue(pds1.isParentPoolDataSource());
        assertFalse(pds2.isParentPoolDataSource());
        assertFalse(pds3.isParentPoolDataSource());

        // all share the same common pool data source
        assertTrue(pds1.getPoolDataSource() == pds2.getPoolDataSource());
        assertTrue(pds1.getPoolDataSource() == pds3.getPoolDataSource());

        // get some connections
        for (int j = 0; j < 2; j++) {
            assertNotNull(conn1 = pds1.getConnection());
            assertTrue(pds1.isOpen());
            
            assertNotNull(conn2 = pds2.getConnection());
            assertTrue(pds2.isOpen());

            assertNotNull(conn3 = pds3.getConnection());
            assertTrue(pds3.isOpen());

            assertTrue(pds1.getActiveConnections() >= 1);
            assertEquals(pds1.getActiveConnections() +
                         pds1.getIdleConnections(),
                         pds1.getTotalConnections());

            assertTrue(pds2.getActiveConnections() >= 1);
            assertEquals(pds2.getActiveConnections() +
                         pds2.getIdleConnections(),
                         pds2.getTotalConnections());

            assertTrue(pds3.getActiveConnections() >= 1);
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

    @Test
    void testConnectionOracle() throws SQLException {
        log.debug("testConnectionOracle()");

        assertNotEquals(domainDataSourceOracle, operatorDataSourceOracle);

        assertNotEquals(domainDataSourceOracle.isParentPoolDataSource(), operatorDataSourceOracle.isParentPoolDataSource());

        final CombiPoolDataSourceOracle parent =
            domainDataSourceOracle.isParentPoolDataSource() ? domainDataSourceOracle : operatorDataSourceOracle;

        final CombiPoolDataSourceOracle child =
            !domainDataSourceOracle.isParentPoolDataSource() ? domainDataSourceOracle : operatorDataSourceOracle;

        for (int nr = 1; nr <= 2; nr++) {
            // no try open block in order not to interfere with other tests
            final CombiPoolDataSourceOracle ds = (nr == 1 ? parent : child);

            log.debug("round #{}; ds.getPoolDataSourceConfiguration(): {}", nr, ds.getPoolDataSourceConfiguration());
                
            assertEquals(CombiPoolDataSource.State.OPEN, ds.getState());
                
            assertEquals("jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1", ds.getURL());
                
            assertEquals(ds == domainDataSourceOracle ? "bodomain" : "bodomain[boopapij]",
                         ds.getPoolDataSourceConfiguration().getUsername());
            assertEquals(parent.getUser(), ds.getPoolDataSource().getUser());

            // NoSuchMethod this method is deprecated
            // assertEquals("bodomain", ds.getPassword());
            assertEquals("bodomain", ds.getPoolDataSourceConfiguration().getPassword());

            assertEquals(2 * 0, ds.getInitialPoolSize());
            assertEquals(ds.getInitialPoolSize(), ds.getPoolDataSource().getInitialPoolSize());

            assertEquals(2 * 10, ds.getMinPoolSize());
            assertEquals(ds.getMinPoolSize(), ds.getPoolDataSource().getMinPoolSize());

            assertEquals(2 * 20, ds.getMaxPoolSize());
            assertEquals(ds.getMaxPoolSize(), ds.getPoolDataSource().getMaxPoolSize());
                                
            assertTrue(ds.getConnectionPoolName().equals(operatorDataSourceOracle.getPoolNamePrefix() + "-boopapij") ||
                       ds.getConnectionPoolName().equals(domainDataSourceOracle.getPoolNamePrefix() + "-bodomain"));
            assertEquals(ds.getConnectionPoolName(), ds.getPoolDataSource().getConnectionPoolName());

            final Connection conn = ds.getConnection();

            assertNotNull(conn);
            assertEquals(ds == domainDataSourceOracle ? "BODOMAIN" : "BOOPAPIJ", conn.getSchema());
                
            conn.close();
        }
    }
}
