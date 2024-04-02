package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

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
@ContextConfiguration(classes = ConfigurationFactoryOracle.class)
@TestPropertySource("classpath:application-test.properties")
public class CheckConfigurationOracleUnitTest {

    @Autowired
    @Qualifier("spring-datasource")
    private PoolDataSourceConfiguration poolDataSourceConfiguration;

    @Autowired
    @Qualifier("app-auth-datasource")
    private PoolDataSourceConfiguration poolDataSourceConfigurationAuth;

    @Autowired
    @Qualifier("app-ocpp-datasource")
    private PoolDataSourceConfiguration poolDataSourceConfigurationOcpp;

    @Autowired
    @Qualifier("app-domain-datasource")
    private PoolDataSourceConfiguration poolDataSourceConfigurationDomain;

    @Autowired
    @Qualifier("app-auth-datasource-oracle")
    private PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle;

    @BeforeAll
    static void clear() {
        SmartPoolDataSource.clear();
        CombiPoolDataSource.clear();
    }

    @Test
    void testPoolDataSourceConfigurationCommonId() {
        PoolDataSourceConfigurationCommonId idAuth, idOcpp, idDomain;
        
        final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracleCopy =
            poolDataSourceConfigurationOracle.toBuilder().build();

        poolDataSourceConfigurationOracleCopy.copyFrom(poolDataSourceConfigurationAuth);
        idAuth = new PoolDataSourceConfigurationCommonId(poolDataSourceConfigurationOracleCopy);
        
        poolDataSourceConfigurationOracleCopy.copyFrom(poolDataSourceConfigurationOcpp);
        idOcpp = new PoolDataSourceConfigurationCommonId(poolDataSourceConfigurationOracleCopy);

        poolDataSourceConfigurationOracleCopy.copyFrom(poolDataSourceConfigurationDomain);
        idDomain = new PoolDataSourceConfigurationCommonId(poolDataSourceConfigurationOracleCopy);

        log.debug("idAuth: {}", idAuth);
        log.debug("idOcpp: {}", idOcpp);
        log.debug("idDomain: {}", idDomain);
        
        assertTrue(idAuth.equals(idOcpp));
        assertTrue(idAuth.equals(idDomain)); // for UCP a different user to logon to is ignored
    }

    //=== Oracle ===

    @Test
    void testPoolDataSourceConfigurationOracle() {
        poolDataSourceConfigurationOracle.copyFrom(poolDataSourceConfiguration);

        assertEquals("common-pool", poolDataSourceConfigurationOracle.getConnectionPoolName());
        assertEquals(0, poolDataSourceConfigurationOracle.getInitialPoolSize());
        assertEquals(10, poolDataSourceConfigurationOracle.getMinPoolSize());
        assertEquals(20, poolDataSourceConfigurationOracle.getMaxPoolSize());
        assertEquals("oracle.jdbc.pool.OracleDataSource", poolDataSourceConfigurationOracle.getConnectionFactoryClassName());
        assertEquals(true, poolDataSourceConfigurationOracle.getValidateConnectionOnBorrow());
        assertEquals(120, poolDataSourceConfigurationOracle.getAbandonedConnectionTimeout());
        assertEquals(120, poolDataSourceConfigurationOracle.getTimeToLiveConnectionTimeout());
        assertEquals(0, poolDataSourceConfigurationOracle.getInactiveConnectionTimeout());
        assertEquals(30, poolDataSourceConfigurationOracle.getTimeoutCheckInterval());
        assertEquals(10, poolDataSourceConfigurationOracle.getMaxStatements());
        assertEquals(3, poolDataSourceConfigurationOracle.getConnectionWaitTimeout());
        assertEquals(0, poolDataSourceConfigurationOracle.getMaxConnectionReuseTime());
        assertEquals(120, poolDataSourceConfigurationOracle.getSecondsToTrustIdleConnection());
        assertEquals(15, poolDataSourceConfigurationOracle.getConnectionValidationTimeout());
        assertEquals("PoolDataSourceConfigurationOracle(super=PoolDataSourceConfiguration(driverClassName=null, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=system, password=change_on_install, " +
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceOracle), connectionPoolName=common-pool, initialPoolSize=0, " +
                     "minPoolSize=10, maxPoolSize=20, connectionFactoryClassName=oracle.jdbc.pool.OracleDataSource, validateConnectionOnBorrow=true, " +
                     "abandonedConnectionTimeout=120, timeToLiveConnectionTimeout=120, inactiveConnectionTimeout=0, timeoutCheckInterval=30, " +
                     "maxStatements=10, connectionWaitTimeout=3, maxConnectionReuseTime=0, secondsToTrustIdleConnection=120, connectionValidationTimeout=15)",
                     poolDataSourceConfigurationOracle.toString());

        poolDataSourceConfigurationOracle = poolDataSourceConfigurationOracle.toBuilder().password("null").timeToLiveConnectionTimeout(100).build();
        assertEquals("PoolDataSourceConfigurationOracle(super=PoolDataSourceConfiguration(driverClassName=null, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=system, password=null, " +
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceOracle), connectionPoolName=common-pool, initialPoolSize=0, " +
                     "minPoolSize=10, maxPoolSize=20, connectionFactoryClassName=oracle.jdbc.pool.OracleDataSource, validateConnectionOnBorrow=true, " +
                     "abandonedConnectionTimeout=120, timeToLiveConnectionTimeout=100, inactiveConnectionTimeout=0, timeoutCheckInterval=30, " +
                     "maxStatements=10, connectionWaitTimeout=3, maxConnectionReuseTime=0, secondsToTrustIdleConnection=120, connectionValidationTimeout=15)",
                     poolDataSourceConfigurationOracle.toString());
    }

    @Test
    void testDefaultSimplePoolDataSourceOracle() throws SQLException {
        final SimplePoolDataSourceOracle pds = SimplePoolDataSourceOracle.build(new PoolDataSourceConfigurationOracle());
            
        assertEquals("PoolDataSourceConfigurationOracle(super=PoolDataSourceConfiguration(driverClassName=null, " +
                     "url=null, username=null, password=null, " +
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceOracle), connectionPoolName=null, initialPoolSize=0, " +
                     "minPoolSize=0, maxPoolSize=0, connectionFactoryClassName=, validateConnectionOnBorrow=false, " +
                     "abandonedConnectionTimeout=0, timeToLiveConnectionTimeout=0, inactiveConnectionTimeout=0, timeoutCheckInterval=0, " +
                     "maxStatements=0, connectionWaitTimeout=0, maxConnectionReuseTime=0, secondsToTrustIdleConnection=0, connectionValidationTimeout=0)",
                     pds.getPoolDataSourceConfiguration().toString());
    }

    @Test
    void testSimplePoolDataSourceOracleJoinTwice() throws SQLException {
        poolDataSourceConfigurationOracle.copyFrom(poolDataSourceConfiguration);

        log.debug("testSimplePoolDataSourceOracleJoinTwice()");
        log.debug("poolDataSourceConfigurationOracle.getType(): {}", poolDataSourceConfigurationOracle.getType());
        
        assertEquals(SimplePoolDataSourceOracle.class, poolDataSourceConfigurationOracle.getType());

        final int startTotalSmartPoolCount = SmartPoolDataSource.getTotalSmartPoolCount();
        final int startTotalSimplePoolCount = SmartPoolDataSource.getTotalSimplePoolCount();
        final SmartPoolDataSource pds1 = SmartPoolDataSource.build(poolDataSourceConfigurationOracle);

        assertEquals(startTotalSmartPoolCount + 1, SmartPoolDataSource.getTotalSmartPoolCount());
        assertEquals(startTotalSimplePoolCount + 1, SmartPoolDataSource.getTotalSimplePoolCount());

        final SmartPoolDataSource pds2 = SmartPoolDataSource.build(poolDataSourceConfigurationOracle); // same config

        assertEquals(startTotalSmartPoolCount + 1, SmartPoolDataSource.getTotalSmartPoolCount());
        assertEquals(startTotalSimplePoolCount + 1, SmartPoolDataSource.getTotalSimplePoolCount());

        final SmartPoolDataSource pds3 = SmartPoolDataSource.build(poolDataSourceConfigurationOracle); // same config

        assertEquals(startTotalSmartPoolCount + 1, SmartPoolDataSource.getTotalSmartPoolCount());
        assertEquals(startTotalSimplePoolCount + 1, SmartPoolDataSource.getTotalSimplePoolCount());
            
        checkSimplePoolDataSourceJoinTwice(pds1, pds2);
        checkSimplePoolDataSourceJoinTwice(pds2, pds3);
        checkSimplePoolDataSourceJoinTwice(pds3, pds1);

        // change one property and create a smart pool data source: total pool count should increase
        final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle1 =
            poolDataSourceConfigurationOracle
            .toBuilder()
            .validateConnectionOnBorrow(!poolDataSourceConfigurationOracle.getValidateConnectionOnBorrow())
            .build();
        final SmartPoolDataSource pds4 = SmartPoolDataSource.build(poolDataSourceConfigurationOracle1);

        assertEquals(startTotalSmartPoolCount + 2, SmartPoolDataSource.getTotalSmartPoolCount());
        assertEquals(startTotalSimplePoolCount + 2, SmartPoolDataSource.getTotalSimplePoolCount());
        
        assertNotEquals(pds1.getCommonPoolDataSource().getPoolDataSourceConfiguration(),
                        pds4.getCommonPoolDataSource().getPoolDataSourceConfiguration());
    }

    private void checkSimplePoolDataSourceJoinTwice(final SmartPoolDataSource pds1, final SmartPoolDataSource pds2) {
        PoolDataSourceConfiguration poolDataSourceConfiguration1 = null;
        PoolDataSourceConfiguration poolDataSourceConfiguration2 = null;
            
        // check all fields
        poolDataSourceConfiguration1 = pds1.getCommonPoolDataSource().getPoolDataSourceConfiguration();
        poolDataSourceConfiguration2 = pds2.getCommonPoolDataSource().getPoolDataSourceConfiguration();

        assertEquals(poolDataSourceConfiguration1.toString(),
                     poolDataSourceConfiguration2.toString());
        
        assertEquals(pds1.isStatisticsEnabled(), pds2.isStatisticsEnabled());
        assertEquals(pds1.isSingleSessionProxyModel(), pds2.isSingleSessionProxyModel());
        assertEquals(pds1.isFixedUsernamePassword(), pds2.isFixedUsernamePassword());
    }
}
