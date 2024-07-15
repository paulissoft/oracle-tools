package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
//import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

//import java.sql.SQLException;
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
@EnableConfigurationProperties({MyDomainDataSourceOracle.class, MyOperatorDataSourceOracle.class})
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryOracle.class})
@TestPropertySource("classpath:application-test.properties")
public class CheckLifeCycleOracleUnitTest {

    @Autowired
    @Qualifier("configDataSourceOracle4")
    private SmartPoolDataSourceOracle configDataSourceOracle;

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

    //=== Oracle ===

    @Disabled("A parent status must be OPEN.")
    @Test
    void testSimplePoolDataSourceOracleJoinTwice() {
        log.debug("testSimplePoolDataSourceOracleJoinTwice()");

        // do not use a try open block for the parent (configDataSourceOracle)
        // since it will close the pool data source giving problems for other tests
        final SmartPoolDataSourceOracle pds1 = configDataSourceOracle;
        
        PoolDataSourceConfigurationOracle pdsConfig = (PoolDataSourceConfigurationOracle) pds1.get();

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
        SmartPoolDataSourceOracle pds = null;
            
        try (final SmartPoolDataSourceOracle pds2 = new SmartPoolDataSourceOracle(pdsConfig)) {
            assertFalse(pds2.isOpen());
            pds2.open();
            assertTrue(pds2.isOpen());

            pdsConfig = (PoolDataSourceConfigurationOracle) pds1.get();
                    
            pdsConfig =
                pdsConfig
                .toBuilder() // copy
                .username(ocppDataSourceProperties.getUsername())
                .password(ocppDataSourceProperties.getPassword())
                .build();

            try (final SmartPoolDataSourceOracle pds3 = new SmartPoolDataSourceOracle(pdsConfig)) {
                assertFalse(pds3.isOpen());
                pds3.open();
                assertTrue(pds3.isOpen());

                checkSimplePoolDataSourceJoin(pds1, pds2, true);
                checkSimplePoolDataSourceJoin(pds2, pds3, true);
                checkSimplePoolDataSourceJoin(pds3, pds1, true);

                pdsConfig = (PoolDataSourceConfigurationOracle) pds1.get();

                // change one property and create a smart pool data source: total pool count should increase
                final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle1 =
                    pdsConfig
                    .toBuilder()
                    .validateConnectionOnBorrow(!pdsConfig.getValidateConnectionOnBorrow())
                    .build();

                try (final SmartPoolDataSourceOracle pds4 = new SmartPoolDataSourceOracle(poolDataSourceConfigurationOracle1)) {
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

    private void checkSimplePoolDataSourceJoin(final SmartPoolDataSourceOracle pds1, final SmartPoolDataSourceOracle pds2, final boolean equal) {
        PoolDataSourceConfiguration poolDataSourceConfiguration1 = null;
        PoolDataSourceConfiguration poolDataSourceConfiguration2 = null;
            
        // check all fields
        poolDataSourceConfiguration1 = pds1.get();
        poolDataSourceConfiguration2 = pds2.get();

        log.debug("poolDataSourceConfiguration1: {}", poolDataSourceConfiguration1);
        log.debug("poolDataSourceConfiguration2: {}", poolDataSourceConfiguration2);

        assertNotEquals(poolDataSourceConfiguration1.toString(), poolDataSourceConfiguration2.toString());
    }
}
