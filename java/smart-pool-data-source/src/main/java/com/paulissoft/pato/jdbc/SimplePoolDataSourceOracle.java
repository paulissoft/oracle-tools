package com.paulissoft.pato.jdbc;

import java.sql.SQLException;
import java.util.concurrent.ConcurrentHashMap;
import lombok.extern.slf4j.Slf4j;
import oracle.ucp.jdbc.PoolDataSourceImpl;


@Slf4j
public class SimplePoolDataSourceOracle extends PoolDataSourceImpl implements SimplePoolDataSource {

    private static final String POOL_NAME_PREFIX = "OraclePool";

    // for join()
    // value true means it is the initialization entry (in constructor)
    private static final ConcurrentHashMap<PoolDataSourceConfigurationId, Boolean> cachedPoolDataSourceConfigurations = new ConcurrentHashMap<>();

    private static final PoolDataSourceStatistics poolDataSourceStatisticsTotal =
        new PoolDataSourceStatistics(() -> POOL_NAME_PREFIX + ": (all)",
                                     PoolDataSourceStatistics.poolDataSourceStatisticsGrandTotal);

    private final PoolDataSourceStatistics poolDataSourceStatistics =
        new PoolDataSourceStatistics(() -> this.getPoolName() + ": (all)", poolDataSourceStatisticsTotal);
    
    // for test purposes
    static void clear() {
        cachedPoolDataSourceConfigurations.clear();
    }

    public SimplePoolDataSourceOracle(final PoolDataSourceConfigurationOracle pdsConfigurationOracle) {
        super();

        int nr = 0;
        final int maxNr = 17;
        
        do {
            try {
                switch(nr) {
                case 0: setURL(pdsConfigurationOracle.getUrl()); break;
                case 1: setUsername(pdsConfigurationOracle.getUsername()); break;
                case 2: setPassword(pdsConfigurationOracle.getPassword()); break;
                case 3: /* set in super() via join() */ break;
                case 4: setInitialPoolSize(pdsConfigurationOracle.getInitialPoolSize()); break;
                case 5: setMinPoolSize(pdsConfigurationOracle.getMinPoolSize()); break;
                case 6: setMaxPoolSize(pdsConfigurationOracle.getMaxPoolSize()); break;
                case 7: setConnectionFactoryClassName(pdsConfigurationOracle.getConnectionFactoryClassName()); break;
                case 8: setValidateConnectionOnBorrow(pdsConfigurationOracle.getValidateConnectionOnBorrow()); break;
                case 9: setAbandonedConnectionTimeout(pdsConfigurationOracle.getAbandonedConnectionTimeout()); break;
                case 10: setTimeToLiveConnectionTimeout(pdsConfigurationOracle.getTimeToLiveConnectionTimeout()); break;
                case 11: setInactiveConnectionTimeout(pdsConfigurationOracle.getInactiveConnectionTimeout()); break;
                case 12: setTimeoutCheckInterval(pdsConfigurationOracle.getTimeoutCheckInterval()); break;
                case 13: setMaxStatements(pdsConfigurationOracle.getMaxStatements()); break;
                case 14: setConnectionWaitTimeout(pdsConfigurationOracle.getConnectionWaitTimeout()); break;
                case 15: setMaxConnectionReuseTime(pdsConfigurationOracle.getMaxConnectionReuseTime()); break;
                case 16: setSecondsToTrustIdleConnection(pdsConfigurationOracle.getSecondsToTrustIdleConnection()); break;
                case 17: setConnectionValidationTimeout(pdsConfigurationOracle.getConnectionValidationTimeout()); break;
                default:
                    throw new IllegalArgumentException(String.format("Wrong value for nr ({nr}): must be between 0 and {}", nr, maxNr));
                }
            } catch (Exception ex) {
                log.warn("exception at nr {}: {}", nr, ex.getMessage());
            }
        } while (++nr <= maxNr);
    }

    public static SimplePoolDataSourceOracle build(final PoolDataSourceConfiguration pdsConfiguration) {
        return new SimplePoolDataSourceOracle((PoolDataSourceConfigurationOracle)pdsConfiguration);
    }

    public PoolDataSourceConfiguration getPoolDataSourceConfiguration() {
        return getPoolDataSourceConfiguration(true);
    }
    
    public PoolDataSourceConfiguration getPoolDataSourceConfiguration(final boolean excludeNonIdConfiguration) {
        return PoolDataSourceConfigurationOracle
            .builder()
            .driverClassName(null)
            .url(getURL())
            .username(getUsername())
            .password(excludeNonIdConfiguration ? null : getPassword())
            .type(SimplePoolDataSourceOracle.class.getName())
            .connectionPoolName(excludeNonIdConfiguration ? null : getConnectionPoolName())
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
            .connectionWaitTimeout(getConnectionWaitTimeout())
            .maxConnectionReuseTime(getMaxConnectionReuseTime())
            .secondsToTrustIdleConnection(getSecondsToTrustIdleConnection())
            .connectionValidationTimeout(getConnectionValidationTimeout())
            .build();
    }
    
    public void join(final PoolDataSourceConfiguration pdsConfiguration, final String schema) {
        final PoolDataSourceConfigurationOracle pdsConfigurationOracle = (PoolDataSourceConfigurationOracle) pdsConfiguration;
        final boolean firstPds = cachedPoolDataSourceConfigurations.isEmpty();
        final PoolDataSourceConfigurationId id = new PoolDataSourceConfigurationId(pdsConfigurationOracle, false);
        final PoolDataSourceConfigurationId otherCommonId = new PoolDataSourceConfigurationId(pdsConfigurationOracle, true);
        final PoolDataSourceConfigurationId thisCommonId = new PoolDataSourceConfigurationId(getPoolDataSourceConfiguration(), true);

        log.debug(">join(id={}, firstPds={})", id, firstPds);

        try {
            if (!otherCommonId.equals(thisCommonId)) {
                log.error("otherCommonId: {}", otherCommonId);
                log.error("thisCommonId: {}", thisCommonId);
        
                assert(false);
            }
        
            cachedPoolDataSourceConfigurations.computeIfAbsent(id, k -> { join(pdsConfigurationOracle, schema, firstPds); return false; });
        } finally {
            log.debug("<join()");
        }
    }
    
    public String getPoolNamePrefix() {
        return POOL_NAME_PREFIX;
    }

    public void updatePoolSizes(final PoolDataSourceConfiguration pds) throws SQLException {
        log.info(">updatePoolSizes()");

        final PoolDataSourceConfigurationOracle pdsOracle = (PoolDataSourceConfigurationOracle) pds;
            
        log.info("pool sizes before: initial/minimum/maximum: {}/{}/{}",
                 getInitialPoolSize(),
                 getMinPoolSize(),
                 getMaxPoolSize());

        int oldSize, newSize;

        newSize = pdsOracle.getInitialPoolSize();
        oldSize = getInitialPoolSize();

        log.info("initial pool sizes before setting it: old/new: {}/{}",
                 oldSize,
                 newSize);

        if (newSize >= 0) {
            setInitialPoolSize(newSize + Integer.max(oldSize, 0));
        }

        newSize = pdsOracle.getMinPoolSize();
        oldSize = getMinPoolSize();

        log.info("minimum pool sizes before setting it: old/new: {}/{}",
                 oldSize,
                 newSize);

        if (newSize >= 0) {                
            setMinPoolSize(newSize + Integer.max(oldSize, 0));
        }
                
        newSize = pdsOracle.getMaxPoolSize();
        oldSize = getMaxPoolSize();

        log.info("maximum pool sizes before setting it: old/new: {}/{}",
                 oldSize,
                 newSize);

        if (newSize >= 0) {
            setMaxPoolSize(newSize + Integer.max(oldSize, 0));
        }
                
        log.info("pool sizes after: initial/minimum/maximum: {}/{}/{}",
                 getInitialPoolSize(),
                 getMinPoolSize(),
                 getMaxPoolSize());

        log.info("<updatePoolSizes()");
    }
    
    public String getPoolName() {
        return getConnectionPoolName();
    }

    public void setPoolName(String poolName) throws SQLException {
        setConnectionPoolName(poolName);
    }

    /*TBD*/
    /*
    public String getUrl() {
        return getURL();
    }
    
    public void setUrl(String url) throws SQLException {
        setURL(url);
    }
    */

    public String getUsername() {
        return getUser();
    }

    public void setUsername(String username) throws SQLException {
        setUser(username);
    }

    public long getConnectionTimeout() { // milliseconds
        return 1000 * getConnectionWaitTimeout();
    }

    // connection statistics
    
    public int getActiveConnections() {
        return getBorrowedConnectionsCount();
    }

    public int getIdleConnections() {
        return getAvailableConnectionsCount();
    }

    public int getTotalConnections() {
        return getActiveConnections() + getIdleConnections();
    }

    public PoolDataSourceStatistics getPoolDataSourceStatistics() {
        return poolDataSourceStatistics;
    }
    
    public void updateStatistics() {
        poolDataSourceStatistics.update(getActiveConnections(), getIdleConnections(), getTotalConnections());
    }

    @Override
    public void open(final PoolDataSourceConfiguration pds) {
        final PoolDataSourceConfigurationOracle pdsOracle = (PoolDataSourceConfigurationOracle) pds;

        cachedPoolDataSourceConfigurations.computeIfPresent(new PoolDataSourceConfigurationId(pdsOracle), (id, opened) -> true);
    }

    @Override
    public void close(final PoolDataSourceConfiguration pds, final boolean statisticsEnabled) {
        final PoolDataSourceConfigurationOracle pdsOracle = (PoolDataSourceConfigurationOracle) pds;
        final boolean isOpenBefore = statisticsEnabled && cachedPoolDataSourceConfigurations.containsValue(true);

        // this will set opened to false for the key
        cachedPoolDataSourceConfigurations.computeIfPresent(new PoolDataSourceConfigurationId(pdsOracle), (id, opened) -> false);

        final boolean isOpenAfter = statisticsEnabled && cachedPoolDataSourceConfigurations.containsValue(true);

        if (isOpenBefore && !isOpenAfter) { // implies statisticsEnabled
            poolDataSourceStatistics.showStatistics(this, -1L, -1L, true);
        }
    }

    // to implement interface Closeable
    public void close() {
        ; // nothing
    }
}
