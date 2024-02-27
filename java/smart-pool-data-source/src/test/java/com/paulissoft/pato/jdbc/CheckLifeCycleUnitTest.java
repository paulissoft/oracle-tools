package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

import java.sql.SQLException;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@ExtendWith(SpringExtension.class)
@EnableConfigurationProperties({PoolDataSourceConfiguration.class, PoolDataSourceConfiguration.class, PoolDataSourceConfigurationHikari.class})
@ContextConfiguration(classes = ConfigurationFactory.class)
@TestPropertySource("classpath:application-test.properties")
public class CheckLifeCycleUnitTest {

    @Autowired
    @Qualifier("app-auth-datasource")
    private PoolDataSourceConfiguration poolAppAuthDataSourceConfiguration;

    @Autowired
    @Qualifier("app-ocpp-datasource")
    private PoolDataSourceConfiguration poolAppOcppDataSourceConfiguration;

    @Autowired
    @Qualifier("app-auth-datasource-hikari")
    private PoolDataSourceConfigurationHikari poolAppAuthDataSourceConfigurationHikari;

    @Autowired
    @Qualifier("app-ocpp-datasource-hikari")
    private PoolDataSourceConfigurationHikari poolAppOcppDataSourceConfigurationHikari;

    @Autowired
    @Qualifier("app-auth-datasource-oracle")
    private PoolDataSourceConfigurationOracle poolAppAuthDataSourceConfigurationOracle;

    @Autowired
    @Qualifier("app-ocpp-datasource-oracle")
    private PoolDataSourceConfigurationOracle poolAppOcppDataSourceConfigurationOracle;

    @BeforeAll
    static void clear() {
        SmartPoolDataSource.clear();
    }

    //=== Hikari ===

    @Test
    void testSimplePoolDataSourceHikariJoinTwice() throws SQLException {
        poolAppAuthDataSourceConfigurationHikari.copy(poolAppAuthDataSourceConfiguration);
        poolAppOcppDataSourceConfigurationHikari.copy(poolAppOcppDataSourceConfiguration);

        log.debug("testSimplePoolDataSourceHikariJoinTwice()");

        final int startTotalSmartPoolCount = SmartPoolDataSource.getTotalSmartPoolCount();
        final int startTotalSimplePoolCount = SmartPoolDataSource.getTotalSimplePoolCount();

        int startTotalSmartPoolCountAfter1 = 0,
            startTotalSimplePoolCountAfter1 = 0,
            startTotalSmartPoolCountAfter2 = 0,
            startTotalSimplePoolCountAfter2 = 0,
            startTotalSmartPoolCountAfter3 = 0,
            startTotalSimplePoolCountAfter3 = 0,
            startTotalSmartPoolCountAfter4 = 0,
            startTotalSimplePoolCountAfter4 = 0;
        
        for (int i = 0; i < 2; i++) {
            switch (i) {
            case 0:
                startTotalSmartPoolCountAfter1 = startTotalSmartPoolCount + 1;
                startTotalSimplePoolCountAfter1 = startTotalSimplePoolCount + 1;
                startTotalSmartPoolCountAfter2 = startTotalSmartPoolCount + 2;
                startTotalSimplePoolCountAfter2 = startTotalSimplePoolCount + 1;
                startTotalSmartPoolCountAfter3 = startTotalSmartPoolCount + 2;
                startTotalSimplePoolCountAfter3 = startTotalSimplePoolCount + 1;
                startTotalSmartPoolCountAfter4 = startTotalSmartPoolCount + 3;
                startTotalSimplePoolCountAfter4 = startTotalSimplePoolCount + 2;
                break;
                
            default:
                startTotalSmartPoolCountAfter1 = startTotalSmartPoolCountAfter2 = startTotalSmartPoolCountAfter3 = startTotalSmartPoolCountAfter4;
                startTotalSimplePoolCountAfter1 = startTotalSimplePoolCountAfter2 = startTotalSimplePoolCountAfter3 = startTotalSimplePoolCountAfter4;
                break;
            }

            try (final SmartPoolDataSource pds1 = SmartPoolDataSource.build(poolAppAuthDataSourceConfigurationHikari)) {
                assertEquals(false, pds1.isClosed());

                assertEquals(startTotalSmartPoolCountAfter1, SmartPoolDataSource.getTotalSmartPoolCount());
                assertEquals(startTotalSimplePoolCountAfter1, SmartPoolDataSource.getTotalSimplePoolCount());

                try (final SmartPoolDataSource pds2 = SmartPoolDataSource.build(poolAppOcppDataSourceConfigurationHikari)) { // not the same config as pds1
                    assertEquals(false, pds2.isClosed());

                    assertEquals(startTotalSmartPoolCountAfter2, SmartPoolDataSource.getTotalSmartPoolCount());
                    assertEquals(startTotalSimplePoolCountAfter2, SmartPoolDataSource.getTotalSimplePoolCount());

                    try (final SmartPoolDataSource pds3 = SmartPoolDataSource.build(poolAppOcppDataSourceConfigurationHikari)) { // same config as pds1
                        assertEquals(false, pds3.isClosed());

                        assertEquals(startTotalSmartPoolCountAfter3, SmartPoolDataSource.getTotalSmartPoolCount());
                        assertEquals(startTotalSimplePoolCountAfter3, SmartPoolDataSource.getTotalSimplePoolCount());

                        checkSimplePoolDataSourceJoin(pds1, pds2, false);
                        checkSimplePoolDataSourceJoin(pds2, pds3, true); // 2 == 3
                        checkSimplePoolDataSourceJoin(pds3, pds1, false);

                        // change one property and create a smart pool data source: total pool count should increase
                        final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari1 =
                            poolAppAuthDataSourceConfigurationHikari
                            .toBuilder()
                            .autoCommit(!poolAppAuthDataSourceConfigurationHikari.isAutoCommit())
                            .build();
                        
                        try (final SmartPoolDataSource pds4 = SmartPoolDataSource.build(poolDataSourceConfigurationHikari1)) {
                            assertEquals(false, pds4.isClosed());
                            
                            assertEquals(startTotalSmartPoolCountAfter4, SmartPoolDataSource.getTotalSmartPoolCount());
                            assertEquals(startTotalSimplePoolCountAfter4, SmartPoolDataSource.getTotalSimplePoolCount());

                            assertNotEquals(pds1.getCommonPoolDataSource().getPoolDataSourceConfiguration(),
                                            pds4.getCommonPoolDataSource().getPoolDataSourceConfiguration());
                        }
                    }
                }
            }
        }

        assertEquals(startTotalSmartPoolCountAfter4, SmartPoolDataSource.getTotalSmartPoolCount());
        assertEquals(startTotalSimplePoolCountAfter4, SmartPoolDataSource.getTotalSimplePoolCount());
    }

    //=== Oracle ===

    @Test
    void testSimplePoolDataSourceOracleJoinTwice() throws SQLException {
        poolAppAuthDataSourceConfigurationOracle.copy(poolAppAuthDataSourceConfiguration);
        poolAppOcppDataSourceConfigurationOracle.copy(poolAppOcppDataSourceConfiguration);

        log.debug("testSimplePoolDataSourceOracleJoinTwice()");

        final int startTotalSmartPoolCount = SmartPoolDataSource.getTotalSmartPoolCount();
        final int startTotalSimplePoolCount = SmartPoolDataSource.getTotalSimplePoolCount();

        int startTotalSmartPoolCountAfter1 = 0,
            startTotalSimplePoolCountAfter1 = 0,
            startTotalSmartPoolCountAfter2 = 0,
            startTotalSimplePoolCountAfter2 = 0,
            startTotalSmartPoolCountAfter3 = 0,
            startTotalSimplePoolCountAfter3 = 0,
            startTotalSmartPoolCountAfter4 = 0,
            startTotalSimplePoolCountAfter4 = 0;

        SmartPoolDataSource pds1, pds2, pds3, pds4;
        
        for (int i = 0; i < 2; i++) {
            switch (i) {
            case 0:
                startTotalSmartPoolCountAfter1 = startTotalSmartPoolCount + 1;
                startTotalSimplePoolCountAfter1 = startTotalSimplePoolCount + 1;
                startTotalSmartPoolCountAfter2 = startTotalSmartPoolCount + 2;
                startTotalSimplePoolCountAfter2 = startTotalSimplePoolCount + 1;
                startTotalSmartPoolCountAfter3 = startTotalSmartPoolCount + 2;
                startTotalSimplePoolCountAfter3 = startTotalSimplePoolCount + 1;
                startTotalSmartPoolCountAfter4 = startTotalSmartPoolCount + 3;
                startTotalSimplePoolCountAfter4 = startTotalSimplePoolCount + 2;
                break;
                
            default:
                startTotalSmartPoolCountAfter1 = startTotalSmartPoolCountAfter2 = startTotalSmartPoolCountAfter3 = startTotalSmartPoolCountAfter4;
                startTotalSimplePoolCountAfter1 = startTotalSimplePoolCountAfter2 = startTotalSimplePoolCountAfter3 = startTotalSimplePoolCountAfter4;
                break;
            }

            pds1 = SmartPoolDataSource.build(poolAppAuthDataSourceConfigurationOracle);

            assertEquals(startTotalSmartPoolCountAfter1, SmartPoolDataSource.getTotalSmartPoolCount());
            assertEquals(startTotalSimplePoolCountAfter1, SmartPoolDataSource.getTotalSimplePoolCount());

            pds2 = SmartPoolDataSource.build(poolAppOcppDataSourceConfigurationOracle); // not the same config as pds1
            assertEquals(startTotalSmartPoolCountAfter2, SmartPoolDataSource.getTotalSmartPoolCount());
            assertEquals(startTotalSimplePoolCountAfter2, SmartPoolDataSource.getTotalSimplePoolCount());

            pds3 = SmartPoolDataSource.build(poolAppOcppDataSourceConfigurationOracle); // same config as pds1
            assertEquals(startTotalSmartPoolCountAfter3, SmartPoolDataSource.getTotalSmartPoolCount());
            assertEquals(startTotalSimplePoolCountAfter3, SmartPoolDataSource.getTotalSimplePoolCount());

            checkSimplePoolDataSourceJoin(pds1, pds2, false);
            checkSimplePoolDataSourceJoin(pds2, pds3, true); // 2 == 3
            assertEquals(true, pds2 == pds3);
            checkSimplePoolDataSourceJoin(pds3, pds1, false);

            // change one property and create a smart pool data source: total pool count should increase
            final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle1 =
                poolAppAuthDataSourceConfigurationOracle
                .toBuilder()
                .validateConnectionOnBorrow(!poolAppAuthDataSourceConfigurationOracle.getValidateConnectionOnBorrow())
                .build();

            pds4 = SmartPoolDataSource.build(poolDataSourceConfigurationOracle1);
            assertEquals(startTotalSmartPoolCountAfter4, SmartPoolDataSource.getTotalSmartPoolCount());
            assertEquals(startTotalSimplePoolCountAfter4, SmartPoolDataSource.getTotalSimplePoolCount());

            assertNotEquals(pds1.getCommonPoolDataSource().getPoolDataSourceConfiguration(),
                            pds4.getCommonPoolDataSource().getPoolDataSourceConfiguration());

            assertEquals(false, pds4.isClosed());
            pds4.close();
            assertEquals(true, pds4.isClosed());

            assertEquals(false, pds3.isClosed());
            pds3.close();
            assertEquals(true, pds3.isClosed());
            
            assertEquals(true, pds2.isClosed()); // since pds2 == pds3, closing pds3 will also close pds2
            pds2.close();
            assertEquals(true, pds2.isClosed());
            
            assertEquals(false, pds1.isClosed());
            pds1.close();
            assertEquals(true, pds1.isClosed());
        }

        assertEquals(startTotalSmartPoolCountAfter4, SmartPoolDataSource.getTotalSmartPoolCount());
        assertEquals(startTotalSimplePoolCountAfter4, SmartPoolDataSource.getTotalSimplePoolCount());
    }

    private void checkSimplePoolDataSourceJoin(final SmartPoolDataSource pds1, final SmartPoolDataSource pds2, final boolean equal) {
        PoolDataSourceConfiguration poolDataSourceConfiguration1 = null;
        PoolDataSourceConfiguration poolDataSourceConfiguration2 = null;
            
        // check all fields
        poolDataSourceConfiguration1 = pds1.getCommonPoolDataSource().getPoolDataSourceConfiguration();
        poolDataSourceConfiguration2 = pds2.getCommonPoolDataSource().getPoolDataSourceConfiguration();

        assertEquals(true,
                     poolDataSourceConfiguration1.toString().equals(poolDataSourceConfiguration2.toString()));
        
        poolDataSourceConfiguration1 = pds1.getPoolDataSourceConfiguration();
        poolDataSourceConfiguration2 = pds2.getPoolDataSourceConfiguration();

        assertEquals(equal,
                     poolDataSourceConfiguration1.toString().equals(poolDataSourceConfiguration2.toString()));
        
        assertEquals(pds1.isStatisticsEnabled(), pds2.isStatisticsEnabled());
        assertEquals(pds1.isSingleSessionProxyModel(), pds2.isSingleSessionProxyModel());
        assertEquals(pds1.isUseFixedUsernamePassword(), pds2.isUseFixedUsernamePassword());
    }
}
