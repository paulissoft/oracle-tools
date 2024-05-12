package com.paulissoft.pato.jdbc.jmh;

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

import com.paulissoft.pato.jdbc.*;

@Slf4j
@ExtendWith(SpringExtension.class)
//@EnableConfigurationProperties({MyDomainDataSourceHikari.class, MyOperatorDataSourceHikari.class})
@ContextConfiguration(classes={ConfigurationFactory.class/*, ConfigurationFactoryHikari.class*/})
@TestPropertySource("classpath:application-test.properties")
public class CheckConnectionHikariUnitTest {

    @Test
    void testFactory() {    
        final Object cfg = SpringContext.getBean("authDataSourceProperties");
    }
    
    /*
    @Test
    void testConnection() throws SQLException {
        final String rex = "^You can only get a connection when the pool state is OPEN or CLOSING but it is CLOSED.$";
        IllegalStateException thrown;
        Connection conn1, conn2, conn3;
        
        log.debug("testConnection()");

        // these two will be combined
        final CombiPoolDataSourceHikari pds1 = (CombiPoolDataSourceHikari) SpringContext.getBean("configDataSourceHikari2");
        final CombiPoolDataSourceHikari pds2 = (CombiPoolDataSourceHikari) SpringContext.getBean("ocpiDataSourceHikari2");
        final CombiPoolDataSourceHikari pds3 = (CombiPoolDataSourceHikari) SpringContext.getBean("ocppDataSourceHikari2");

        // the first to create will become the parent
        assertTrue(pds1.isParentPoolDataSource());
        assertFalse(pds2.isParentPoolDataSource());
        assertFalse(pds3.isParentPoolDataSource());

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
    */
}
