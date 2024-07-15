package com.paulissoft.pato.jdbc;

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

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

@Slf4j
@ExtendWith(SpringExtension.class)
@EnableConfigurationProperties({MyDomainDataSourceHikari.class, MyOperatorDataSourceHikari.class})
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryHikari.class})
@TestPropertySource("classpath:application-test.properties")
public class CheckConnectionHikariUnitTest {

    @Autowired
    @Qualifier("configDataSourceHikari4")
    private SmartPoolDataSourceHikari configDataSourceHikari;

    @Autowired
    @Qualifier("ocpiDataSourceHikari1")
    private SmartPoolDataSourceHikari ocpiDataSourceHikari;

    @Autowired
    @Qualifier("ocppDataSourceHikari1")
    private SmartPoolDataSourceHikari ocppDataSourceHikari;

    @Autowired
    private MyDomainDataSourceHikari domainDataSourceHikari;
    
    @Autowired
    private MyOperatorDataSourceHikari operatorDataSourceHikari;
    
    @BeforeAll
    static void clear() {
        PoolDataSourceStatistics.clear();
    }

    //=== Hikari ===

    @Test
    void testConnection() throws SQLException {
        final String rex1 = "^You can only get a connection when the pool state is OPEN but it is CLOSED\\.$";
        IllegalStateException thrown1;
        Connection conn1, conn2, conn3;
        
        log.debug("testConnection()");

        final SmartPoolDataSourceHikari pds1 = configDataSourceHikari;
        final SmartPoolDataSourceHikari pds2 = ocpiDataSourceHikari;
        final SmartPoolDataSourceHikari pds3 = ocppDataSourceHikari;

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

        thrown1 = assertThrows(IllegalStateException.class, pds3::getConnection);
        log.debug("message: {}", thrown1.getMessage());       
        assertTrue(thrown1.getMessage().matches(rex1));

        // close pds2
        assertTrue(pds2.isOpen());
        pds2.close();
        assertFalse(pds2.isOpen());

        thrown1 = assertThrows(IllegalStateException.class, pds2::getConnection);
        log.debug("message: {}", thrown1.getMessage());       
        assertTrue(thrown1.getMessage().matches(rex1));

        // close pds1
        assertTrue(pds1.isOpen());
        pds1.close();
        assertSame(pds1.getState(), SmartPoolDataSourceHikari.State.CLOSED);

        thrown1 = assertThrows(IllegalStateException.class, pds1::getConnection);
        log.debug("message: {}", thrown1.getMessage());        
        assertTrue(thrown1.getMessage().matches(rex1));
    }
}
