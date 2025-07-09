package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariPoolMXBean;
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

    public void add(HikariDataSource ds) {
        members.add(ds);
    }

    public void remove(HikariDataSource ds) {
        members.remove(ds);
    }

    public Boolean contains(HikariDataSource ds) {
        return members.contains(ds);
    }

    public void configure() {
        if (members.isEmpty()) {
            throw new IllegalStateException("Members should have been added before you can configure.");
        }
        
        ds.setMinimumIdle(members.stream().mapToInt(HikariDataSource::getMinimumIdle).sum());
        ds.setMaximumPoolSize(members.stream().mapToInt(HikariDataSource::getMaximumPoolSize).sum());

        // properties that may NOT differ, i.e. must be common

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
        // 
        // private boolean readOnly;
        // 
        // private boolean registerMbeans;
        // 
        // private long validationTimeout;
        // 
        // private long leakDetectionThreshold;
        //
    }

    public Connection getConnection() throws SQLException {
        return ds.getConnection();
    }

    public Connection getConnection(String username, String password) throws SQLException {
        return ds.getConnection(username, password);
    }

}    
