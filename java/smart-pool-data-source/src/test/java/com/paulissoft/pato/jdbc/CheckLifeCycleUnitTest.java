package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

import java.sql.SQLException;
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
    @Qualifier("app-auth-datasource-hikari")
    private PoolDataSourceConfigurationHikari poolAppAuthDataSourceConfigurationHikari;

    @Autowired
    @Qualifier("app-ocpp-datasource")
    private PoolDataSourceConfiguration poolAppOcppDataSourceConfiguration;

    @Autowired
    @Qualifier("app-ocpp-datasource-hikari")
    private PoolDataSourceConfigurationHikari poolAppOcppDataSourceConfigurationHikari;

    //=== Hikari ===

    @Test
    void testSimplePoolDataSourceHikariJoinTwice() throws SQLException {
        poolAppAuthDataSourceConfigurationHikari.copy(poolAppAuthDataSourceConfiguration);
        poolAppOcppDataSourceConfigurationHikari.copy(poolAppOcppDataSourceConfiguration);

        log.debug("testSimplePoolDataSourceHikariJoinTwice()");

        final int startTotalSmartPoolCount = SmartPoolDataSource.getTotalSmartPoolCount();
        final int startTotalSimplePoolCount = SmartPoolDataSource.getTotalSimplePoolCount();
        final SmartPoolDataSource pds1 = SmartPoolDataSource.build(poolAppAuthDataSourceConfigurationHikari);

        assertEquals(startTotalSmartPoolCount + 1, SmartPoolDataSource.getTotalSmartPoolCount());
        assertEquals(startTotalSimplePoolCount + 1, SmartPoolDataSource.getTotalSimplePoolCount());

        final SmartPoolDataSource pds2 = SmartPoolDataSource.build(poolAppOcppDataSourceConfigurationHikari); // not the same config as pds1

        assertEquals(startTotalSmartPoolCount + 2, SmartPoolDataSource.getTotalSmartPoolCount());
        assertEquals(startTotalSimplePoolCount + 1, SmartPoolDataSource.getTotalSimplePoolCount());

        final SmartPoolDataSource pds3 = SmartPoolDataSource.build(poolAppOcppDataSourceConfigurationHikari); // same config as pds1

        assertEquals(startTotalSmartPoolCount + 2, SmartPoolDataSource.getTotalSmartPoolCount());
        assertEquals(startTotalSimplePoolCount + 1, SmartPoolDataSource.getTotalSimplePoolCount());

        checkSimplePoolDataSourceJoin(pds1, pds2, false);
        checkSimplePoolDataSourceJoin(pds2, pds3, true); // 2 == 3
        checkSimplePoolDataSourceJoin(pds3, pds1, false);

        // change one property and create a smart pool data source: total pool count should increase
        final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari1 =
            poolAppAuthDataSourceConfigurationHikari
            .toBuilder()
            .autoCommit(!poolAppAuthDataSourceConfigurationHikari.isAutoCommit())
            .build();
        final SmartPoolDataSource pds4 = SmartPoolDataSource.build(poolDataSourceConfigurationHikari1);

        assertEquals(startTotalSmartPoolCount + 3, SmartPoolDataSource.getTotalSmartPoolCount());
        assertEquals(startTotalSimplePoolCount + 2, SmartPoolDataSource.getTotalSimplePoolCount());

        assertNotEquals(pds1.getCommonPoolDataSource().getPoolDataSourceConfiguration(),
                        pds4.getCommonPoolDataSource().getPoolDataSourceConfiguration());
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
