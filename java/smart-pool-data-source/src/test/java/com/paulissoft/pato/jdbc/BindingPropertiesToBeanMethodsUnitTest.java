package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;

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
public class BindingPropertiesToBeanMethodsUnitTest {

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
        assertEquals("PoolDataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=system, password=change_on_install, type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari)", poolDataSourceConfiguration.toString());
    }
    
    @Test
    void testPoolDataSourceConfigurationHikari() {
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
        assertEquals("PoolDataSourceConfigurationHikari(super=PoolDataSourceConfiguration(driverClassName=null, url=null, username=null, password=null, type=null), poolName=HikariPool-boauth, maximumPoolSize=60, minimumIdle=60, dataSourceClassName=null, autoCommit=true, connectionTimeout=30000, idleTimeout=600000, maxLifetime=1800000, connectionTestQuery=select 1 from dual, initializationFailTimeout=1, isolateInternalQueries=false, allowPoolSuspension=false, readOnly=false, registerMbeans=false, validationTimeout=5000, leakDetectionThreshold=0)", poolDataSourceConfigurationHikari.toString());
    }
}
