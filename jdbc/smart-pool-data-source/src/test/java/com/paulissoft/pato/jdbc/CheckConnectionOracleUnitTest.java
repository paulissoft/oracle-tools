package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.sql.Connection;
import java.sql.SQLException;
import lombok.extern.slf4j.Slf4j;
import oracle.jdbc.OracleConnection;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Disabled;
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
    @Qualifier("configDataSource4")
    private SmartPoolDataSourceOracle configDataSourceOracle;

    @Autowired
    @Qualifier("ocpiDataSource1")
    private SmartPoolDataSourceOracle ocpiDataSourceOracle;

    @Autowired
    @Qualifier("ocppDataSource1")
    private SmartPoolDataSourceOracle ocppDataSourceOracle;
        
    @Autowired
    private MyDomainDataSourceOracle domainDataSourceOracle;
    
    @Autowired
    private MyOperatorDataSourceOracle operatorDataSourceOracle;
    
    @BeforeAll
    static void clear() {
        PoolDataSourceStatistics.clear();
    }

    @Disabled
    @Test
    void testConnection() throws SQLException {
        final String rex1 = "^You can only get a connection when the pool state is OPEN but it is CLOSED.$";
        IllegalStateException thrown1;
        Connection conn1, conn2, conn3;
        
        log.debug("testConnection()");

        final SmartPoolDataSourceOracle pds1 = configDataSourceOracle;
        final SmartPoolDataSourceOracle pds2 = ocpiDataSourceOracle;
        final SmartPoolDataSourceOracle pds3 = ocppDataSourceOracle;

        // get some connections
        for (int j = 0; j < 2; j++) {
            /*
            // UCP-0: Unable to start the Universal Connection Pool
            // UCP-45386: Error during pool creation in Universal Connection Pool Manager MBean
            // UCP-22: Invalid Universal Connection Pool configuration
            // UCP-45350: Universal Connection Pool already exists in the Universal Connection Pool Manager.
            //            Universal Connection Pool cannot be added to the Universal Connection Pool Manager
            */
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

        thrown1 = assertThrows(IllegalStateException.class, () -> pds3.getConnection());
        log.debug("message: {}", thrown1.getMessage());        
        assertTrue(thrown1.getMessage().matches(rex1));

        // close pds2
        assertTrue(pds2.isOpen());
        pds2.close();
        assertFalse(pds2.isOpen());

        thrown1 = assertThrows(IllegalStateException.class, () -> pds2.getConnection());
        log.debug("message: {}", thrown1.getMessage());        
        assertTrue(thrown1.getMessage().matches(rex1));

        // close pds1
        assertTrue(pds1.isOpen());
        pds1.close();
        assertTrue(pds1.getState() == SmartPoolDataSourceOracle.State.CLOSED);

        thrown1 = assertThrows(IllegalStateException.class, () -> pds1.getConnection());
        log.debug("message: {}", thrown1.getMessage());        
        assertTrue(thrown1.getMessage().matches(rex1));
    }
}
