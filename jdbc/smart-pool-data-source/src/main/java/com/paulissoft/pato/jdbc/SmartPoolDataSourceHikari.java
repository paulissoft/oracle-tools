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
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.ThreadFactory;
import java.util.logging.Logger;
import javax.sql.DataSource;

@Slf4j
public class SmartPoolDataSourceHikari extends HikariDataSource {

    final static HikariDataSource delegate = new HikariDataSource();

    private volatile static SmartPoolDataSourceHikari first = null; // only the first smart pool datasource created ever can set properties, the rest must have the same

    // overridden methods from HikariDataSource
    
    public HikariDataSource() {
        super();

        if (first == null) {
            synchronized(first) {
                first = this;
            }
        }
    }

    public HikariDataSource(HikariConfig configuration);

    @Override
    public Connection getConnection() throws SQLException;

    @Override
    public Connection getConnection(String username, String password) throws SQLException;
    
    @Override
    public PrintWriter getLogWriter() throws SQLException;

    @Override
    public void setLogWriter(PrintWriter out) throws SQLException;

    @Override
    public void setLoginTimeout(int seconds) throws SQLException;

    @Override
    public int getLoginTimeout() throws SQLException;

    @Override
    public Logger getParentLogger() throws SQLFeatureNotSupportedException;

    @Override
    public <T> T unwrap(Class<T> iface) throws SQLException;

    @Override
    public boolean isWrapperFor(Class<?> iface) throws SQLException;

    @Override
    public void setMetricRegistry(Object metricRegistry);
    
    @Override
    public void setMetricsTrackerFactory(MetricsTrackerFactory metricsTrackerFactory);

    @Override
    public void setHealthCheckRegistry(Object healthCheckRegistry);

    @Override
    public boolean isRunning();

    @Override
    public HikariPoolMXBean getHikariPoolMXBean();

    @Override
    public HikariConfigMXBean getHikariConfigMXBean();

    @Override
    public void evictConnection(Connection connection);

    @Deprecated
    @Override
    public void suspendPool();

    @Deprecated
    @Override
    public void resumePool();

    @Override
    public void close();

    @Override
    public boolean isClosed();

    @Deprecated
    @Override
    public void shutdown();

    @Override
    public String toString();    

    // overridden methods from HikariConfig

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

    @Override
    public String getConnectionTestQuery();

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

    @Override
    public void setConnectionTestQuery(String connectionTestQuery);

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

    @Override
    public void setPassword(String password);

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

    @Override
    public void setUsername(String username);

    @Override
    public void setValidationTimeout(long validationTimeoutMs);

    @Override
    public void validate();
}
