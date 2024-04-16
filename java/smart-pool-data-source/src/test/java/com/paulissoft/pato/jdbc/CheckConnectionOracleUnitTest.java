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
    @Qualifier("configDataSource")
    private CombiPoolDataSourceOracle configDataSourceOracle;

    @Autowired
    @Qualifier("ocpiDataSource")
    private CombiPoolDataSourceOracle ocpiDataSourceOracle;

    @Autowired
    @Qualifier("ocppDataSource")
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
        Connection conn4, conn5, conn6;
        
        log.debug("testConnection()");

        final CombiPoolDataSourceOracle pds4 = configDataSourceOracle;
        final CombiPoolDataSourceOracle pds5 = ocpiDataSourceOracle;
        final CombiPoolDataSourceOracle pds6 = ocppDataSourceOracle;

        // the first to create will become the parent
        assertTrue(pds4.isParentPoolDataSource());
        assertFalse(pds5.isParentPoolDataSource());
        assertFalse(pds6.isParentPoolDataSource());

        // all share the same common pool data source
        assertTrue(pds4.getPoolDataSource() == pds5.getPoolDataSource());
        assertTrue(pds4.getPoolDataSource() == pds6.getPoolDataSource());

        // get some connections
        for (int j = 0; j < 2; j++) {
            assertNotNull(conn4 = pds4.getConnection());
            assertTrue(pds4.isOpen());
            
            assertNotNull(conn5 = pds5.getConnection());
            assertTrue(pds5.isOpen());

            assertNotNull(conn6 = pds6.getConnection());
            assertTrue(pds6.isOpen());

            assertTrue(pds4.getActiveConnections() >= 1);
            assertEquals(pds4.getActiveConnections() +
                         pds4.getIdleConnections(),
                         pds4.getTotalConnections());

            assertTrue(pds5.getActiveConnections() >= 1);
            assertEquals(pds5.getActiveConnections() +
                         pds5.getIdleConnections(),
                         pds5.getTotalConnections());

            assertTrue(pds6.getActiveConnections() >= 1);
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
                
                assertEquals(ds == domainDataSourceOracle ? "bodomain" : "bodomain[boopapij]", ds.getPoolDataSourceConfiguration().getUsername());
                assertEquals(parent.getUser(), ds.getPoolDataSource().getUser());

                // NoSuchMethod this method is deprecated
                // assertEquals("bodomain", ds.getPassword());
                assertEquals("bodomain", ds.getPoolDataSourceConfiguration().getPassword());

                assertEquals(2 * 10, ds.getMinPoolSize());
                //assertEquals(parent.getMinPoolSize() + child.getMinPoolSize(), ds.getPoolDataSource().getMinPoolSize());
                assertEquals(ds.getMinPoolSize(), ds.getPoolDataSource().getMinPoolSize());

                assertEquals(2 * 20, ds.getMaxPoolSize());
                //assertEquals(parent.getMaxPoolSize() + child.getMaxPoolSize(), ds.getPoolDataSource().getMaxPoolSize());
                assertEquals(ds.getMaxPoolSize(), ds.getPoolDataSource().getMaxPoolSize());
                                
                assertEquals("OraclePool-boopapij-bodomain", ds.getConnectionPoolName());
                assertEquals(ds.getConnectionPoolName(), ds.getPoolDataSource().getConnectionPoolName());

                final Connection conn = ds.getConnection();

                assertNotNull(conn);
                assertEquals(ds == domainDataSourceOracle ? "BODOMAIN" : "BOOPAPIJ", conn.getSchema());
                
                conn.close();
            }
        }
    }
}
