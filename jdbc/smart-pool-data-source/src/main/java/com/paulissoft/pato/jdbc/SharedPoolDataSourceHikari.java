package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariPoolMXBean;
import com.zaxxer.hikari.metrics.MetricsTrackerFactory;
import java.sql.Connection;
import java.sql.SQLException;


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
    void initialize() {
        super.initialize();

        initializeIntProperty(HikariDataSource::getMinimumIdle,
                              HikariDataSource::setMinimumIdle,
                              "minimum idle",
                              true);

        initializeIntProperty(HikariDataSource::getMaximumPoolSize,
                              HikariDataSource::setMaximumPoolSize,
                              "maximum pool size",
                              true);

        // Must use lambda expressions for methods with primitive arguments or return values
        // since the functional interface does not support them all (boolean).
        // But auto-boxing handles this implicitly.
        
        // properties that may NOT differ, i.e. must be common

        // just a check: no need to invoke ds.setUsername() since that has been done already via SmartPoolDataSourceHikari.setUsername().
        checkStringProperty(HikariDataSource::getUsername, "username");

        initializeStringProperty(HikariDataSource::getCatalog, HikariDataSource::setCatalog, "catalog");

        initializeStringProperty(HikariDataSource::getConnectionInitSql, HikariDataSource::setConnectionInitSql, "connection init sql");

        initializeStringProperty(HikariDataSource::getDataSourceClassName, HikariDataSource::setDataSourceClassName, "data source class name");

        initializeStringProperty(HikariDataSource::getDataSourceJNDI, HikariDataSource::setDataSourceJNDI, "data source JNDI");

        initializeStringProperty(HikariDataSource::getDriverClassName, HikariDataSource::setDriverClassName, "driver class name");

        initializeBooleanProperty((ds) -> ds.isAllowPoolSuspension(),
                                  (ds, value) -> ds.setAllowPoolSuspension(value),
                                  "allow pool suspension");

        initializeBooleanProperty((ds) -> ds.isAutoCommit(),
                                  (ds, value) -> ds.setAutoCommit(value),
                                  "auto commit");
        
        initializeLongProperty((ds) -> ds.getConnectionTimeout(),
                               (ds, value) -> ds.setConnectionTimeout(value),
                               "connection timeout");

        initializeLongProperty((ds) -> ds.getIdleTimeout(),
                               (ds, value) -> ds.setIdleTimeout(value),
                               "idle timeout");

        initializeLongProperty((ds) -> ds.getInitializationFailTimeout(),
                               (ds, value) -> ds.setInitializationFailTimeout(value),
                               "initialization fail timeout");

        initializeStringProperty(HikariDataSource::getJdbcUrl, HikariDataSource::setJdbcUrl, "JDBC URL");

        // The functional interface does not allow checked exceptions so convert them into a RuntimeException (unchecked).
        initializeIntProperty((ds) -> { try { return ds.getLoginTimeout(); } catch (SQLException ex) { throw new RuntimeException(ex); } },
                              (ds, value) -> { try { ds.setLoginTimeout(value); } catch (SQLException ex) { throw new RuntimeException(ex); } },
                              "login timeout");

        initializeLongProperty((ds) -> ds.getMaxLifetime(),
                               (ds, value) -> ds.setMaxLifetime(value),
                               "max lifetime");

        initializeBooleanProperty((ds) -> ds.isIsolateInternalQueries(),
                                  (ds, value) -> ds.setIsolateInternalQueries(value),
                                  "isolate internal queries");

        initializeBooleanProperty((ds) -> ds.isReadOnly(),
                                  (ds, value) -> ds.setReadOnly(value),
                                  "read only");

        initializeBooleanProperty((ds) -> ds.isRegisterMbeans(),
                                  (ds, value) -> ds.setRegisterMbeans(value),
                                  "register Mbeans");

        initializeStringProperty(HikariDataSource::getSchema, HikariDataSource::setSchema, "schema");

        initializeStringProperty(HikariDataSource::getTransactionIsolation, HikariDataSource::setTransactionIsolation, "transaction isolation");

        initializeLongProperty((ds) -> ds.getValidationTimeout(),
                               (ds, value) -> ds.setValidationTimeout(value),
                               "validation timeout");

        initializeLongProperty((ds) -> ds.getLeakDetectionThreshold(),
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
