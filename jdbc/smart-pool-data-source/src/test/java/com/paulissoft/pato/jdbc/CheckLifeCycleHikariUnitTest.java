package com.paulissoft.pato.jdbc;

//import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.SQLException;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@ExtendWith(SpringExtension.class)
// not needed in this file but apparently Spring needs it
@EnableConfigurationProperties({MyDomainDataSourceHikari.class, MyOperatorDataSourceHikari.class})
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryHikari.class})
@TestPropertySource("classpath:application-test.properties")
public class CheckLifeCycleHikariUnitTest {

    @Autowired
    @Qualifier("configDataSourceHikari4")
    private SmartPoolDataSourceHikari configDataSourceHikari;

    @Autowired
    @Qualifier("ocpiDataSourceProperties")
    private DataSourceProperties ocpiDataSourceProperties;
        
    @Autowired
    @Qualifier("ocppDataSourceProperties")
    private DataSourceProperties ocppDataSourceProperties;
        
    @BeforeAll
    static void clear() {
        PoolDataSourceStatistics.clear();
    }

    //=== Hikari ===

    @Disabled("A parent status must be OPEN.")
    @Test
    void testSimplePoolDataSourceHikariJoinTwice() throws SQLException {
        log.debug("testSimplePoolDataSourceHikariJoinTwice()");

        // do not use a try open block for the parent (configDataSourceHikari)
        // since it will close the pool data source giving problems for other tests
        final SmartPoolDataSourceHikari pds1 = configDataSourceHikari;

        PoolDataSourceConfigurationHikari pdsConfig = (PoolDataSourceConfigurationHikari) pds1.get();
        
        pds1.open();
        log.debug("pds1.isOpen(): {}; pds1.getState(): {}", pds1.isOpen(), pds1.getState());
        assertTrue(pds1.isOpen());

        pdsConfig =
            pdsConfig
            .toBuilder() // copy
            .username(ocpiDataSourceProperties.getUsername())
            .password(ocpiDataSourceProperties.getPassword())
            .build();
                    
        // scratch variable
        SmartPoolDataSourceHikari pds = null;

        try (final SmartPoolDataSourceHikari pds2 = new SmartPoolDataSourceHikari(pdsConfig)) {
            assertFalse(pds2.isOpen());
            pds2.open();
            assertTrue(pds2.isOpen());

            pdsConfig = (PoolDataSourceConfigurationHikari) pds1.get();
            
            pdsConfig =
                pdsConfig
                .toBuilder() // copy
                .username(ocppDataSourceProperties.getUsername())
                .password(ocppDataSourceProperties.getPassword())
                .build();

            try (final SmartPoolDataSourceHikari pds3 = new SmartPoolDataSourceHikari(pdsConfig)) {
                assertFalse(pds3.isOpen());
                pds3.open();
                assertTrue(pds3.isOpen());

                checkSimplePoolDataSourceJoin(pds1, pds2, true);
                checkSimplePoolDataSourceJoin(pds2, pds3, true);
                checkSimplePoolDataSourceJoin(pds3, pds1, true);

                pdsConfig = (PoolDataSourceConfigurationHikari) pds1.get();

                // change one property
                final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari1 =
                    pdsConfig
                    .toBuilder()
                    .autoCommit(!pdsConfig.isAutoCommit())
                    .build();
                        
                try (final SmartPoolDataSourceHikari pds4 = new SmartPoolDataSourceHikari(poolDataSourceConfigurationHikari1)) {
                    assertTrue(pds4.isOpen());

                    assertNotEquals(pds1.get().toString(),
                                    pds4.get().toString());

                    pds = pds4;
                }
                assertFalse(pds.isOpen());

                pds = pds3;
            }
            assertFalse(pds.isOpen());

            pds = pds2;
        }
        assertFalse(pds.isOpen());
        assertTrue(pds1.isOpen());
    }

    private void checkSimplePoolDataSourceJoin(final SmartPoolDataSourceHikari pds1, final SmartPoolDataSourceHikari pds2, final boolean equal) {
        PoolDataSourceConfiguration poolDataSourceConfiguration1 = null;
        PoolDataSourceConfiguration poolDataSourceConfiguration2 = null;
            
        // check all fields
        poolDataSourceConfiguration1 = pds1.get();
        poolDataSourceConfiguration2 = pds2.get();

        log.debug("poolDataSourceConfiguration1: {}", poolDataSourceConfiguration1);
        log.debug("poolDataSourceConfiguration2: {}", poolDataSourceConfiguration2);

        // usernames differ
        assertNotEquals(poolDataSourceConfiguration1.toString(), poolDataSourceConfiguration2.toString());
        
    }
}
