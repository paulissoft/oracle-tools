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
        ds.setMinimumIdle(members.stream().mapToInt(HikariDataSource::getMinimumIdle).sum());
        ds.setMaximumPoolSize(members.stream().mapToInt(HikariDataSource::getMaximumPoolSize).sum());

        // properties that may NOT differ, i.e. must be common
        /*
        // private String dataSourceClassName;
        // 
        // private boolean autoCommit;
        // 
        // private long connectionTimeout;
        // 
        // private long idleTimeout;
        // 
        // private long maxLifetime;
        // 
        // private String connectionTestQuery;
        // 
        // private long initializationFailTimeout;
        // 
        // private boolean isolateInternalQueries;
        // 
        // private boolean allowPoolSuspension;
        // 
        // private boolean readOnly;
        // 
        // private boolean registerMbeans;
        // 
        // private long validationTimeout;
        // 
        // private long leakDetectionThreshold;
        */
    }

    public Connection getConnection() throws SQLException {
        return ds.getConnection();
    }

    public Connection getConnection(String username, String password) throws SQLException {
        return ds.getConnection(username, password);
    }

}    
