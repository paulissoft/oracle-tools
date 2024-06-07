package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.sql.Connection;
import java.sql.SQLException;
import lombok.extern.slf4j.Slf4j;
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
@EnableConfigurationProperties({MyDomainDataSourceHikari.class, MyOperatorDataSourceHikari.class}) // keep it like that
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryHikari.class})
@TestPropertySource("classpath:application-test.properties")
public class CheckOverflowHikariUnitTest {

    @Autowired
    @Qualifier("configDataSource3")
    private OverflowPoolDataSourceHikari configDataSourceHikari;

    //=== Hikari ===

    @Test
    void testConnection() throws SQLException {
        final String rex = "^You can only get a connection when the pool state is OPEN but it is CLOSED.$";
        IllegalStateException thrown;
        Connection conn;
        
        log.debug("testConnection()");

        final OverflowPoolDataSourceHikari pds = configDataSourceHikari;

        // get some connections
        for (int j = 0; j < 2; j++) {
            assertNotNull(conn = pds.getConnection());
            assertTrue(pds.isOpen());

            assertTrue(pds.getActiveConnections() >= 1);
            assertEquals(pds.getActiveConnections() +
                         pds.getIdleConnections(),
                         pds.getTotalConnections());

            conn.close();
        }

        // close pds
        assertTrue(pds.isOpen());
        pds.close();
        assertFalse(pds.isOpen());

        thrown = assertThrows(IllegalStateException.class, () -> pds.getConnection());
        assertTrue(thrown.getMessage().matches(rex));
    }

    @Test
    void testNoIdleConnections() throws SQLException {
        final String rex = "^You can only get a connection when the pool state is OPEN but it is CLOSED.$";
        IllegalStateException thrown;
        
        log.debug("testNoIdleConnections()");

        final OverflowPoolDataSourceHikari pds = configDataSourceHikari;

        thrown = assertThrows(IllegalStateException.class, () -> {
                for (int j = 0; j <= configDataSourceHikari.getMaxPoolSize(); j++) {
                    assertNotNull(pds.getConnection());
                }
            });

        log.debug("message: {}", thrown.getMessage());
        
        assertTrue(thrown.getMessage().matches(rex));

        // close pds
        pds.close();
    }
}
