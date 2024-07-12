package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.atomic.AtomicBoolean;
import lombok.extern.slf4j.Slf4j;
import oracle.ucp.UniversalConnectionPool;
import oracle.ucp.UniversalConnectionPoolException;
import oracle.ucp.admin.UniversalConnectionPoolManager;
import oracle.ucp.admin.UniversalConnectionPoolManagerImpl;
import oracle.ucp.jdbc.PoolDataSourceImpl;
    
@Slf4j
public class SimplePoolDataSourceOracle
    extends PoolDataSourceImpl
    implements SimplePoolDataSource, PoolDataSourcePropertiesSettersOracle, PoolDataSourcePropertiesGettersOracle {

    // all static related
    
    private static final long serialVersionUID = 3886083682048526889L;
    
    static final long MIN_CONNECTION_TIMEOUT = 0; // milliseconds for one pool, so twice this number for two

    private static final String POOL_NAME_PREFIX = "OraclePool";

    private static final PoolDataSourceStatistics poolDataSourceStatisticsTotal =
        new PoolDataSourceStatistics(() -> POOL_NAME_PREFIX + ": (all)",
                                     PoolDataSourceStatistics.poolDataSourceStatisticsGrandTotal);

    private static final UniversalConnectionPoolManager mgr;

    static {
        try {
            mgr = UniversalConnectionPoolManagerImpl.getUniversalConnectionPoolManager();
        } catch (UniversalConnectionPoolException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    // all object related
    
    private final StringBuffer id = new StringBuffer();

    private final StringBuffer password = new StringBuffer();

    private final AtomicBoolean isClosed = new AtomicBoolean(false);

    private final PoolDataSourceStatistics poolDataSourceStatistics;

    private final AtomicBoolean hasShownConfig = new AtomicBoolean(false);

    // constructor
    public SimplePoolDataSourceOracle() {
        poolDataSourceStatistics = 
            new PoolDataSourceStatistics(null, // description will be the pool name
                                         poolDataSourceStatisticsTotal, 
                                         this::isClosed,
                                         this::getWithPoolName);
    }
    
    @Override
    public Connection getConnection() throws SQLException {
        Connection conn = null;
        final boolean isStatisticsEnabled = poolDataSourceStatistics != null && SimplePoolDataSource.isStatisticsEnabled();

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

        if (!hasShownConfig.getAndSet(true)) {
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
    // @param username  provided by pool data source that needs the overflow pool data source to connect to schema
    //                  via a proxy session through username (e.g. bc_proxy[bodomain])
    // @param password  provided by pool data source that needs the overflow pool data source to connect to schema
    //                  via a proxy session through with this password
    // @param schema    provided by pool data source that needs the overflow pool data source to connect to schema
    //                  via a proxy session (e.g. bodomain)
    public Connection getConnection(final String username,
                                    final String password,
                                    final String schema,
                                    final int refCount) throws SQLException {
        log.debug(">getConnection(id={}, username={}, schema={})",
                  getId(), username, schema);

        final Instant tm0 = Instant.now();
        Connection conn = null;

        try {
            conn = super.getConnection(username, password);

            assert conn.getSchema().equalsIgnoreCase(schema) : String.format("Connection schema (%s) must be equal to %s", conn.getSchema(), schema);
        } finally {
            log.debug("<getConnection(id={})", getId());
        }
        
        if (statisticsEnabled.get()) {
            poolDataSourceStatistics.updateStatistics(this,
                                                      conn,
                                                      Duration.between(tm0, Instant.now()).toMillis(),
                                                      true);
        }

        return conn;
    }

    public String getPoolNamePrefix() {
        return POOL_NAME_PREFIX;
    }

    public void setId(final String srcId) {
        SimplePoolDataSource.setId(id, String.format("0x%08x", hashCode()), srcId);
    }

    public String getId() {
        return id.toString();
    }

    public void set(final PoolDataSourceConfiguration pdsConfig) {
        set((PoolDataSourceConfigurationOracle)pdsConfig);
    }
    
    private void set(final PoolDataSourceConfigurationOracle pdsConfig) {
        PoolDataSourceConfigurationOracle.set(this, pdsConfig);
    }
   
    public PoolDataSourceConfiguration getWithPoolName() {
        return get(true);
    }

    public PoolDataSourceConfiguration get() {
        return get(false);
    }

    private PoolDataSourceConfiguration get(final boolean withPoolName) {
        return PoolDataSourceConfigurationOracle
            .builder()
            .driverClassName(null)
            .url(getURL())
            .username(getUsername())
            .password(null) // do not copy password
            .type(this.getClass().getName())
            .connectionPoolName(withPoolName ? getConnectionPoolName() : null)
            .initialPoolSize(getInitialPoolSize())
            .minPoolSize(getMinPoolSize())
            .maxPoolSize(getMaxPoolSize())
            .connectionFactoryClassName(getConnectionFactoryClassName())
            .validateConnectionOnBorrow(getValidateConnectionOnBorrow())
            .abandonedConnectionTimeout(getAbandonedConnectionTimeout())
            .timeToLiveConnectionTimeout(getTimeToLiveConnectionTimeout())
            .inactiveConnectionTimeout(getInactiveConnectionTimeout())
            .timeoutCheckInterval(getTimeoutCheckInterval())
            .maxStatements(getMaxStatements())
            .connectionWaitDurationInMillis(getConnectionWaitDurationInMillis())
            .maxConnectionReuseTime(getMaxConnectionReuseTime())
            .secondsToTrustIdleConnection(getSecondsToTrustIdleConnection())
            .connectionValidationTimeout(getConnectionValidationTimeout())
            .build();
    }

    public boolean isClosed() {
        return isClosed.get();
    }
    
    public void show(final PoolDataSourceConfiguration pdsConfig) {
        show((PoolDataSourceConfigurationOracle)pdsConfig);
    }
    
    private void show(final PoolDataSourceConfigurationOracle pdsConfig) {
        final String indentPrefix = PoolDataSourceStatistics.INDENT_PREFIX;

        /* Pool Data Source */

        log.info("Properties for pool connecting to schema {} via {}", pdsConfig.getSchema(), pdsConfig.getUsernameToConnectTo());

        /* info from PoolDataSourceConfiguration */
        log.info("{}url: {}", indentPrefix, pdsConfig.getUrl());
        log.info("{}username: {}", indentPrefix, pdsConfig.getUsername());
        // do not log passwords
        log.info("{}type: {}", indentPrefix, pdsConfig.getType());
        /* info from PoolDataSourceConfigurationOracle */
        log.info("{}initialPoolSize: {}", indentPrefix, pdsConfig.getInitialPoolSize());
        log.info("{}minPoolSize: {}", indentPrefix, pdsConfig.getMinPoolSize());
        log.info("{}maxPoolSize: {}", indentPrefix, pdsConfig.getMaxPoolSize());
        log.info("{}connectionFactoryClassName: {}", indentPrefix, pdsConfig.getConnectionFactoryClassName());
        log.info("{}validateConnectionOnBorrow: {}", indentPrefix, pdsConfig.getValidateConnectionOnBorrow());
        log.info("{}abandonedConnectionTimeout: {}", indentPrefix, pdsConfig.getAbandonedConnectionTimeout());
        log.info("{}timeToLiveConnectionTimeout: {}", indentPrefix, pdsConfig.getTimeToLiveConnectionTimeout()); 
        log.info("{}inactiveConnectionTimeout: {}", indentPrefix, pdsConfig.getInactiveConnectionTimeout());
        log.info("{}timeoutCheckInterval: {}", indentPrefix, pdsConfig.getTimeoutCheckInterval());
        log.info("{}maxStatements: {}", indentPrefix, pdsConfig.getMaxStatements());
        log.info("{}connectionWaitDurationInMillis: {}", indentPrefix, pdsConfig.getConnectionWaitDurationInMillis());
        log.info("{}maxConnectionReuseTime: {}", indentPrefix, pdsConfig.getMaxConnectionReuseTime());
        log.info("{}secondsToTrustIdleConnection: {}", indentPrefix, pdsConfig.getSecondsToTrustIdleConnection());
        log.info("{}connectionValidationTimeout: {}", indentPrefix, pdsConfig.getConnectionValidationTimeout());

        /* Common Simple Pool Data Source */

        log.info("Properties for {}: {}", getClass().getSimpleName(), getConnectionPoolName());

        /* info from PoolDataSourceConfiguration */
        log.info("{}url: {}", indentPrefix, getURL());
        log.info("{}username: {}", indentPrefix, getUser());
        // do not log passwords
        /* info from PoolDataSourceConfigurationOracle */
        log.info("{}initialPoolSize: {}", indentPrefix, getInitialPoolSize());
        log.info("{}minPoolSize: {}", indentPrefix, getMinPoolSize());
        log.info("{}maxPoolSize: {}", indentPrefix, getMaxPoolSize());
        log.info("{}connectionFactoryClassName: {}", indentPrefix, getConnectionFactoryClassName());
        log.info("{}validateConnectionOnBorrow: {}", indentPrefix, getValidateConnectionOnBorrow());
        log.info("{}abandonedConnectionTimeout: {}", indentPrefix, getAbandonedConnectionTimeout());
        log.info("{}timeToLiveConnectionTimeout: {}", indentPrefix, getTimeToLiveConnectionTimeout()); 
        log.info("{}inactiveConnectionTimeout: {}", indentPrefix, getInactiveConnectionTimeout());
        log.info("{}timeoutCheckInterval: {}", indentPrefix, getTimeoutCheckInterval());
        log.info("{}maxStatements: {}", indentPrefix, getMaxStatements());
        log.info("{}connectionWaitDurationInMillis: {}", indentPrefix, getConnectionWaitDurationInMillis());
        log.info("{}maxConnectionReuseTime: {}", indentPrefix, getMaxConnectionReuseTime());
        log.info("{}secondsToTrustIdleConnection: {}", indentPrefix, getSecondsToTrustIdleConnection());
        log.info("{}connectionValidationTimeout: {}", indentPrefix, getConnectionValidationTimeout());
    }

    /* Interface PoolDataSourcePropertiesSettersOracle */

    public void setUrl(String url) throws SQLException {
        setURL(url);
    }

    public void setType(String paramString) {
    }

    /* Interface PoolDataSourcePropertiesGettersOracle */
    
    public String getUrl() {
        return getURL();
    }

    public void setPoolName(String poolName) throws SQLException {
        setConnectionPoolName(poolName);
    }

    public String getPoolName() {
        return getConnectionPoolName();
    }

    public void setUsername(String username) throws SQLException {
        setUser(username);
    }

    public String getUsername() {
        return getUser();
    }

    @Override
    public void setPassword(String password) throws SQLException {
        this.password.delete(0, this.password.length());
        this.password.append(password);

        super.setPassword(password);
    }
    
    @SuppressWarnings("deprecation")
    @Override
    public String getPassword() {
        return password.toString();
    }

    // Already part of PoolDataSourceImpl:
    // public int getInitialPoolSize();
    // public void setInitialPoolSize(int initialPoolSize);
    // public int getMinPoolSize();
    // public void setMinPoolSize(int minPoolSize);
    // public int getMaxPoolSize();
    // public void setMaxPoolSize(int maxPoolSize);
    
    public long getConnectionTimeout() { // milliseconds
        return getConnectionWaitDurationInMillis();
    }

    public void setConnectionTimeout(long connectionTimeout) throws SQLException { // milliseconds
        setConnectionWaitDurationInMillis(connectionTimeout);
    }

    public int getActiveConnections() {
        return getBorrowedConnectionsCount();
    }

    public int getIdleConnections() {
        return getAvailableConnectionsCount();
    }

    public int getTotalConnections() {
        return getActiveConnections() + getIdleConnections();
    }

    public void close() {
        try {
            if (poolDataSourceStatistics != null) {
                poolDataSourceStatistics.close();
            }
                            
            final String connectionPoolName = getConnectionPoolName();
            
            log.info("{} - Close initiated...", connectionPoolName);
            
            // this pool may or may NOT be in the connection pools (implicitly) managed by mgr
            UniversalConnectionPool ucp;

            try {
                ucp = mgr.getConnectionPool(connectionPoolName);
            } catch (Exception ex) {
                ucp = null;
            }

            if (ucp != null) {
                ucp.stop();
                isClosed.set(true);
                log.info("{} - Close completed.", connectionPoolName);
                // mgr.destroyConnectionPool(getConnectionPoolName()); // will generate a UCP-45 later on
            }
        } catch (UniversalConnectionPoolException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }
    
    @Override
    public long getConnectionWaitDurationInMillis() {
        return getConnectionWaitDuration().toMillis();
    }

    @Override
    public void setConnectionWaitDurationInMillis(long waitTimeout) throws SQLException {
        setConnectionWaitDuration(Duration.ofMillis(waitTimeout));
    }

    public final boolean isInitializing() {
        return !hasShownConfig.get();
    }

    public long getMinConnectionTimeout() {
        return MIN_CONNECTION_TIMEOUT;
    }
}
