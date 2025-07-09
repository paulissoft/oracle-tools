package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariPoolMXBean;
import com.zaxxer.hikari.metrics.MetricsTrackerFactory;
import java.sql.Connection;
import java.util.Objects;
import java.util.stream.Collectors;


// a package accessible class
class SharedPoolDataSourceHikari extends SharedPoolDataSource<HikariDataSource> {
    private static final String USERNAMES_ERROR = "Not all usernames are the same and not null: %s.";

    private static final String DATA_SOURCE_CLASS_NAMES_ERROR = "Not all data source class names are the same: %s.";

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
	/*
	//  TO DO:
	//
	//  public String getCatalog();
	//
	//  public String getConnectionInitSql();
	//
	//  public String getConnectionTestQuery();
	//
	//  public long getConnectionTimeout();
	//
	//  public javax.sql.DataSource getDataSource();
	//
	//  public String getDataSourceClassName();
	//
	//  public String getDataSourceJNDI();
	//
	//  public Properties getDataSourceProperties();
	//
	//  public String getDriverClassName();
	//
	//  public Properties getHealthCheckProperties();
	//
	//  public Object getHealthCheckRegistry();
	//
	//  public long getIdleTimeout();
	//
	//  public long getInitializationFailTimeout();
	//
	//  public String getJdbcUrl();
	//
	//  public long getLeakDetectionThreshold();
	//
	//  public int getMaximumPoolSize();
	//
	//  public long getMaxLifetime();
	//
	//  public Object getMetricRegistry();
	//
	//  public int getMinimumIdle();
	//
	//  public String getPassword();
	//
	//  public String getPoolName();
	//
	//  public ScheduledExecutorService getScheduledExecutor();
	//
	//  public ScheduledThreadPoolExecutor getScheduledExecutorService();
	//
	//  public String getSchema();
	//
	//  public ThreadFactory getThreadFactory();
	//
	//  public String getTransactionIsolation();
	//
	//  public String getUsername();
	//
	//  public long getValidationTimeout();
	//
	//  public boolean isAllowPoolSuspension();
	//
	//  public boolean isAutoCommit();
	//
	//  public boolean isInitializationFailFast();
	//
	//  public boolean isIsolateInternalQueries();
	//
	//  public boolean isJdbc4ConnectionTest();
	//
	//  public boolean isReadOnly();
	//
	//  public boolean isRegisterMbeans();
	*/

        super.configure();
        
        ds.setMinimumIdle(members.stream().mapToInt(HikariDataSource::getMinimumIdle).sum());
        ds.setMaximumPoolSize(members.stream().mapToInt(HikariDataSource::getMaximumPoolSize).sum());

        // properties that may NOT differ, i.e. must be common

        // private String username;
        var streamUsername = members.stream().map(HikariDataSource::getUsername);

        // just a check: no need to invoke ds.setUsername() since that has been done already in SmartPoolDataSourceHikari
        if (!(streamUsername.filter(Objects::nonNull).count() == members.size() &&
              streamUsername.filter(Objects::nonNull).distinct().count() == 1)) {
            /* some null or not the same */
        } else {
            throw new IllegalStateException(String.format(USERNAMES_ERROR, streamUsername.collect(Collectors.toList()).toString()));
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
            throw new IllegalStateException(String.format(DATA_SOURCE_CLASS_NAMES_ERROR, streamDataSourceClassName.collect(Collectors.toList()).toString()));
        }

        // Must use lambda expressions below since primitives are used and
        // the functional interface does not support them all (boolean).
        
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

        // private long maxLifetime;
        configureLongProperty((ds) -> ds.getMaxLifetime(),
                              (ds, value) -> ds.setMaxLifetime(value),
                              "max lifetime");

        // private long initializationFailTimeout;
        configureLongProperty((ds) -> ds.getInitializationFailTimeout(),
                              (ds, value) -> ds.setInitializationFailTimeout(value),
                              "initialization fail timeout");

        // private boolean isolateInternalQueries;
        configureBooleanProperty((ds) -> ds.isIsolateInternalQueries(),
                                 (ds, value) -> ds.setIsolateInternalQueries(value),
                                 "isolate internal queries");

        // private boolean allowPoolSuspension;
        configureBooleanProperty((ds) -> ds.isAllowPoolSuspension(),
                                 (ds, value) -> ds.setAllowPoolSuspension(value),
                                 "allow pool suspension");

        // private boolean readOnly;
        configureBooleanProperty((ds) -> ds.isReadOnly(),
                                 (ds, value) -> ds.setReadOnly(value),
                                 "read only");

        // private boolean registerMbeans;
        configureBooleanProperty((ds) -> ds.isRegisterMbeans(),
                                 (ds, value) -> ds.setRegisterMbeans(value),
                                 "register Mbeans");

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
