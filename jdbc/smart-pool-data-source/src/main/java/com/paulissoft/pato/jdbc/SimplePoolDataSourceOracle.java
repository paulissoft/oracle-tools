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
    
    protected static final UniversalConnectionPoolManager mgr;

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
    
    private volatile PoolDataSourceStatistics poolDataSourceStatistics = null;

    // can only be set after constructor
    protected synchronized void determinePoolDataSourceStatistics(final PoolDataSourceStatistics parentPoolDataSourceStatistics) {
        if (parentPoolDataSourceStatistics == null) {
            poolDataSourceStatistics = null;
        } else {
            final PoolDataSourceConfiguration pdsConfig = get();

            // level 4
            poolDataSourceStatistics =
                new PoolDataSourceStatistics(() -> getPoolDescription() + ": (only " + pdsConfig.getSchema() + ")",
                                             parentPoolDataSourceStatistics, 
                                             () -> isClosed.get(),
                                             this::get);
        }        
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
        log.debug(">set(pdsConfig={})", pdsConfig);

        int nr = 0;
        final int maxNr = 17;
        
        do {
            try {
                /* this.driverClassName is ignored */
                switch(nr) {
                case  0: setURL(pdsConfig.getUrl()); break;
                case  1: setUser(pdsConfig.getUsername()); break;
                case  2: setPassword(pdsConfig.getPassword()); break;
                case  3: setConnectionPoolName(pdsConfig.getConnectionPoolName()); break;
                case  4: setInitialPoolSize(pdsConfig.getInitialPoolSize()); break;
                case  5: setMinPoolSize(pdsConfig.getMinPoolSize()); break;
                case  6: setMaxPoolSize(pdsConfig.getMaxPoolSize()); break;
                case  7:
                    if (pdsConfig.getConnectionFactoryClassName() != null) {
                        setConnectionFactoryClassName(pdsConfig.getConnectionFactoryClassName());
                    }
                    break;
                case  8: setValidateConnectionOnBorrow(pdsConfig.getValidateConnectionOnBorrow()); break;
                case  9: setAbandonedConnectionTimeout(pdsConfig.getAbandonedConnectionTimeout()); break;
                case 10: setTimeToLiveConnectionTimeout(pdsConfig.getTimeToLiveConnectionTimeout()); break;
                case 11: setInactiveConnectionTimeout(pdsConfig.getInactiveConnectionTimeout()); break;
                case 12: setTimeoutCheckInterval(pdsConfig.getTimeoutCheckInterval()); break;
                case 13: setMaxStatements(pdsConfig.getMaxStatements()); break;
                case 14: setConnectionWaitDurationInMillis(pdsConfig.getConnectionWaitDurationInMillis()); break;
                case 15: setMaxConnectionReuseTime(pdsConfig.getMaxConnectionReuseTime()); break;
                case 16: setSecondsToTrustIdleConnection(pdsConfig.getSecondsToTrustIdleConnection()); break;
                case 17: setConnectionValidationTimeout(pdsConfig.getConnectionValidationTimeout()); break;
                default:
                    throw new IllegalArgumentException(String.format("Wrong value for nr (%d): must be between 0 and %d", nr, maxNr));
                }
            } catch (Exception ex) {
                log.warn("nr: {}; exception: {}", nr, SimplePoolDataSource.exceptionToString(ex));
            }
        } while (++nr <= maxNr);

        log.debug("<set()");
    }
   
    public PoolDataSourceConfiguration get() {
        return PoolDataSourceConfigurationOracle
            .builder()
            .driverClassName(null)
            .url(getURL())
            .username(getUsername())
            .password(null) // do not copy password
            .type(this.getClass().getName())
            .connectionPoolName(null) // do not copy pool name
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

        log.info("Properties for common simple pool: {}", getConnectionPoolName());

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

    // IMPORTANT
    //
    // Since the connection pool name can notchange once the pool has started,
    // we change the description if we add/remove schemas.
    public String getPoolDescription() {
        final String poolName = getConnectionPoolName();
        final String description = getDescription();
        
        return (poolName == null || poolName.isEmpty() ?
                "" :
                poolName + (description == null || description.isEmpty() ? "" : "-" + description));
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

    @Override
    public Connection getConnection() throws SQLException {
        final PoolDataSourceStatistics poolDataSourceStatistics = this.poolDataSourceStatistics;
        Connection conn = null;

        if (poolDataSourceStatistics != null && SimplePoolDataSource.isStatisticsEnabled()) {
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

        return conn;
    }
}
