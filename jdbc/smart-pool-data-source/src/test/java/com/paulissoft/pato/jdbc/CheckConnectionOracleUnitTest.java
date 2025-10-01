package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.SQLException;
import oracle.jdbc.OracleConnection;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;


@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryOracle.class})
@TestPropertySource("classpath:application-test.properties")
public class CheckConnectionOracleUnitTest {

    @Autowired
    @Qualifier("configDataSourceOracle4")
    private SmartPoolDataSourceOracle configDataSourceOracle;

    @Autowired
    @Qualifier("ocpiDataSourceOracle1")
    private SmartPoolDataSourceOracle ocpiDataSourceOracle;

    @Autowired
    @Qualifier("ocppDataSourceOracle1")
    private SmartPoolDataSourceOracle ocppDataSourceOracle;

    @Disabled
    @Test
    void testConnection() throws SQLException {
        final String rex1 = "^You can only get a connection when the pool state is OPEN but it is CLOSED.$";
        IllegalStateException thrown1;
        Connection conn1, conn2, conn3;
        
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

        thrown1 = assertThrows(IllegalStateException.class, pds3::getConnection);
        assertTrue(thrown1.getMessage().matches(rex1));

        // close pds2
        assertTrue(pds2.isOpen());
        pds2.close();
        assertFalse(pds2.isOpen());

        thrown1 = assertThrows(IllegalStateException.class, pds2::getConnection);
        assertTrue(thrown1.getMessage().matches(rex1));

        // close pds1
        assertTrue(pds1.isOpen());
        pds1.close();
        assertTrue(pds1.isClosed());

        thrown1 = assertThrows(IllegalStateException.class, pds1::getConnection);
        assertTrue(thrown1.getMessage().matches(rex1));
    }
}
