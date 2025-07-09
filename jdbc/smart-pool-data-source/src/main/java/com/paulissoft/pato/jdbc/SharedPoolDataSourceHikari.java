package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariPoolMXBean;
import com.zaxxer.hikari.metrics.MetricsTrackerFactory;
import java.sql.Connection;


// a package accessible class
class SharedPoolDataSourceHikari extends SharedPoolDataSource<HikariDataSource> {

    // constructor
    SharedPoolDataSourceHikari() {
        super(new HikariDataSource());
    }

    void setMetricRegistry(Object metricRegistry) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setMetricRegistry() while initializing.");
        }
        ds.setMetricRegistry(metricRegistry);
    }
    
    void setMetricsTrackerFactory(MetricsTrackerFactory metricsTrackerFactory) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setMetricsTrackerFactory() while initializing.");
        }
        ds.setMetricsTrackerFactory(metricsTrackerFactory);
    }

    void setHealthCheckRegistry(Object healthCheckRegistry) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setHealthCheckRegistry() while initializing.");
        }
        ds.setHealthCheckRegistry(healthCheckRegistry);
    }

    boolean isRunning() {
        return ds.isRunning();
    }

    HikariPoolMXBean getHikariPoolMXBean() {
        return ds.getHikariPoolMXBean();
    }

    HikariConfigMXBean getHikariConfigMXBean() {
        return ds.getHikariConfigMXBean();
    }

    void evictConnection(Connection connection) {
        ds.evictConnection(connection);
    }

    void setPassword(String password) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setPassword() while initializing.");
        }
        ds.setPassword(password);
    }
    
    void setUsername(String username) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setUsername() while initializing.");
        }
        ds.setUsername(username);
    }

    @Override
    void configure() {
        super.configure();
        
        ds.setMinimumIdle(members.stream().mapToInt(HikariDataSource::getMinimumIdle).sum());
        ds.setMaximumPoolSize(members.stream().mapToInt(HikariDataSource::getMaximumPoolSize).sum());

        // Must use lambda expressions below since primitives are used and
        // the functional interface does not support them all (boolean).
        
        // properties that may NOT differ, i.e. must be common

        // private String username;
        // just a check: no need to invoke ds.setUsername() since that has been done already in SmartPoolDataSourceHikari
        checkStringProperty((ds) -> ds.getUsername(),
                            "username");

        // private String catalog;
        configureStringProperty((ds) -> ds.getCatalog(),
                                (ds, value) -> ds.setCatalog(value),
                                "catalog");

        // private String connectionInitSql;
        configureStringProperty((ds) -> ds.getConnectionInitSql(),
                                (ds, value) -> ds.setConnectionInitSql(value),
                                "connection init sql");

        // private String dataSourceClassName;
        configureStringProperty((ds) -> ds.getDataSourceClassName(),
                                (ds, value) -> ds.setDataSourceClassName(value),
                                "data source class name");

        // private String dataSourceJNDI;
        configureStringProperty((ds) -> ds.getDataSourceJNDI(),
                                (ds, value) -> ds.setDataSourceJNDI(value),
                                "data source JNDI");

        // private String driverClassName;
        configureStringProperty((ds) -> ds.getDriverClassName(),
                                (ds, value) -> ds.setDriverClassName(value),
                                "driver class name");

        // private boolean allowPoolSuspension;
        configureBooleanProperty((ds) -> ds.isAllowPoolSuspension(),
                                 (ds, value) -> ds.setAllowPoolSuspension(value),
                                 "allow pool suspension");

        // private boolean autoCommit;
        configureBooleanProperty((ds) -> ds.isAutoCommit(),
                                 (ds, value) -> ds.setAutoCommit(value),
                                 "auto commit");
        
        // private long connectionTimeout;
        configureLongProperty((ds) -> ds.getConnectionTimeout(),
                              (ds, value) -> ds.setConnectionTimeout(value),
                              "connection timeout");

        // private long idleTimeout;
        configureLongProperty((ds) -> ds.getIdleTimeout(),
                              (ds, value) -> ds.setIdleTimeout(value),
                              "idle timeout");

        // private long initializationFailTimeout;
        configureLongProperty((ds) -> ds.getInitializationFailTimeout(),
                              (ds, value) -> ds.setInitializationFailTimeout(value),
                              "initialization fail timeout");

        // private String jdbcUrl;
        configureStringProperty((ds) -> ds.getJdbcUrl(),
                              (ds, value) -> ds.setJdbcUrl(value),
                              "JDBC URL");

        // private long maxLifetime;
        configureLongProperty((ds) -> ds.getMaxLifetime(),
                              (ds, value) -> ds.setMaxLifetime(value),
                              "max lifetime");

        // private boolean isolateInternalQueries;
        configureBooleanProperty((ds) -> ds.isIsolateInternalQueries(),
                                 (ds, value) -> ds.setIsolateInternalQueries(value),
                                 "isolate internal queries");

        // private boolean readOnly;
        configureBooleanProperty((ds) -> ds.isReadOnly(),
                                 (ds, value) -> ds.setReadOnly(value),
                                 "read only");

        // private boolean registerMbeans;
        configureBooleanProperty((ds) -> ds.isRegisterMbeans(),
                                 (ds, value) -> ds.setRegisterMbeans(value),
                                 "register Mbeans");

        // private String schema;
        configureStringProperty((ds) -> ds.getSchema(),
                              (ds, value) -> ds.setSchema(value),
                              "schema");

        // private String transactionIsolation;
        configureStringProperty((ds) -> ds.getTransactionIsolation(),
                              (ds, value) -> ds.setTransactionIsolation(value),
                              "transaction isolation");

        // private long validationTimeout;
        configureLongProperty((ds) -> ds.getValidationTimeout(),
                              (ds, value) -> ds.setValidationTimeout(value),
                              "validation timeout");

        // private long leakDetectionThreshold;
        configureLongProperty((ds) -> ds.getLeakDetectionThreshold(),
                              (ds, value) -> ds.setLeakDetectionThreshold(value),
                              "leak detection threshold");
    }

    void close() {
        ds.close();
        synchronized(this) {
            state = State.CLOSED;
        }
    }
}    
