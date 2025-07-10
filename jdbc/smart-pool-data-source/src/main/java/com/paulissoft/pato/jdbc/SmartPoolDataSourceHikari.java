package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariPoolMXBean;
import com.zaxxer.hikari.metrics.MetricsTrackerFactory;
import java.io.Closeable;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.util.logging.Logger;


public class SmartPoolDataSourceHikari extends HikariDataSource implements ConnectInfo, Closeable {

    // this delegate will do the actual work
    private static final SharedPoolDataSourceHikari delegate = new SharedPoolDataSourceHikari();
    
    private volatile String currentSchema = null;

    /*
    // overridden methods from HikariDataSource
    */
    
    @Override
    public Connection getConnection() throws SQLException {
        return delegate.getConnection();
    }

    @Override
    public Connection getConnection(String username, String password) throws SQLException {
        return delegate.getConnection(username, password);
    }
    
    @Override
    public PrintWriter getLogWriter() throws SQLException {
        return delegate.getLogWriter();
    }

    @Override
    public void setLogWriter(PrintWriter out) throws SQLException {
        delegate.setLogWriter(out);
    }

    @Override
    public Logger getParentLogger() throws SQLFeatureNotSupportedException {
        return delegate.getParentLogger();
    }

    @Override
    public <T> T unwrap(Class<T> iface) throws SQLException {
        return delegate.unwrap(iface);
    }

    @Override
    public boolean isWrapperFor(Class<?> iface) throws SQLException {
        return delegate.isWrapperFor(iface);
    }

    @Override
    public void setMetricRegistry(Object metricRegistry) {
        delegate.setMetricRegistry(metricRegistry);
    }
    
    @Override
    public void setMetricsTrackerFactory(MetricsTrackerFactory metricsTrackerFactory) {
        delegate.setMetricsTrackerFactory(metricsTrackerFactory);
    }

    @Override
    public void setHealthCheckRegistry(Object healthCheckRegistry) {
        delegate.setHealthCheckRegistry(healthCheckRegistry);
    }

    @Override
    public boolean isRunning() {
        return delegate.isRunning();
    }

    @Override
    public HikariPoolMXBean getHikariPoolMXBean() {
        return delegate.getHikariPoolMXBean();
    }

    @Override
    public HikariConfigMXBean getHikariConfigMXBean() {
        return delegate.getHikariConfigMXBean();
    }

    @Override
    public void evictConnection(Connection connection) {
        delegate.evictConnection(connection);
    }
    
    @Override
    public void close() {
        delegate.remove(this);
    }

    @Override
    public boolean isClosed() {
        return !delegate.contains(this);
    }

    /*
    // overridden methods from HikariConfig
    */

    @Override
    public String getConnectionTestQuery() {
        return getSQLAlterSessionSetCurrentSchema();
    }
    
    @Override
    public void setConnectionTestQuery(String connectionTestQuery) {
        try {
            // since getConnectionTestQuery is overridden it does not make sense to set it
            throw new SQLFeatureNotSupportedException("setConnectionTestQuery");            
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setPassword(String password) {
        // Here we will set both the super and the delegate password so that the overridden getConnection() will always use
        // the same password no matter where it comes from.

        super.setPassword(password);
        delegate.setPassword(password);
    }

    @Override
    public void setUsername(String username) {
        // Here we will set both the super and the delegate username so that the overridden getConnection() will always use
        // the same password no matter where it comes from.
        var connectInfo = determineProxyUsernameAndCurrentDSchema(username);
        
        synchronized(this) {
            currentSchema = connectInfo[1];
        }

        super.setUsername(connectInfo[0] != null ? connectInfo[0] : connectInfo[1]);
        delegate.setUsername(connectInfo[0] != null ? connectInfo[0] : connectInfo[1]);

        // Add this object here (setUsername() should always be called) and
        // not in the constructor to prevent a this escape warning in the constructor.
        delegate.add(this);
    }

    /*
    // Interface ConnectInfo
    */
    public String getCurrentSchema() {
        return currentSchema;
    }
}
