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
@EnableConfigurationProperties({DataSourceConfiguration.class, PoolDataSourceConfiguration.class, PoolDataSourceConfigurationHikari.class})
@ContextConfiguration(classes = ConfigurationFactory.class)
@TestPropertySource("classpath:application-test.properties")
public class BindingPropertiesToBeanMethodsUnitTest {

    @Autowired
    @Qualifier("spring-datasource")
    private DataSourceConfiguration dataSourceConfiguration;

    @Autowired
    @Qualifier("app-auth-datasource-pool")
    private PoolDataSourceConfiguration poolDataSourceConfiguration;

    @Autowired
    @Qualifier("app-auth-datasource-hikari")
    private PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari;

    @Test
    void testDataSourceConfiguration() {
        assertEquals("oracle.jdbc.OracleDriver", dataSourceConfiguration.getDriverClassName());
        assertEquals("jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1", dataSourceConfiguration.getUrl());
        assertEquals("system", dataSourceConfiguration.getUsername());
        assertEquals("change_on_install", dataSourceConfiguration.getPassword());
        assertEquals(SimplePoolDataSourceHikari.class, dataSourceConfiguration.getType());
        assertEquals("DataSourceConfiguration(driverClassName=oracle.jdbc.OracleDriver, url=jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1, username=system, password=change_on_install, type=class com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari)", dataSourceConfiguration.toString());
    }
    
    @Test
    void testPoolDataSourceConfiguration() {
        // generic
        assertEquals(0, poolDataSourceConfiguration.getInitialPoolSize());
        assertEquals(10, poolDataSourceConfiguration.getMinPoolSize());
        assertEquals(20, poolDataSourceConfiguration.getMaxPoolSize());
        assertEquals("oracle.jdbc.pool.OracleDataSource", poolDataSourceConfiguration.getConnectionFactoryClassName());
        assertEquals("PoolDataSourceConfiguration(initialPoolSize=0, minPoolSize=10, maxPoolSize=20, connectionFactoryClassName=oracle.jdbc.pool.OracleDataSource)", poolDataSourceConfiguration.toString());
    }
    
    @Test
    void testPoolDataSourceConfigurationHikari() {
        // specific
        assertEquals(true, poolDataSourceConfigurationHikari.isAutoCommit());
        assertEquals(30000, poolDataSourceConfigurationHikari.getConnectionTimeout());
        assertEquals(600000, poolDataSourceConfigurationHikari.getIdleTimeout());
        assertEquals(1800000, poolDataSourceConfigurationHikari.getMaxLifetime());
        assertEquals("select 1 from dual", poolDataSourceConfigurationHikari.getConnectionTestQuery());
        assertEquals("HikariPool-boauth", poolDataSourceConfigurationHikari.getPoolName());
        assertEquals(60, poolDataSourceConfigurationHikari.getMinimumIdle());
        assertEquals(1, poolDataSourceConfigurationHikari.getInitializationFailTimeout());
        assertEquals(false, poolDataSourceConfigurationHikari.isIsolateInternalQueries());
        assertEquals(false, poolDataSourceConfigurationHikari.isAllowPoolSuspension());
        assertEquals(false, poolDataSourceConfigurationHikari.isReadOnly());
        assertEquals(false, poolDataSourceConfigurationHikari.isRegisterMbeans());
        assertEquals(5000, poolDataSourceConfigurationHikari.getValidationTimeout());
        assertEquals(0, poolDataSourceConfigurationHikari.getLeakDetectionThreshold());
        assertEquals("PoolDataSourceConfigurationHikari(autoCommit=true, connectionTimeout=30000, idleTimeout=600000, maxLifetime=1800000, connectionTestQuery=select 1 from dual, maximumPoolSize=60, poolName=HikariPool-boauth, minimumIdle=60, initializationFailTimeout=1, isolateInternalQueries=false, allowPoolSuspension=false, readOnly=false, registerMbeans=false, validationTimeout=5000, leakDetectionThreshold=0)", poolDataSourceConfigurationHikari.toString());
    }
}
