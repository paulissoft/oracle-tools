package com.paulissoft.pato.jdbc;

//import static org.junit.jupiter.api.Assertions.assertEquals;
//import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

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
public class CheckConnectionUnitTest {

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
    void testConnection() throws SQLException {
        log.debug("testConnection()");

        // auth
        poolAppAuthDataSourceConfigurationHikari.copy(poolAppAuthDataSourceConfiguration);
        poolAppAuthDataSourceConfigurationOracle.copy(poolAppAuthDataSourceConfiguration);

        // ocpp
        poolAppOcppDataSourceConfigurationHikari.copy(poolAppOcppDataSourceConfiguration);
        poolAppOcppDataSourceConfigurationOracle.copy(poolAppOcppDataSourceConfiguration);

        SmartPoolDataSource pds1, pds2, pds3, pds4;

        // these two will be combined
        pds1 = SmartPoolDataSource.build(poolAppAuthDataSourceConfigurationHikari);
        pds2 = SmartPoolDataSource.build(poolAppOcppDataSourceConfigurationHikari);

        assertTrue(pds1 == pds2); // do not use assertEquals(pds1, pds2) since equals() is overridden

        // these two will be combined
        pds3 = SmartPoolDataSource.build(poolAppAuthDataSourceConfigurationOracle);
        pds4 = SmartPoolDataSource.build(poolAppOcppDataSourceConfigurationOracle);

        assertTrue(pds3 == pds4);

        assertFalse(pds1 == pds3);

        // issue come connections
        assertNotNull(pds1.getConnection());
        assertNotNull(pds3.getConnection());

        // close pds4 (and thus indirectly pds3)
        assertFalse(pds4.isClosed());
        pds4.close();
        assertTrue(pds4.isClosed());

        final String rex = "^Smart pool data source \(.+\) must be open.$";
        IllegalStateException thrown = assertThrows(IllegalStateException.class, () -> pds3.getConnection());

        assertTrue(thrown.getMessage().matches(rex));

        assertTrue(pds3.isClosed()); // since pds3 == pds4, closing pds3 will also close pds2
        pds3.close();
        assertTrue(pds3.isClosed());

        // close pds2 (and thus indirectly pds1)
        assertFalse(pds2.isClosed());
        pds2.close();
        assertTrue(pds2.isClosed());

        thrown = assertThrows(IllegalStateException.class, () -> pds1.getConnection());
        assertTrue(thrown.getMessage().matches(rex));
            
        assertTrue(pds1.isClosed()); // since pds1 == pds2, closing pds3 will also close pds2
        pds1.close();
        assertTrue(pds1.isClosed());
    }
}
