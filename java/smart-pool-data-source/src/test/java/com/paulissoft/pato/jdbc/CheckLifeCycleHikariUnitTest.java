package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.SQLException;
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
import lombok.extern.slf4j.Slf4j;

@Slf4j
@ExtendWith(SpringExtension.class)
@EnableConfigurationProperties({MyDomainDataSourceHikari.class, MyOperatorDataSourceHikari.class})
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryHikari.class})
@TestPropertySource("classpath:application-test.properties")
public class CheckLifeCycleHikariUnitTest {

    @Autowired
    @Qualifier("configDataSource")
    private CombiPoolDataSourceHikari configDataSourceHikari;

    @Autowired
    @Qualifier("ocpiDataSourceProperties")
    private DataSourceProperties ocpiDataSourceProperties;
        
    @Autowired
    @Qualifier("ocppDataSourceProperties")
    private DataSourceProperties ocppDataSourceProperties;
        
    @BeforeAll
    static void clear() {
        PoolDataSourceStatistics.clear();
        CombiPoolDataSource.clear();
    }

    //=== Hikari ===

    @Test
    void testSimplePoolDataSourceHikariJoinTwice() throws SQLException {
        log.debug("testSimplePoolDataSourceHikariJoinTwice()");

        PoolDataSourceConfigurationHikari pdsConfig;

        for (int i = 0; i < 2; i++) {
            // pds1 is parent
            try (final CombiPoolDataSourceHikari pds1 = configDataSourceHikari) {
                assertTrue(pds1.isOpen());
                assertTrue(pds1.isParentPoolDataSource());

                pdsConfig =
                    pds1
                    .getPoolDataSourceConfiguration()
                    .toBuilder() // copy
                    .username(ocpiDataSourceProperties.getUsername())
                    .password(ocpiDataSourceProperties.getPassword())
                    .build();
                    
                try (final CombiPoolDataSourceHikari pds2 = new CombiPoolDataSourceHikari(pdsConfig, pds1)) {
                    assertFalse(pds2.isOpen());
                    assertFalse(pds2.isParentPoolDataSource());

                    pdsConfig =
                        pds1
                        .getPoolDataSourceConfiguration()
                        .toBuilder() // copy
                        .username(ocppDataSourceProperties.getUsername())
                        .password(ocppDataSourceProperties.getPassword())
                        .build();

                    try (final CombiPoolDataSourceHikari pds3 = new CombiPoolDataSourceHikari(pdsConfig, pds1)) {
                        assertFalse(pds3.isOpen());
                        assertFalse(pds3.isParentPoolDataSource());

                        checkSimplePoolDataSourceJoin(pds1, pds2, true);
                        checkSimplePoolDataSourceJoin(pds2, pds3, true);
                        checkSimplePoolDataSourceJoin(pds3, pds1, true);

                        // change one property
                        final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari1 =
                            pds1
                            .getPoolDataSourceConfiguration()
                            .toBuilder()
                            .autoCommit(!pds1.getPoolDataSourceConfiguration().isAutoCommit())
                            .build();
                        
                        try (final CombiPoolDataSourceHikari pds4 = new CombiPoolDataSourceHikari(poolDataSourceConfigurationHikari1)) {
                            assertTrue(pds4.isOpen());
                            assertTrue(pds4.isParentPoolDataSource()); // a parent too

                            assertNotEquals(pds1.getPoolDataSourceConfiguration().toString(),
                                            pds4.getPoolDataSourceConfiguration().toString());
                        }
                    }
                }
            }
        }
    }

    private void checkSimplePoolDataSourceJoin(final CombiPoolDataSourceHikari pds1, final CombiPoolDataSourceHikari pds2, final boolean equal) {
        PoolDataSourceConfiguration poolDataSourceConfiguration1 = null;
        PoolDataSourceConfiguration poolDataSourceConfiguration2 = null;
            
        // check all fields
        poolDataSourceConfiguration1 = pds1.getPoolDataSourceConfiguration();
        poolDataSourceConfiguration2 = pds2.getPoolDataSourceConfiguration();

        log.debug("poolDataSourceConfiguration1: {}", poolDataSourceConfiguration1);
        log.debug("poolDataSourceConfiguration2: {}", poolDataSourceConfiguration2);

        // usernames differ
        assertNotEquals(poolDataSourceConfiguration1.toString(), poolDataSourceConfiguration2.toString());
        
        assertEquals(pds1.isSingleSessionProxyModel(), pds2.isSingleSessionProxyModel());
        assertEquals(pds1.isFixedUsernamePassword(), pds2.isFixedUsernamePassword());
    }
}
