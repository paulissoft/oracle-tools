package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariPoolMXBean;
import com.zaxxer.hikari.metrics.MetricsTrackerFactory;
import java.io.Closeable;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.util.Properties;
import java.util.logging.Logger;
import javax.sql.DataSource;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ThreadFactory;

public class SmartPoolDataSourceHikari
    extends HikariDataSource
    implements ConnectInfo, Closeable, StatePoolDataSource, StatisticsPoolDataSource {

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
        return isInitializing() ? super.getLogWriter() : delegate.ds.getLogWriter();
    }

    @Override
    public void setLogWriter(PrintWriter out) throws SQLException {
        checkInitializing("setLogWriter");
        super.setLogWriter(out);
    }

    @Override
    public Logger getParentLogger() throws SQLFeatureNotSupportedException {
        return isInitializing() ? super.getParentLogger() : delegate.ds.getParentLogger();
    }

    @Override
    public <T> T unwrap(Class<T> iface) throws SQLException {
        return isInitializing() ? super.unwrap(iface) : delegate.ds.unwrap(iface);
    }

    @Override
    public boolean isWrapperFor(Class<?> iface) throws SQLException {
        return isInitializing() ? super.isWrapperFor(iface) : delegate.ds.isWrapperFor(iface);
    }

    @Override
    public boolean isRunning() {
        return isInitializing() ? super.isRunning() : delegate.ds.isRunning();
    }

    @Override
    public HikariPoolMXBean getHikariPoolMXBean() {
        return delegate.ds.getHikariPoolMXBean();
    }

    @Override
    public HikariConfigMXBean getHikariConfigMXBean() {
        return delegate.ds.getHikariConfigMXBean();
    }

    @Override
    public void evictConnection(Connection connection) {
        checkNotInitializing("evictConnection");
        delegate.ds.evictConnection(connection);
    }
    
    @Override
    public void close() {
        delegate.remove(this);
    }

    @Override
    public boolean isClosed() {
        return !delegate.members.contains(this) && ( delegate.isClosing() || delegate.isClosed() );
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
        checkInitializing("setPassword");

        // Here we will set both the super and the delegate password so that the overridden getConnection() will always use
        // the same password no matter where it comes from.

        super.setPassword(password);
        delegate.ds.setPassword(password);
    }

    @Override
    public void setUsername(String username) {
        checkInitializing("setUsername");
        
        // Here we will set both the super and the delegate username so that the overridden getConnection() will always use
        // the same password no matter where it comes from.
        var connectInfo = determineProxyUsernameAndCurrentDSchema(username);
        
        synchronized(this) {
            currentSchema = connectInfo[1];
        }

        super.setUsername(connectInfo[0] != null ? connectInfo[0] : connectInfo[1]);
        delegate.ds.setUsername(connectInfo[0] != null ? connectInfo[0] : connectInfo[1]);

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

    /*
    // Start of interface StatePoolDataSource
    */
    
    public boolean isInitializing() {
        return delegate.isInitializing();
    }

    public boolean hasInitializationError() {
        return delegate.hasInitializationError();
    }    
    
    public boolean isOpen() {
        return delegate.members.contains(this) && ( delegate.isOpen() || delegate.isClosing() );
    }

    // isClosed: see above
    
    /*
    // End of interface StatePoolDataSource
    */

    public int getActiveConnections() {
        try {
            return getHikariPoolMXBean().getActiveConnections();
        } catch (NullPointerException ex) {
            return -1;
        }
    }

    public int getIdleConnections() {
        try {
            return getHikariPoolMXBean().getIdleConnections();
        } catch (NullPointerException ex) {
            return -1;
        }
    }

    public int getTotalConnections() {
        try {
            return getHikariPoolMXBean().getTotalConnections();
        } catch (NullPointerException ex) {
            return -1;
        }
    }

    /*
    // Unsupported methods from interface HikariConfig
    */
  
    @Override
    public DataSource getDataSource() {
        try {
            throw new SQLFeatureNotSupportedException("getDataSource");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public void setDataSource(DataSource dataSource) {
        try {
            throw new SQLFeatureNotSupportedException("setDataSource");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public void addDataSourceProperty(String propertyName, Object value) {
        try {
            throw new SQLFeatureNotSupportedException("addDataSourceProperty");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public Properties getDataSourceProperties() {
        try {
            throw new SQLFeatureNotSupportedException("getDataSourceProperties");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public void setDataSourceProperties(Properties dsProperties) {
        try {
            throw new SQLFeatureNotSupportedException("setDataSourceProperties");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public MetricsTrackerFactory getMetricsTrackerFactory() {
        try {
            throw new SQLFeatureNotSupportedException("getMetricsTrackerFactory");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public void setMetricsTrackerFactory(MetricsTrackerFactory metricsTrackerFactory) {
        try {
            throw new SQLFeatureNotSupportedException("setMetricsTrackerFactory");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public Object getMetricRegistry() {
        try {
            throw new SQLFeatureNotSupportedException("getMetricRegistry");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public void setMetricRegistry(Object metricRegistry) {
        try {
            throw new SQLFeatureNotSupportedException("setMetricRegistry");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public Object getHealthCheckRegistry() {
        try {
            throw new SQLFeatureNotSupportedException("getHealthCheckRegistry");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public void setHealthCheckRegistry(Object healthCheckRegistry) {
        try {
            throw new SQLFeatureNotSupportedException("setHealthCheckRegistry");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public Properties getHealthCheckProperties() {
        try {
            throw new SQLFeatureNotSupportedException("getHealthCheckProperties");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public void setHealthCheckProperties(Properties healthCheckProperties) {
        try {
            throw new SQLFeatureNotSupportedException("setHealthCheckProperties");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public void addHealthCheckProperty(String key, String value) {
        try {
            throw new SQLFeatureNotSupportedException("addHealthCheckProperty");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public ScheduledExecutorService getScheduledExecutor() {
        try {
            throw new SQLFeatureNotSupportedException("getScheduledExecutor");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public void setScheduledExecutor(ScheduledExecutorService executor) {
        try {
            throw new SQLFeatureNotSupportedException("setScheduledExecutor");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public ThreadFactory getThreadFactory() {
        try {
            throw new SQLFeatureNotSupportedException("getThreadFactory");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public void setThreadFactory(ThreadFactory threadFactory) {
        try {
            throw new SQLFeatureNotSupportedException("setThreadFactory");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
  
    @Override
    public void copyStateTo(HikariConfig other) {
        try {
            throw new SQLFeatureNotSupportedException("copyStateTo");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
}

