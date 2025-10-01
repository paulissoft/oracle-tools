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
    // Overridden property setter/getter methods from HikariConfig/HikariDataSource used in SharedPoolDataSourceHikari.initialize()
    */

    @Override
    public int getMinimumIdle() {
        return isInitializing() ? super.getMinimumIdle() : delegate.ds.getMinimumIdle();
    }

    @Override
    public void setMinimumIdle(int minIdle) {
        checkInitializing("setMinimumIdle");
        super.setMinimumIdle(minIdle);
    }

    @Override
    public int getMaximumPoolSize() {
        return isInitializing() ? super.getMaximumPoolSize() : delegate.ds.getMaximumPoolSize();
    }

    @Override
    public void setMaximumPoolSize(int maxPoolSize) {
        checkInitializing("setMaximumPoolSize");
        super.setMaximumPoolSize(maxPoolSize);
    }
    
    @Override
    public String getUsername() {
        return isInitializing() ? super.getUsername() : delegate.ds.getUsername();
    }

    @Override
    public String getCatalog() {
        return isInitializing() ? super.getCatalog() : delegate.ds.getCatalog();
    }

    @Override
    public void setCatalog(String catalog) {
        checkInitializing("setCatalog");
        super.setCatalog(catalog);
    }

    @Override
    public String getConnectionInitSql() {
        return isInitializing() ? super.getConnectionInitSql() : delegate.ds.getConnectionInitSql();
    }

    @Override
    public void setConnectionInitSql(String connectionInitSql) {
        checkInitializing("setConnectionInitSql");
        super.setConnectionInitSql(connectionInitSql);
    }

    @Override
    public String getDataSourceClassName() {
        return isInitializing() ? super.getDataSourceClassName() : delegate.ds.getDataSourceClassName();
    }

    @Override
    public void setDataSourceClassName(String className) {
        checkInitializing("setDataSourceClassName");
        super.setDataSourceClassName(className);
    }

    @Override
    public String getDataSourceJNDI() {
        return isInitializing() ? super.getDataSourceJNDI() : delegate.ds.getDataSourceJNDI();
    }

    @Override
    public void setDataSourceJNDI(String jndiDataSource) {
        checkInitializing("setDataSourceJNDI");
        super.setDataSourceJNDI(jndiDataSource);
    }

    @Override
    public String getDriverClassName() {
        return isInitializing() ? super.getDriverClassName() : delegate.ds.getDriverClassName();
    }

    @Override
    public void setDriverClassName(String driverClassName) {
        checkInitializing("setDriverClassName");
        super.setDriverClassName(driverClassName);
    }

    @Override
    public boolean isAllowPoolSuspension() {
        return isInitializing() ? super.isAllowPoolSuspension() : delegate.ds.isAllowPoolSuspension();
    }

    @Override
    public void setAllowPoolSuspension(boolean isAllowPoolSuspension) {
        checkInitializing("setAllowPoolSuspension");
        super.setAllowPoolSuspension(isAllowPoolSuspension);
    }
    
    @Override
    public boolean isAutoCommit() {
        return isInitializing() ? super.isAutoCommit() : delegate.ds.isAutoCommit();
    }

    @Override
    public void setAutoCommit(boolean isAutoCommit) {
        checkInitializing("setAutoCommit");
        super.setAutoCommit(isAutoCommit);
    }

    @Override
    public long getConnectionTimeout() {
        return isInitializing() ? super.getConnectionTimeout() : delegate.ds.getConnectionTimeout();
    }
    
    @Override
    public void setConnectionTimeout(long connectionTimeoutMs) {
        checkInitializing("setConnectionTimeout");
        super.setConnectionTimeout(connectionTimeoutMs);
    }

    @Override
    public long getIdleTimeout() {
        return isInitializing() ? super.getIdleTimeout() : delegate.ds.getIdleTimeout();
    }

    @Override
    public void setIdleTimeout(long idleTimeoutMs) {
        checkInitializing("setIdleTimeout");
        super.setIdleTimeout(idleTimeoutMs);
    }

    @Override
    public long getInitializationFailTimeout() {
        return isInitializing() ? super.getInitializationFailTimeout() : delegate.ds.getInitializationFailTimeout();
    }
    
    @Override
    public void setInitializationFailTimeout(long initializationFailTimeout) {
        checkInitializing("setInitializationFailTimeout");
        super.setInitializationFailTimeout(initializationFailTimeout);
    }

    @Override
    public String getJdbcUrl() {
        return isInitializing() ? super.getJdbcUrl() : delegate.ds.getJdbcUrl();
    }

    @Override
    public void setJdbcUrl(String jdbcUrl) {
        checkInitializing("setJdbcUrl");
        super.setJdbcUrl(jdbcUrl);
    }

    @Override
    public long getMaxLifetime() {
        return isInitializing() ? super.getMaxLifetime() : delegate.ds.getMaxLifetime();
    }

    @Override
    public void setMaxLifetime(long maxLifetimeMs) {
        checkInitializing("setMaxLifetime");
        super.setMaxLifetime(maxLifetimeMs);
    }

    @Override
    public boolean isIsolateInternalQueries() {
        return isInitializing() ? super.isIsolateInternalQueries() : delegate.ds.isIsolateInternalQueries();
    }

    @Override
    public void setIsolateInternalQueries(boolean isolate) {
        checkInitializing("setIsolateInternalQueries");
        super.setIsolateInternalQueries(isolate);
    }

    @Override
    public boolean isReadOnly() {
        return isInitializing() ? super.isReadOnly() : delegate.ds.isReadOnly();
    }
    
    @Override
    public void setReadOnly(boolean readOnly) {
        checkInitializing("setReadOnly");
        super.setReadOnly(readOnly);
    }

    @Override
    public boolean isRegisterMbeans() {
        return isInitializing() ? super.isRegisterMbeans() : delegate.ds.isRegisterMbeans();
    }
    
    @Override
    public void setRegisterMbeans(boolean register) {
        checkInitializing("setRegisterMbeans");
        super.setRegisterMbeans(register);
    }

    @Override
    public String getSchema() {
        return isInitializing() ? super.getSchema() : delegate.ds.getSchema();
    }
    
    @Override
    public void setSchema(String schema) {
        checkInitializing("setSchema");
        super.setSchema(schema);
    }

    @Override
    public String getTransactionIsolation() {
        return isInitializing() ? super.getTransactionIsolation() : delegate.ds.getTransactionIsolation();
    }

    @Override
    public void setTransactionIsolation(String isolationLevel) {
        checkInitializing("setTransactionIsolation");
        super.setTransactionIsolation(isolationLevel);
    }

    @Override
    public long getValidationTimeout() {
        return isInitializing() ? super.getValidationTimeout() : delegate.ds.getValidationTimeout();
    }
    
    @Override
    public void setValidationTimeout(long validationTimeoutMs) {
        checkInitializing("setValidationTimeout");
        super.setValidationTimeout(validationTimeoutMs);
    }

    @Override
    public long getLeakDetectionThreshold() {
        return isInitializing() ? super.getLeakDetectionThreshold() : delegate.ds.getLeakDetectionThreshold();
    }

    @Override
    public void setLeakDetectionThreshold(long leakDetectionThresholdMs) {
        checkInitializing("setLeakDetectionThreshold");
        super.setLeakDetectionThreshold(leakDetectionThresholdMs);
    }
    
    /*
    // Other overridden methods from HikariDataSource
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
    public int getLoginTimeout() throws SQLException {
        return isInitializing() ? super.getLoginTimeout() : delegate.ds.getLoginTimeout();
    }

    @Override
    public void setLoginTimeout(int seconds) throws SQLException {
        checkInitializing("setLoginTimeout");
        super.setLoginTimeout(seconds);
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

    @Override
    public String getPoolName() {
        return isInitializing() ? super.getPoolName() : delegate.ds.getPoolName();
    }
    
    @Override
    public void setPoolName(String schema) {
        checkInitializing("setPoolName");
        super.setPoolName(schema);
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

