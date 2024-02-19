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

@ExtendWith(SpringExtension.class)
@EnableConfigurationProperties({PoolDataSourceConfiguration.class, PoolDataSourceConfiguration.class, PoolDataSourceConfigurationHikari.class})
@ContextConfiguration(classes = ConfigurationFactory.class)
@TestPropertySource("classpath:application-test.properties")
public class CheckConfigurationUnitTest {

    @Autowired
    @Qualifier("spring-datasource")
    private PoolDataSourceConfiguration poolDataSourceConfiguration;

    @Autowired
    @Qualifier("app-auth-datasource-hikari")
    private PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari;

    @Autowired
    @Qualifier("app-auth-datasource-oracle")
    private PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle;

    @Test
    void testPoolDataSourceConfiguration() {
        assertEquals("oracle.jdbc.OracleDriver", poolDataSourceConfiguration.getDriverClassName());
        assertEquals("jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1", poolDataSourceConfiguration.getUrl());
        assertEquals("system", poolDataSourceConfiguration.getUsername());
        assertEquals("change_on_install", poolDataSourceConfiguration.getPassword());
        assertEquals(SimplePoolDataSourceHikari.class, poolDataSourceConfiguration.getType());
        assertEquals("PoolDataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, " +
                     "username=system, password=change_on_install, type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari)",
                     poolDataSourceConfiguration.toString());
    }
    
    //=== Hikari ===

    @Test
    void testPoolDataSourceConfigurationHikari() {
        poolDataSourceConfigurationHikari.copy(poolDataSourceConfiguration);
        assertEquals("HikariPool-boauth", poolDataSourceConfigurationHikari.getPoolName());
        assertEquals(60, poolDataSourceConfigurationHikari.getMaximumPoolSize());
        assertEquals(60, poolDataSourceConfigurationHikari.getMinimumIdle());
        assertEquals(null, poolDataSourceConfigurationHikari.getDataSourceClassName());
        assertEquals(true, poolDataSourceConfigurationHikari.isAutoCommit());
        assertEquals(30000, poolDataSourceConfigurationHikari.getConnectionTimeout());
        assertEquals(600000, poolDataSourceConfigurationHikari.getIdleTimeout());
        assertEquals(1800000, poolDataSourceConfigurationHikari.getMaxLifetime());
        assertEquals("select 1 from dual", poolDataSourceConfigurationHikari.getConnectionTestQuery());
        assertEquals(1, poolDataSourceConfigurationHikari.getInitializationFailTimeout());
        assertEquals(false, poolDataSourceConfigurationHikari.isIsolateInternalQueries());
        assertEquals(false, poolDataSourceConfigurationHikari.isAllowPoolSuspension());
        assertEquals(false, poolDataSourceConfigurationHikari.isReadOnly());
        assertEquals(false, poolDataSourceConfigurationHikari.isRegisterMbeans());
        assertEquals(5000, poolDataSourceConfigurationHikari.getValidationTimeout());
        assertEquals(0, poolDataSourceConfigurationHikari.getLeakDetectionThreshold());
        assertEquals("PoolDataSourceConfigurationHikari(super=PoolDataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=system, password=change_on_install, " +
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari), poolName=HikariPool-boauth, " +
                     "maximumPoolSize=60, minimumIdle=60, dataSourceClassName=null, autoCommit=true, connectionTimeout=30000, " +
                     "idleTimeout=600000, maxLifetime=1800000, connectionTestQuery=select 1 from dual, initializationFailTimeout=1, " +
                     "isolateInternalQueries=false, allowPoolSuspension=false, readOnly=false, registerMbeans=false, " +
                     "validationTimeout=5000, leakDetectionThreshold=0)",
                     poolDataSourceConfigurationHikari.toString());

        final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikariCopy =
            poolDataSourceConfigurationHikari.toBuilder().username(null).poolName("").autoCommit(false).build();

        assertEquals("PoolDataSourceConfigurationHikari(super=PoolDataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=null, password=change_on_install, " +
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari), poolName=, " +
                     "maximumPoolSize=60, minimumIdle=60, dataSourceClassName=null, autoCommit=false, connectionTimeout=30000, " +
                     "idleTimeout=600000, maxLifetime=1800000, connectionTestQuery=select 1 from dual, initializationFailTimeout=1, " +
                     "isolateInternalQueries=false, allowPoolSuspension=false, readOnly=false, registerMbeans=false, " +
                     "validationTimeout=5000, leakDetectionThreshold=0)",
                     poolDataSourceConfigurationHikariCopy.toString());
    }

    @Test
    void testDefaultSimplePoolDataSourceHikari() {
        final SimplePoolDataSourceHikari pds = new SimplePoolDataSourceHikari(new PoolDataSourceConfigurationHikari());

        assertEquals("PoolDataSourceConfigurationHikari(super=PoolDataSourceConfiguration(driverClassName=null, " +
                     "url=null, username=null, password=null, " +
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari), poolName=null, " +
                     "maximumPoolSize=-1, minimumIdle=0, dataSourceClassName=null, autoCommit=false, connectionTimeout=2147483647, " +
                     "idleTimeout=0, maxLifetime=0, connectionTestQuery=null, initializationFailTimeout=0, " +
                     "isolateInternalQueries=false, allowPoolSuspension=false, readOnly=false, registerMbeans=false, " +
                     "validationTimeout=5000, leakDetectionThreshold=0)",
                     pds.getPoolDataSourceConfiguration().toString());
    }

    @Test
    void testSimplePoolDataSourceHikariJoinTwice() throws SQLException {
        poolDataSourceConfigurationHikari.copy(poolDataSourceConfiguration);

        final int startTotalPoolCount = SmartPoolDataSource.getTotalPoolCount();
        final SmartPoolDataSource pds1 = SmartPoolDataSource.build(poolDataSourceConfigurationHikari);

        assertEquals(startTotalPoolCount + 1, SmartPoolDataSource.getTotalPoolCount());

        final SmartPoolDataSource pds2 = SmartPoolDataSource.build(poolDataSourceConfigurationHikari); // same config

        assertEquals(startTotalPoolCount + 1, SmartPoolDataSource.getTotalPoolCount());

        final SmartPoolDataSource pds3 = SmartPoolDataSource.build(poolDataSourceConfigurationHikari); // same config

        assertEquals(startTotalPoolCount + 1, SmartPoolDataSource.getTotalPoolCount());

        checkSimplePoolDataSourceJoinTwice(pds1, pds2);
        checkSimplePoolDataSourceJoinTwice(pds2, pds3);
        checkSimplePoolDataSourceJoinTwice(pds3, pds1);

        // change one property and create a smart pool data source: total pool count should increase
        final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari1 =
            poolDataSourceConfigurationHikari
            .toBuilder()
            .autoCommit(!poolDataSourceConfigurationHikari.isAutoCommit())
            .build();
        final SmartPoolDataSource pds4 = SmartPoolDataSource.build(poolDataSourceConfigurationHikari1);

        assertEquals(startTotalPoolCount + 2, SmartPoolDataSource.getTotalPoolCount());

        assertNotEquals(pds1.getCommonPoolDataSource().getPoolDataSourceConfiguration(),
                        pds4.getCommonPoolDataSource().getPoolDataSourceConfiguration());
    }

    //=== Oracle ===

    @Test
    void testPoolDataSourceConfigurationOracle() {
        poolDataSourceConfigurationOracle.copy(poolDataSourceConfiguration);

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
        assertEquals("PoolDataSourceConfigurationOracle(super=PoolDataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=system, password=change_on_install, " +
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari), connectionPoolName=common-pool, initialPoolSize=0, " +
                     "minPoolSize=10, maxPoolSize=20, connectionFactoryClassName=oracle.jdbc.pool.OracleDataSource, validateConnectionOnBorrow=true, " +
                     "abandonedConnectionTimeout=120, timeToLiveConnectionTimeout=120, inactiveConnectionTimeout=0, timeoutCheckInterval=30, " +
                     "maxStatements=10, connectionWaitTimeout=3, maxConnectionReuseTime=0, secondsToTrustIdleConnection=120, connectionValidationTimeout=15)",
                     poolDataSourceConfigurationOracle.toString());

        poolDataSourceConfigurationOracle = poolDataSourceConfigurationOracle.toBuilder().password("null").timeToLiveConnectionTimeout(100).build();
        assertEquals("PoolDataSourceConfigurationOracle(super=PoolDataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, " +
                     "url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=system, password=null, " +
                     "type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari), connectionPoolName=common-pool, initialPoolSize=0, " +
                     "minPoolSize=10, maxPoolSize=20, connectionFactoryClassName=oracle.jdbc.pool.OracleDataSource, validateConnectionOnBorrow=true, " +
                     "abandonedConnectionTimeout=120, timeToLiveConnectionTimeout=100, inactiveConnectionTimeout=0, timeoutCheckInterval=30, " +
                     "maxStatements=10, connectionWaitTimeout=3, maxConnectionReuseTime=0, secondsToTrustIdleConnection=120, connectionValidationTimeout=15)",
                     poolDataSourceConfigurationOracle.toString());
    }

    @Test
    void testDefaultSimplePoolDataSourceOracle() throws SQLException {
        final SimplePoolDataSourceOracle pds = new SimplePoolDataSourceOracle(new PoolDataSourceConfigurationOracle());
            
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
        poolDataSourceConfigurationOracle.copy(poolDataSourceConfiguration);

        final int startTotalPoolCount = SmartPoolDataSource.getTotalPoolCount();
        final SmartPoolDataSource pds1 = SmartPoolDataSource.build(poolDataSourceConfigurationOracle);

        assertEquals(startTotalPoolCount + 1, SmartPoolDataSource.getTotalPoolCount());

        final SmartPoolDataSource pds2 = SmartPoolDataSource.build(poolDataSourceConfigurationOracle); // same config

        assertEquals(startTotalPoolCount + 1, SmartPoolDataSource.getTotalPoolCount());

        final SmartPoolDataSource pds3 = SmartPoolDataSource.build(poolDataSourceConfigurationOracle); // same config

        assertEquals(startTotalPoolCount + 1, SmartPoolDataSource.getTotalPoolCount());
            
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

        assertEquals(startTotalPoolCount + 2, SmartPoolDataSource.getTotalPoolCount());
        
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
        assertEquals(pds1.isUseFixedUsernamePassword(), pds2.isUseFixedUsernamePassword());
    }
}
