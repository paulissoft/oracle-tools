package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariPoolMXBean;
import com.zaxxer.hikari.metrics.MetricsTrackerFactory;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.sql.SQLTransientConnectionException;
import java.util.Properties;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.ThreadFactory;
import java.util.logging.Logger;
import javax.sql.DataSource;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.Objects;


// a package accessible class
class SharedPoolDataSourceHikari {
    final static HikariDataSource ds = new HikariDataSource();

    final static CopyOnWriteArrayList<HikariDataSource> members = new CopyOnWriteArrayList<>();

    public static void add(HikariDataSource member) {
        members.add(member);
    }

    public static void remove(HikariDataSource member) {
        members.remove(member);
    }

    public static Boolean contains(HikariDataSource member) {
        return members.contains(member);
    }

    public static void configure() {
        if (members.isEmpty()) {
            throw new IllegalStateException("Members should have been added before you can configure.");
        }
        
        ds.setMinimumIdle(members.stream().mapToInt(HikariDataSource::getMinimumIdle).sum());
        ds.setMaximumPoolSize(members.stream().mapToInt(HikariDataSource::getMaximumPoolSize).sum());

        // properties that may NOT differ, i.e. must be common

        // private String username;
        var streamUsername = members.stream().map(HikariDataSource::getUsername);

        if (!(streamUsername.filter(Objects::nonNull).count() == members.size() &&
              streamUsername.filter(Objects::nonNull).distinct().count() == 1)) {
            /* some null or not the same */
        } else {
            throw new IllegalStateException(String.format("Not all usernames are the same and not null: %s", streamUsername.collect(Collectors.toList()).toString()));
        }

        // private String dataSourceClassName;
        var streamDataSourceClassName = members.stream().map(HikariDataSource::getDataSourceClassName);

        if (streamDataSourceClassName.filter(Objects::isNull).count() == members.size()) {
            /* all null */
            ds.setDataSourceClassName(null);
        } else if (streamDataSourceClassName.filter(Objects::nonNull).count() == members.size() &&
                   streamDataSourceClassName.filter(Objects::nonNull).distinct().count() == 1) {
            /* all not null and the same */
            ds.setDataSourceClassName(members.get(0).getDataSourceClassName());
        } else {
            throw new IllegalStateException(String.format("Not all data source class names are the same: %s", streamDataSourceClassName.collect(Collectors.toList()).toString()));
        }

        // private boolean autoCommit;
        var streamAutoCommit = members.stream().map(HikariDataSource::isAutoCommit);

        if (streamAutoCommit.distinct().count() == 1) {
            /* all the same */
            ds.setAutoCommit(members.get(0).isAutoCommit());
        } else {
            throw new IllegalStateException(String.format("Not all auto commit values are the same: %s", streamAutoCommit.collect(Collectors.toList()).toString()));
        }
        
        // private long connectionTimeout;
        var streamConnectionTimeout = members.stream().map(HikariDataSource::getConnectionTimeout);

        if (streamConnectionTimeout.distinct().count() == 1) {
            /* all the same */
            ds.setConnectionTimeout(members.get(0).getConnectionTimeout());
        } else {
            throw new IllegalStateException(String.format("Not all connection timeout values are the same: %s", streamConnectionTimeout.collect(Collectors.toList()).toString()));
        }

        // private long idleTimeout;
        var streamIdleTimeout = members.stream().map(HikariDataSource::getIdleTimeout);

        if (streamIdleTimeout.distinct().count() == 1) {
            /* all the same */
            ds.setIdleTimeout(members.get(0).getIdleTimeout());
        } else {
            throw new IllegalStateException(String.format("Not all idle timeout values are the same: %s", streamIdleTimeout.collect(Collectors.toList()).toString()));
        }

        // private long maxLifetime;
        var streamMaxLifetime = members.stream().map(HikariDataSource::getMaxLifetime);

        if (streamMaxLifetime.distinct().count() == 1) {
            /* all the same */
            ds.setMaxLifetime(members.get(0).getMaxLifetime());
        } else {
            throw new IllegalStateException(String.format("Not all max lifetime values are the same: %s", streamMaxLifetime.collect(Collectors.toList()).toString()));
        }

        // private long initializationFailTimeout;
        var streamInitializationFailTimeout = members.stream().map(HikariDataSource::getInitializationFailTimeout);

        if (streamInitializationFailTimeout.distinct().count() == 1) {
            /* all the same */
            ds.setInitializationFailTimeout(members.get(0).getInitializationFailTimeout());
        } else {
            throw new IllegalStateException(String.format("Not all initialization fail timeout values are the same: %s", streamInitializationFailTimeout.collect(Collectors.toList()).toString()));
        }

        // private boolean isolateInternalQueries;
        var streamIsolateInternalQueries = members.stream().map(HikariDataSource::isIsolateInternalQueries);

        if (streamIsolateInternalQueries.distinct().count() == 1) {
            /* all the same */
            ds.setIsolateInternalQueries(members.get(0).isIsolateInternalQueries());
        } else {
            throw new IllegalStateException(String.format("Not all isolate internal queries values are the same: %s", streamIsolateInternalQueries.collect(Collectors.toList()).toString()));
        }

        // private boolean allowPoolSuspension;
        var streamAllowPoolSuspension = members.stream().map(HikariDataSource::isAllowPoolSuspension);

        if (streamAllowPoolSuspension.distinct().count() == 1) {
            /* all the same */
            ds.setAllowPoolSuspension(members.get(0).isAllowPoolSuspension());
        } else {
            throw new IllegalStateException(String.format("Not all allow pool suspension values are the same: %s", streamAllowPoolSuspension.collect(Collectors.toList()).toString()));
        }

        // private boolean readOnly;
        var streamReadOnly = members.stream().map(HikariDataSource::isReadOnly);

        if (streamReadOnly.distinct().count() == 1) {
            /* all the same */
            ds.setReadOnly(members.get(0).isReadOnly());
        } else {
            throw new IllegalStateException(String.format("Not all read only values are the same: %s", streamReadOnly.collect(Collectors.toList()).toString()));
        }

        // private boolean registerMbeans;
        var streamRegisterMbeans = members.stream().map(HikariDataSource::isRegisterMbeans);

        if (streamRegisterMbeans.distinct().count() == 1) {
            /* all the same */
            ds.setRegisterMbeans(members.get(0).isRegisterMbeans());
        } else {
            throw new IllegalStateException(String.format("Not all register Mbeans values are the same: %s", streamRegisterMbeans.collect(Collectors.toList()).toString()));
        }

        // private long validationTimeout;
        var streamValidationTimeout = members.stream().map(HikariDataSource::getValidationTimeout);

        if (streamValidationTimeout.distinct().count() == 1) {
            /* all the same */
            ds.setValidationTimeout(members.get(0).getValidationTimeout());
        } else {
            throw new IllegalStateException(String.format("Not all validation timeout values are the same: %s", streamValidationTimeout.collect(Collectors.toList()).toString()));
        }

        // private long leakDetectionThreshold;
        var streamLeakDetectionThreshold = members.stream().map(HikariDataSource::getLeakDetectionThreshold);

        if (streamLeakDetectionThreshold.distinct().count() == 1) {
            /* all the same */
            ds.setLeakDetectionThreshold(members.get(0).getLeakDetectionThreshold());
        } else {
            throw new IllegalStateException(String.format("Not all leak detection threshold values are the same: %s", streamLeakDetectionThreshold.collect(Collectors.toList()).toString()));
        }

    }

    public static Connection getConnection() throws SQLException {
        return ds.getConnection();
    }

    public static Connection getConnection(String username, String password) throws SQLException {
        return ds.getConnection(username, password);
    }

    public static PrintWriter getLogWriter() throws SQLException {
        return ds.getLogWriter();
    }

    public static void setLogWriter(PrintWriter out) throws SQLException {
        ds.setLogWriter(out);
    }

    public static void setLoginTimeout(int seconds) throws SQLException {
        ds.setLoginTimeout(seconds);
    }

    public static int getLoginTimeout() throws SQLException {
        return ds.getLoginTimeout();
    }

    public static Logger getParentLogger() throws SQLFeatureNotSupportedException {
        return ds.getParentLogger();
    }

    public static <T> T unwrap(Class<T> iface) throws SQLException {
        return ds.unwrap(iface);
    }

    public static boolean isWrapperFor(Class<?> iface) throws SQLException {
        return ds.isWrapperFor(iface);
    }

    public static void setMetricRegistry(Object metricRegistry) {
        ds.setMetricRegistry(metricRegistry);
    }
    
    public static void setMetricsTrackerFactory(MetricsTrackerFactory metricsTrackerFactory) {
        ds.setMetricsTrackerFactory(metricsTrackerFactory);
    }

    public static void setHealthCheckRegistry(Object healthCheckRegistry) {
        ds.setHealthCheckRegistry(healthCheckRegistry);
    }

    public static boolean isRunning() {
        return ds.isRunning();
    }

    public static HikariPoolMXBean getHikariPoolMXBean() {
        return ds.getHikariPoolMXBean();
    }

    public static HikariConfigMXBean getHikariConfigMXBean() {
        return ds.getHikariConfigMXBean();
    }

    public static void evictConnection(Connection connection) {
        ds.evictConnection(connection);
    }

    public static void setPassword(String password) {
        ds.setPassword(password);
    }
    
    public static void setUsername(String username) {
        ds.setUsername(username);
    }
}    
