package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariPoolMXBean;
import com.zaxxer.hikari.metrics.MetricsTrackerFactory;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.util.logging.Logger;


public class SmartPoolDataSourceHikari extends HikariDataSource {

    // this delegate will do the actual work
    private static final SharedPoolDataSourceHikari delegate = new SharedPoolDataSourceHikari();
    
    private volatile String schema = null;

    private volatile String proxyUsername = null;

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
    public void setLoginTimeout(int seconds) throws SQLException {
        delegate.setLoginTimeout(seconds);
    }

    @Override
    public int getLoginTimeout() throws SQLException {
        return delegate.getLoginTimeout();
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
    @Override
    public String toString();
    */

    /*
    // overridden methods from HikariConfig
    */

    /*
    @Override
    public void addDataSourceProperty(String propertyName, Object value);

    @Override
    public void addHealthCheckProperty(String key, String value);

    @Deprecated
    @Override
    public void copyState(HikariConfig other);

    @Override
    public void copyStateTo(HikariConfig other);

    @Override
    public String getCatalog();

    @Override
    public String getConnectionInitSql();
    */
    
    @Override
    public String getConnectionTestQuery() {
        return "alter session set current_schema = " + schema;
    }

    /*
    @Override
    public long getConnectionTimeout();

    @Override
    public javax.sql.DataSource getDataSource();

    @Override
    public String getDataSourceClassName();

    @Override
    public String getDataSourceJNDI();

    @Override
    public Properties getDataSourceProperties();

    @Override
    public String getDriverClassName();

    @Override
    public Properties getHealthCheckProperties();

    @Override
    public Object getHealthCheckRegistry();

    @Override
    public long getIdleTimeout();

    @Override
    public long getInitializationFailTimeout();

    @Override
    public String getJdbcUrl();

    @Override
    public long getLeakDetectionThreshold();

    @Override
    public int getMaximumPoolSize();

    @Override
    public long getMaxLifetime();

    @Override
    public Object getMetricRegistry();

    @Override
    public int getMinimumIdle();

    @Override
    public String getPassword();

    @Override
    public String getPoolName();

    @Override
    public ScheduledExecutorService getScheduledExecutor();

    @Deprecated
    @Override
    public ScheduledThreadPoolExecutor getScheduledExecutorService();

    @Override
    public String getSchema();

    @Override
    public ThreadFactory getThreadFactory();

    @Override
    public String getTransactionIsolation();

    @Override
    public String getUsername();

    @Override
    public long getValidationTimeout();

    @Override
    public boolean isAllowPoolSuspension();

    @Override
    public boolean isAutoCommit();

    @Deprecated
    @Override
    public boolean isInitializationFailFast();

    @Override
    public boolean isIsolateInternalQueries();

    @Deprecated
    @Override
    public boolean isJdbc4ConnectionTest();

    @Override
    public boolean isReadOnly();

    @Override
    public boolean isRegisterMbeans();

    @Override
    public void setAllowPoolSuspension(boolean isAllowPoolSuspension);

    @Override
    public void setAutoCommit(boolean isAutoCommit);

    @Override
    public void setCatalog(String catalog);

    @Override
    public void setConnectionInitSql(String connectionInitSql);
    */
    
    @Override
    public void setConnectionTestQuery(String connectionTestQuery) {
        try {
            // since getConnectionTestQuery is overridden it does not make sense to set it
            throw new SQLFeatureNotSupportedException("setConnectionTestQuery");            
        } catch (Exception ex) {
            throw new RuntimeException(String.format("%s: %s", ex.getClass().getName(), ex.getMessage()));
        }
    }

    /*
    @Override
    public void setConnectionTimeout(long connectionTimeoutMs);

    @Override
    public void setDataSource(javax.sql.DataSource dataSource);

    @Override
    public void setDataSourceClassName(String className);

    @Override
    public void setDataSourceJNDI(String jndiDataSource);

    @Override
    public void setDataSourceProperties(Properties dsProperties);

    @Override
    public void setDriverClassName(String driverClassName);

    @Override
    public void setHealthCheckProperties(Properties healthCheckProperties);

    @Override
    public void setHealthCheckRegistry(Object healthCheckRegistry);

    @Override
    public void setIdleTimeout(long idleTimeoutMs);

    @Deprecated
    @Override
    public void setInitializationFailFast(boolean failFast);

    @Override
    public void setInitializationFailTimeout(long initializationFailTimeout);

    @Override
    public void setIsolateInternalQueries(boolean isolate);

    @Deprecated
    @Override
    public void setJdbc4ConnectionTest(boolean useIsValid);

    @Override
    public void setJdbcUrl(String jdbcUrl);

    @Override
    public void setLeakDetectionThreshold(long leakDetectionThresholdMs);

    @Override
    public void setMaximumPoolSize(int maxPoolSize);

    @Override
    public void setMaxLifetime(long maxLifetimeMs);

    @Override
    public void setMetricRegistry(Object metricRegistry);

    @Override
    public void setMetricsTrackerFactory(MetricsTrackerFactory metricsTrackerFactory);

    @Override
    public void setMinimumIdle(int minIdle);
    */
    
    @Override
    public void setPassword(String password) {
        // Here we will set both the super and the delegate password so that the overridden getConnection() will always use
        // the same password no matter where it comes from.

        super.setPassword(password);
        delegate.setPassword(password);
    }

    /*
    @Override
    public void setPoolName(String poolName);

    @Override
    public void setReadOnly(boolean readOnly);

    @Override
    public void setRegisterMbeans(boolean register);

    @Override
    public void setScheduledExecutor(ScheduledExecutorService executor);

    @Deprecated
    @Override
    public void setScheduledExecutorService(ScheduledThreadPoolExecutor executor);

    @Override
    public void setSchema(String schema);

    @Override
    public void setThreadFactory(ThreadFactory threadFactory);

    @Override
    public void setTransactionIsolation(String isolationLevel);
    */
    
    @Override
    public void setUsername(String username) {
        // Here we will set both the super and the delegate username so that the overridden getConnection() will always use
        // the same password no matter where it comes from.

        synchronized(this) {
            if (username == null) {
                proxyUsername = schema = null;
            } else {
                final int pos1 = username.indexOf("[");
                final int pos2 = ( username.endsWith("]") ? username.length() - 1 : -1 );
      
                if (pos1 >= 0 && pos2 >= pos1) {
                    // a username like bc_proxy[bodomain]
                    proxyUsername = username.substring(0, pos1);
                    schema = username.substring(pos1+1, pos2);
                } else {
                    // a username like bodomain
                    proxyUsername = null;
                    schema = username;
                }
            }
        }

        super.setUsername(proxyUsername != null ? proxyUsername : schema);
        delegate.setUsername(proxyUsername != null ? proxyUsername : schema);

        // Add this object here (setUsername() should always be called) and
        // not in the constructor to prevent a this escape warning in the constructor.
        delegate.add(this);
    }

    /*
    @Override
    public void setValidationTimeout(long validationTimeoutMs);

    @Override
    public void validate();
    */
}
