package com.paulissoft.pato.jdbc;

import java.sql.SQLException;
import java.util.concurrent.ConcurrentHashMap;
import lombok.extern.slf4j.Slf4j;
import oracle.ucp.jdbc.PoolDataSourceImpl;


@Slf4j
public class SimplePoolDataSourceOracle extends PoolDataSourceImpl implements SimplePoolDataSource {

    private static final String POOL_NAME_PREFIX = "OraclePool";

    private static final PoolDataSourceStatistics poolDataSourceStatisticsTotal
        = new PoolDataSourceStatistics(() -> POOL_NAME_PREFIX + ": (all)",
                                       PoolDataSourceStatistics.poolDataSourceStatisticsGrandTotal);

    private final PoolDataSourceStatistics poolDataSourceStatistics =
        new PoolDataSourceStatistics(() -> this.getPoolName() + ": (all)",
                                     poolDataSourceStatisticsTotal,
                                     this::isClosed,
                                     this::getPoolDataSourceConfiguration);

    // for join(), value: pool data source open (true) or not (false)
    private final ConcurrentHashMap<PoolDataSourceConfiguration, Boolean> cachedPoolDataSourceConfigurations = new ConcurrentHashMap<>();
    
    // for test purposes
    static void clear() {
        poolDataSourceStatisticsTotal.reset();
    }

    private SimplePoolDataSourceOracle(final PoolDataSourceConfigurationOracle pdsConfigurationOracle) {
        // super();

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
                    throw new IllegalArgumentException(String.format("Wrong value for nr (%d): must be between 0 and %d", nr, maxNr));
                }
            } catch (Exception ex) {
                log.warn("nr: {}; exception: {}", nr, SimplePoolDataSource.exceptionToString(ex));
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
    
    public void join(final PoolDataSourceConfiguration pds) {
        final PoolDataSourceConfigurationCommonId otherCommonId =
            new PoolDataSourceConfigurationCommonId(pds);
        final PoolDataSourceConfigurationCommonId thisCommonId =
            new PoolDataSourceConfigurationCommonId(this.getPoolDataSourceConfiguration());
        final boolean firstPds = cachedPoolDataSourceConfigurations.isEmpty();

        log.debug(">join(id={}, firstPds={})", pds.toString(), firstPds);

        try {
            try {
                assert(otherCommonId.equals(thisCommonId));
            } catch (AssertionError ex) {
                log.error("otherCommonId: {}", otherCommonId);
                log.error("thisCommonId: {}", thisCommonId);
                throw ex;
            }
        
            cachedPoolDataSourceConfigurations.computeIfAbsent(pds, k -> { join(pds, firstPds); return false; });
        } finally {
            log.debug("<join()");
        }
    }
    
    public String getPoolNamePrefix() {
        return POOL_NAME_PREFIX;
    }

    public void updatePoolSizes(final PoolDataSourceConfiguration pds) throws SQLException {
        updatePoolSizes((PoolDataSourceConfigurationOracle)pds);
    }
    
    private void updatePoolSizes(final PoolDataSourceConfigurationOracle pds) throws SQLException {
        log.debug(">updatePoolSizes({})", pds);

        try {
            log.debug("pool sizes before: initial/minimum/maximum: {}/{}/{}",
                      getInitialPoolSize(),
                      getMinPoolSize(),
                      getMaxPoolSize());

            int oldSize, newSize;

            newSize = pds.getInitialPoolSize();
            oldSize = getInitialPoolSize();

            log.debug("initial pool sizes before setting it: old/new: {}/{}",
                      oldSize,
                      newSize);

            if (newSize >= 0) {
                setInitialPoolSize(newSize + Integer.max(oldSize, 0));
            }

            newSize = pds.getMinPoolSize();
            oldSize = getMinPoolSize();

            log.debug("minimum pool sizes before setting it: old/new: {}/{}",
                      oldSize,
                      newSize);

            if (newSize >= 0) {                
                setMinPoolSize(newSize + Integer.max(oldSize, 0));
            }
                
            newSize = pds.getMaxPoolSize();
            oldSize = getMaxPoolSize();

            log.debug("maximum pool sizes before setting it: old/new: {}/{}",
                      oldSize,
                      newSize);

            if (newSize >= 0) {
                setMaxPoolSize(newSize + Integer.max(oldSize, 0));
            }
        } finally {
            log.debug("pool sizes after: initial/minimum/maximum: {}/{}/{}",
                      getInitialPoolSize(),
                      getMinPoolSize(),
                      getMaxPoolSize());

            log.debug("<updatePoolSizes()");
        }
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

    @SuppressWarnings("deprecation")
    @Override
    public String getPassword() {
        return super.getPassword();
    }

    @SuppressWarnings("deprecation")
    @Override
    public int getConnectionWaitTimeout() {
        return super.getConnectionWaitTimeout();
    }

    @SuppressWarnings("deprecation")
    @Override
    public void setConnectionWaitTimeout(int waitTimeout) throws java.sql.SQLException {
        super.setConnectionWaitTimeout(waitTimeout);
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

    public void open(final PoolDataSourceConfiguration pds) {
        log.debug("open({})", pds);
        
        cachedPoolDataSourceConfigurations.computeIfPresent(pds, (k, v) -> true);
    }

    public void close(final PoolDataSourceConfiguration pds) {
        log.debug("close({})", pds);
        
        cachedPoolDataSourceConfigurations.computeIfPresent(pds, (k, v) -> false);
    }

    // to implement interface Closeable
    public void close() {
        // nothing
    }

    public boolean isClosed() {
        log.debug(">isClosed()");
        
        // when there is at least one attached pool open: return false
        final Boolean found = cachedPoolDataSourceConfigurations.containsValue(true);

        log.debug("<isClosed() = {}", !found);

        return !found; // all closed
    }

    public void show(final PoolDataSourceConfiguration pds) {
        show((PoolDataSourceConfigurationOracle)pds);
    }
    
    private void show(final PoolDataSourceConfigurationOracle pds) {
        final String indentPrefix = PoolDataSourceStatistics.INDENT_PREFIX;

        /* Smart Pool Data Source */

        log.info("Properties for smart pool connecting to schema {} via {}", pds.getSchema(), pds.getUsernameToConnectTo());

        /* info from PoolDataSourceConfiguration */
        log.info("{}url: {}", indentPrefix, pds.getUrl());
        log.info("{}username: {}", indentPrefix, pds.getUsername());
        // do not log passwords
        log.info("{}type: {}", indentPrefix, pds.getType());
        /* info from PoolDataSourceConfigurationOracle */
        log.info("{}initialPoolSize: {}", indentPrefix, pds.getInitialPoolSize());
        log.info("{}minPoolSize: {}", indentPrefix, pds.getMinPoolSize());
        log.info("{}maxPoolSize: {}", indentPrefix, pds.getMaxPoolSize());
        log.info("{}connectionFactoryClassName: {}", indentPrefix, pds.getConnectionFactoryClassName());
        log.info("{}validateConnectionOnBorrow: {}", indentPrefix, pds.getValidateConnectionOnBorrow());
        log.info("{}abandonedConnectionTimeout: {}", indentPrefix, pds.getAbandonedConnectionTimeout());
        log.info("{}timeToLiveConnectionTimeout: {}", indentPrefix, pds.getTimeToLiveConnectionTimeout()); 
        log.info("{}inactiveConnectionTimeout: {}", indentPrefix, pds.getInactiveConnectionTimeout());
        log.info("{}timeoutCheckInterval: {}", indentPrefix, pds.getTimeoutCheckInterval());
        log.info("{}maxStatements: {}", indentPrefix, pds.getMaxStatements());
        log.info("{}connectionWaitTimeout: {}", indentPrefix, pds.getConnectionWaitTimeout());
        log.info("{}maxConnectionReuseTime: {}", indentPrefix, pds.getMaxConnectionReuseTime());
        log.info("{}secondsToTrustIdleConnection: {}", indentPrefix, pds.getSecondsToTrustIdleConnection());
        log.info("{}connectionValidationTimeout: {}", indentPrefix, pds.getConnectionValidationTimeout());

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
        log.info("{}connectionWaitTimeout: {}", indentPrefix, getConnectionWaitTimeout());
        log.info("{}maxConnectionReuseTime: {}", indentPrefix, getMaxConnectionReuseTime());
        log.info("{}secondsToTrustIdleConnection: {}", indentPrefix, getSecondsToTrustIdleConnection());
        log.info("{}connectionValidationTimeout: {}", indentPrefix, getConnectionValidationTimeout());
    }

    @Override
    public boolean equals(Object obj) {
        if (obj == null || !(obj instanceof SimplePoolDataSourceOracle)) {
            return false;
        }

        final SimplePoolDataSourceOracle other = (SimplePoolDataSourceOracle) obj;
        
        return other.getPoolDataSourceConfiguration().equals(this.getPoolDataSourceConfiguration());
    }

    @Override
    public int hashCode() {
        return this.getPoolDataSourceConfiguration().hashCode();
    }

    @Override
    public String toString() {
        return this.getPoolDataSourceConfiguration().toString();
    }
}
