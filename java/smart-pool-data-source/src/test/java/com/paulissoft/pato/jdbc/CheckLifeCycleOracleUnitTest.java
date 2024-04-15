package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

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
@EnableConfigurationProperties({PoolDataSourceConfiguration.class, PoolDataSourceConfiguration.class, PoolDataSourceConfigurationOracle.class})
@ContextConfiguration(classes = ConfigurationFactoryOracle.class)
@TestPropertySource("classpath:application-test.properties")
public class CheckLifeCycleOracleUnitTest {

    @Autowired
    @Qualifier("authDataSourceProperties")
    private DataSourceProperties authDataSourceProperties;
        
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

    //=== Oracle ===

    @Test
    void testSimplePoolDataSourceOracleJoinTwice() throws SQLException {
        log.debug("testSimplePoolDataSourceOracleJoinTwice()");

        for (int i = 0; i < 2; i++) {
            try (final SmartPoolDataSourceOracle pds1 = authDataSourceProperties
                 .initializeDataSourceBuilder()
                 .type(SmartPoolDataSourceOracle.class)
                 .build()) {
                assertTrue(pds1.isOpen());

                try (final SmartPoolDataSourceOracle pds2 = ocpiDataSourceProperties
                     .initializeDataSourceBuilder()
                     .type(SmartPoolDataSourceOracle.class)
                     .build()) {
                    assertTrue(pds2.isOpen());

                    try (final SmartPoolDataSourceOracle pds3 = ocppDataSourceProperties
                         .initializeDataSourceBuilder()
                         .type(SmartPoolDataSourceOracle.class)
                         .build()) {
                        assertTrue(pds3.isOpen());

                        checkSimplePoolDataSourceJoin(pds1, pds2, false);
                        checkSimplePoolDataSourceJoin(pds2, pds3, true); // 2 == 3
                        checkSimplePoolDataSourceJoin(pds3, pds1, false);

                        // change one property and create a smart pool data source: total pool count should increase
                        final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle1 =
                            pds1
                            .getPoolDataSourceConfiguration()
                            .toBuilder()
                            .validateConnectionOnBorrow(!pds1.getPoolDataSourceConfiguration().getValidateConnectionOnBorrow())
                            .build();

                        try (final SmartPoolDataSourceOracle pds4 = new SmartPoolDataSourceOracle(poolDataSourceConfigurationOracle1)) {
                            assertTrue(pds4.isOpen());
                            
                            assertNotEquals(pds1.getPoolDataSourceConfiguration().toString(),
                                            pds4.getPoolDataSourceConfiguration().toString());
                        }
                    }
                }
            }
        }
    }

    private void checkSimplePoolDataSourceJoin(final SmartPoolDataSourceOracle pds1, final SmartPoolDataSourceOracle pds2, final boolean equal) {
        PoolDataSourceConfiguration poolDataSourceConfiguration1 = null;
        PoolDataSourceConfiguration poolDataSourceConfiguration2 = null;
            
        // check all fields
        poolDataSourceConfiguration1 = pds1.getPoolDataSourceConfiguration();
        poolDataSourceConfiguration2 = pds2.getPoolDataSourceConfiguration();

        assertEquals(true,
                     poolDataSourceConfiguration1.toString().equals(poolDataSourceConfiguration2.toString()));
        
        poolDataSourceConfiguration1 = pds1.getPoolDataSourceConfiguration();
        poolDataSourceConfiguration2 = pds2.getPoolDataSourceConfiguration();

        assertEquals(equal,
                     poolDataSourceConfiguration1.toString().equals(poolDataSourceConfiguration2.toString()));
        
        assertEquals(pds1.isStatisticsEnabled(), pds2.isStatisticsEnabled());
        assertEquals(pds1.isSingleSessionProxyModel(), pds2.isSingleSessionProxyModel());
        assertEquals(pds1.isFixedUsernamePassword(), pds2.isFixedUsernamePassword());
    }
}
