package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import java.util.Properties;
import java.util.concurrent.atomic.AtomicBoolean;
import lombok.extern.slf4j.Slf4j;
import oracle.jdbc.OracleConnection;

@Slf4j
public class SimplePoolDataSourceHikari
    extends HikariDataSource
    implements SimplePoolDataSource, PoolDataSourcePropertiesSettersHikari, PoolDataSourcePropertiesGettersHikari {

    // all static related

    static final long MIN_CONNECTION_TIMEOUT = 250; // milliseconds for one pool, so twice this number for two

    private static final String POOL_NAME_PREFIX = "HikariPool";

    private static final PoolDataSourceStatistics poolDataSourceStatisticsTotal =
        new PoolDataSourceStatistics(() -> POOL_NAME_PREFIX + ": (all)",
                                     PoolDataSourceStatistics.poolDataSourceStatisticsGrandTotal);

    // all object related

    private final StringBuffer id = new StringBuffer();

    protected final PoolDataSourceStatistics poolDataSourceStatistics;

    private final AtomicBoolean hasShownConfig = new AtomicBoolean(false);

    // constructors
    public SimplePoolDataSourceHikari() {
        poolDataSourceStatistics = 
            new PoolDataSourceStatistics(null, // description will be the pool name
                                         poolDataSourceStatisticsTotal, 
                                         this::isClosed,
                                         this::getWithPoolName);
        setId(this.getClass().getSimpleName());
    }

    public SimplePoolDataSourceHikari(final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari) {
        this();
        set(poolDataSourceConfigurationHikari);
    }
    
    @Override
    public Connection getConnection() throws SQLException {
        Connection conn = null;
        final boolean isStatisticsEnabled = poolDataSourceStatistics != null && SimplePoolDataSource.isStatisticsEnabled();
        final boolean isInitializing = !hasShownConfig.getAndSet(true);
        
        if (isStatisticsEnabled) {
            final Instant tm = Instant.now();
            
            try {
                conn = super.getConnection();
            } catch (SQLException se) {
                poolDataSourceStatistics.signalSQLException(this, se);
                throw se;
            } catch (Exception ex) {
                poolDataSourceStatistics.signalException(this, ex);
                throw ex;
            }

            poolDataSourceStatistics.updateStatistics(this,
                                                      conn,
                                                      Duration.between(tm, Instant.now()).toMillis(),
                                                      true);
        } else {
            conn = super.getConnection();
        }

        if (isInitializing) {
            // Only show the first time a pool has gotten a connection.
            // Not earlier because these (fixed) values may change before and after the first connection.
            show(get());

            if (isStatisticsEnabled) {
                poolDataSourceStatistics.showStatistics();
            }
        }

        return conn;
    }

    // get a connection for the multi-session proxy model
    //
    // @param usernameToConnectTo  provided by pool data source that needs the overflow pool data source to connect to schema
    //                             via a proxy session through username (e.g. bc_proxy[bodomain])
    // @param password             provided by pool data source that needs the overflow pool data source to connect to schema
    //                             via a proxy session through with this password
    // @param schema               provided by pool data source that needs the overflow pool data source to connect to schema
    //                             via a proxy session (e.g. bodomain)
    public Connection getConnection(final String usernameToConnectTo,
                                    final String password,
                                    final String schema,
                                    final int refCount) throws SQLException {
        log.debug(">getConnection(id={}, usernameToConnectTo={}, schema={})",
                  getId(), usernameToConnectTo, schema);

        Connection conn = null;
        final boolean isStatisticsEnabled = poolDataSourceStatistics != null && SimplePoolDataSource.isStatisticsEnabled();
        final boolean isInitializing = !hasShownConfig.getAndSet(true);
        final int maxProxyLogicalConnectionCount = refCount - 1; // only relevant when there are more than 1 shared pool data sources
        final Instant tm0 = Instant.now();
        Instant tm1 = null;
        int proxyLogicalConnectionCount = 0;
        int proxyOpenSessionCount = 0;
        int proxyCloseSessionCount = 0;
        final String proxyUsername = usernameToConnectTo;
        final Connection[] connectionsWithWrongSchema =
            maxProxyLogicalConnectionCount > 0 ? new Connection[maxProxyLogicalConnectionCount] : null;
        int nrProxyLogicalConnectionCount = 0;
        boolean found;

        try {
            while (true) {
                conn = super.getConnection(); // username will be bc_proxy when it is a new physical connection

                found = conn.getSchema().equalsIgnoreCase(schema);

                if (found || nrProxyLogicalConnectionCount >= maxProxyLogicalConnectionCount || getIdleConnections() == 0) {
                    break;
                } else {
                    // !found && nrProxyLogicalConnectionCount < maxProxyLogicalConnectionCount && getIdleConnections() > 0

                    connectionsWithWrongSchema[nrProxyLogicalConnectionCount++] = conn;
                
                    proxyLogicalConnectionCount++;
                }
            }

            log.debug("before proxy session - current schema: {}",
                      conn.getSchema());

            // if the current schema is not the requested schema try to open/close the proxy session
            if (!found) {
                tm1 = Instant.now();
                
                OracleConnection oraConn = null;

                try {
                    if (conn.isWrapperFor(OracleConnection.class)) {
                        oraConn = conn.unwrap(OracleConnection.class);
                    }
                } catch (SQLException ex) {
                    oraConn = null;
                }

                if (oraConn != null) {
                    int nr = 0;

                    log.debug("before open proxy session - current schema: {}; is proxy session: {}",
                              conn.getSchema(),
                              oraConn.isProxySession());
                    
                    do {                    
                        switch(nr) {
                        case 0:
                            if (!conn.getSchema().equalsIgnoreCase(proxyUsername) /*oraConn.isProxySession()*/) {
                                // go back to the session with the first username
                                try {
                                    oraConn.close(OracleConnection.PROXY_SESSION);
                                    
                                    proxyCloseSessionCount++;
                                } catch (SQLException ex) {
                                    log.warn("SQL warning: {}", ex.getMessage());
                                }
                                oraConn.setSchema(proxyUsername);
                            }
                            break;
                            
                        case 1:
                            if (!proxyUsername.equals(schema)) {
                                // open a proxy session with the second username
                                final Properties proxyProperties = new Properties();

                                proxyProperties.setProperty(OracleConnection.PROXY_USER_NAME, schema);
                                oraConn.openProxySession(OracleConnection.PROXYTYPE_USER_NAME, proxyProperties);
                                oraConn.setSchema(schema);
                                
                                proxyOpenSessionCount++;
                            }
                            break;
                            
                        case 2:
                            oraConn.setSchema(schema);
                            break;
                            
                        default:
                            throw new IllegalArgumentException(String.format("Wrong value for nr (%d): must be between 0 and 2", nr));
                        }

                        log.debug("after open proxy session (#{}) - current schema: {}; is proxy session: {}",
                                  nr,
                                  conn.getSchema(),
                                  oraConn.isProxySession());
                    } while (!conn.getSchema().equalsIgnoreCase(schema) && nr++ < 3);
                }
            }

            log.debug("after proxy session - current schema: {}",
                      conn.getSchema());
        } catch (SQLException se) {
            if (isStatisticsEnabled) {
                poolDataSourceStatistics.signalSQLException(this, se);
            }
            throw se;
        } catch (Exception ex) {
            if (isStatisticsEnabled) {
                poolDataSourceStatistics.signalException(this, ex);
            }
            throw ex;
        } finally {
            while (nrProxyLogicalConnectionCount > 0) {
                try {
                    connectionsWithWrongSchema[--nrProxyLogicalConnectionCount].close();
                } catch (SQLException ex) {
                    log.error("SQL exception on close(): {}", ex);
                }
            }
            log.debug("<getConnection(id={})", getId());
        }
        
        if (isStatisticsEnabled) {
            if (tm1 == null) {
                poolDataSourceStatistics.updateStatistics(this,
                                                          conn,
                                                          Duration.between(tm0, Instant.now()).toMillis(),
                                                          true);
            } else {
                poolDataSourceStatistics.updateStatistics(this,
                                                          conn,
                                                          Duration.between(tm0, tm1).toMillis(),
                                                          Duration.between(tm1, Instant.now()).toMillis(),
                                                          true,
                                                          proxyLogicalConnectionCount,
                                                          proxyOpenSessionCount,
                                                          proxyCloseSessionCount);
            }
        }

        if (isInitializing) {
            // Only show the first time a pool has gotten a connection.
            // Not earlier because these (fixed) values may change before and after the first connection.
            show(get());

            if (isStatisticsEnabled) {
                poolDataSourceStatistics.showStatistics();
            }
        }

        return conn;
    }

    public String getPoolNamePrefix() {
        return POOL_NAME_PREFIX;
    }

    public void setId(final String srcId) {
        SimplePoolDataSource.setId(id, String.format("0x%08x", hashCode())/*(long) System.identityHashCode(this)/*VM.current().addressOf(this)*/, srcId);
    }

    public String getId() {
        return id.toString();
    }

    public void set(final PoolDataSourceConfiguration pdsConfig) {
        set((PoolDataSourceConfigurationHikari)pdsConfig);
    }
    
    private void set(final PoolDataSourceConfigurationHikari pdsConfig) {
        PoolDataSourceConfigurationHikari.set(this, pdsConfig);
    }

    public PoolDataSourceConfiguration getWithPoolName() {
        return get(true);
    }

    public PoolDataSourceConfiguration get() {
        return get(false);
    }

    private PoolDataSourceConfiguration get(final boolean withPoolName) {
        return PoolDataSourceConfigurationHikari
            .builder()
            .driverClassName(getDriverClassName())
            .url(getJdbcUrl())
            .username(getUsername())
            .password(null) // do not copy password
            .type(this.getClass().getName())
            .poolName(withPoolName ? getPoolName() : null)
            .maximumPoolSize(getMaximumPoolSize())
            .minimumIdle(getMinimumIdle())
            .autoCommit(isAutoCommit())
            .connectionTimeout(getConnectionTimeout())
            .idleTimeout(getIdleTimeout())
            .maxLifetime(getMaxLifetime())
            .connectionTestQuery(getConnectionTestQuery())
            .initializationFailTimeout(getInitializationFailTimeout())
            .isolateInternalQueries(isIsolateInternalQueries())
            .allowPoolSuspension(isAllowPoolSuspension())
            .readOnly(isReadOnly())
            .registerMbeans(isRegisterMbeans())
            .validationTimeout(getValidationTimeout())
            .leakDetectionThreshold(getLeakDetectionThreshold())
            .build();
    }
        
    public void show(final PoolDataSourceConfiguration pdsConfig) {
        show((PoolDataSourceConfigurationHikari)pdsConfig);
    }
    
    private void show(final PoolDataSourceConfigurationHikari pdsConfig) {
        final String indentPrefix = PoolDataSourceStatistics.INDENT_PREFIX;

        /* Pool Data Source */
        
        log.info("Properties for pool connecting to schema {} via {}", pdsConfig.getSchema(), pdsConfig.getUsernameToConnectTo());

        /* info from PoolDataSourceConfiguration */
        log.info("{}url: {}", indentPrefix, pdsConfig.getUrl());
        log.info("{}username: {}", indentPrefix, pdsConfig.getUsername());
        // do not log passwords
        log.info("{}type: {}", indentPrefix, pdsConfig.getType());

        /* info from PoolDataSourceConfigurationHikari */
        log.info("{}maximumPoolSize: {}", indentPrefix, pdsConfig.getMaximumPoolSize());
        log.info("{}minimumIdle: {}", indentPrefix, pdsConfig.getMinimumIdle());
        log.info("{}dataSourceClassName: {}", indentPrefix, pdsConfig.getDataSourceClassName());
        log.info("{}autoCommit: {}", indentPrefix, pdsConfig.isAutoCommit());
        log.info("{}connectionTimeout: {}", indentPrefix, pdsConfig.getConnectionTimeout());
        log.info("{}idleTimeout: {}", indentPrefix, pdsConfig.getIdleTimeout());
        log.info("{}maxLifetime: {}", indentPrefix, pdsConfig.getMaxLifetime());
        log.info("{}connectionTestQuery: {}", indentPrefix, pdsConfig.getConnectionTestQuery());
        log.info("{}initializationFailTimeout: {}", indentPrefix, pdsConfig.getInitializationFailTimeout());
        log.info("{}isolateInternalQueries: {}", indentPrefix, pdsConfig.isIsolateInternalQueries());
        log.info("{}allowPoolSuspension: {}", indentPrefix, pdsConfig.isAllowPoolSuspension());
        log.info("{}readOnly: {}", indentPrefix, pdsConfig.isReadOnly());
        log.info("{}registerMbeans: {}", indentPrefix, pdsConfig.isRegisterMbeans());
        log.info("{}validationTimeout: {}", indentPrefix, pdsConfig.getValidationTimeout());
        log.info("{}leakDetectionThreshold: {}", indentPrefix, pdsConfig.getLeakDetectionThreshold());

        /* Common Simple Pool Data Source */
        
        log.info("Properties for {}: {}", getClass().getSimpleName(), getPoolName());
        
        /* info from PoolDataSourceConfiguration */
        log.info("{}driverClassName: {}", indentPrefix, getDriverClassName());
        log.info("{}url: {}", indentPrefix, getJdbcUrl());
        log.info("{}username: {}", indentPrefix, getUsername());
        // do not log passwords
        /* info from PoolDataSourceConfigurationHikari */
        log.info("{}maximumPoolSize: {}", indentPrefix, getMaximumPoolSize());
        log.info("{}minimumIdle: {}", indentPrefix, getMinimumIdle());
        log.info("{}dataSourceClassName: {}", indentPrefix, getDataSourceClassName());
        log.info("{}autoCommit: {}", indentPrefix, isAutoCommit());
        log.info("{}connectionTimeout: {}", indentPrefix, getConnectionTimeout());
        log.info("{}idleTimeout: {}", indentPrefix, getIdleTimeout());
        log.info("{}maxLifetime: {}", indentPrefix, getMaxLifetime());
        log.info("{}connectionTestQuery: {}", indentPrefix, getConnectionTestQuery());
        log.info("{}initializationFailTimeout: {}", indentPrefix, getInitializationFailTimeout());
        log.info("{}isolateInternalQueries: {}", indentPrefix, isIsolateInternalQueries());
        log.info("{}allowPoolSuspension: {}", indentPrefix, isAllowPoolSuspension());
        log.info("{}readOnly: {}", indentPrefix, isReadOnly());
        log.info("{}registerMbeans: {}", indentPrefix, isRegisterMbeans());
        log.info("{}validationTimeout: {}", indentPrefix, getValidationTimeout());
        log.info("{}leakDetectionThreshold: {}", indentPrefix, getLeakDetectionThreshold());
        /*
        log.info("metricRegistry: {}", getMetricRegistry());
        log.info("healthCheckRegistry: {}", getHealthCheckRegistry());
        log.info("catalog: {}", getCatalog());
        log.info("connectionInitSql: {}", getConnectionInitSql());
        log.info("transactionIsolation: {}", getTransactionIsolation());
        log.info("dataSource: {}", getDataSource());
        log.info("schema: {}", getSchema());
        log.info("threadFactory: {}", getThreadFactory());
        log.info("scheduledExecutor: {}", getScheduledExecutor());
        */
    }

    /* Interface PoolDataSourcePropertiesSettersHikari */
    
    public void setUrl(String url) {
        setJdbcUrl(url);
    }

    public void setType(String type) {
    }

    /* Interface PoolDataSourcePropertiesGettersHikari */
    
    public String getUrl() {
        return getJdbcUrl();
    }  

    // public void setPoolName(String poolName) throws SQLException;

    // public String getPoolName();

    // public void setUsername(String username) throws SQLException;

    // public String getUsername();

    // public void setPassword(String password) throws SQLException;

    // public String getPassword();
    
    // HikariCP does NOT know of an initial pool size so just use getMinPoolSize()
    public int getInitialPoolSize() {
        return getMinPoolSize();
    }

    // HikariCP does NOT know of an initial pool size so just use setMinPoolSize()
    public void setInitialPoolSize(int initialPoolSize) {
        setMinPoolSize(initialPoolSize);
    }

    // HikariCP does NOT know of a minimum pool size but minimumIdle seems to be the equivalent
    public int getMinPoolSize() {
        return getMinimumIdle();
    }

    public void setMinPoolSize(int minPoolSize) {
        setMinimumIdle(minPoolSize);
    }

    public int getMaxPoolSize() {
        return getMaximumPoolSize();
    }

    public void setMaxPoolSize(int maxPoolSize) {
        setMaximumPoolSize(maxPoolSize);
    }

    // Already part of HikariDataSource:
    // public long getConnectionTimeout(); // milliseconds
    // public void setConnectionTimeout(long connectionTimeout); // milliseconds
    
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

    @Override
    public void close() {
        try {
            if (poolDataSourceStatistics != null) {
                poolDataSourceStatistics.close();
            }
            super.close();
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    public final boolean isInitializing() {
        return !hasShownConfig.get();
    }

    public long getMinConnectionTimeout() {
        return MIN_CONNECTION_TIMEOUT;
    }
}
