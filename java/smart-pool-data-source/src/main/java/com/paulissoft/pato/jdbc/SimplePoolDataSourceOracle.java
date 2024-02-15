package com.paulissoft.pato.jdbc;

import java.sql.SQLException;
import oracle.ucp.jdbc.PoolDataSourceImpl;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class SimplePoolDataSourceOracle extends PoolDataSourceImpl implements SimplePoolDataSource {

    public SimplePoolDataSourceOracle(final PoolDataSourceConfigurationOracle pdsConfigurationOracle) throws SQLException {
        super();

        log.info("SimplePoolDataSourceOracle(pdsConfigurationOracle={})", pdsConfigurationOracle);
        
        int nr = 0;
        final int maxNr = 17;
        
        do {
            try {
                switch(nr) {
                case 0: setURL(pdsConfigurationOracle.getUrl()); break;
                case 1: setUsername(pdsConfigurationOracle.getUsername()); break;
                case 2: setPassword(pdsConfigurationOracle.getPassword()); break;
                case 3: setConnectionPoolName(pdsConfigurationOracle.getConnectionPoolName()); break;
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
                    throw new RuntimeException(String.format("Wrong value for nr ({nr}): must be between 0 and {}", nr, maxNr));
                }
            } catch (Exception ex) {
                log.warn("exception at nr {}: {}", nr, ex.getMessage());
            }
        } while (++nr <= maxNr);

        log.info("getPoolDataSourceConfiguration()={}", getPoolDataSourceConfiguration().toString());
    }

    public PoolDataSourceConfiguration getPoolDataSourceConfiguration() {
        return PoolDataSourceConfigurationOracle
            .builder()
            .driverClassName(null)
            .url(getURL())
            .username(getUsername())
            .password(getPassword())
            .type(SimplePoolDataSourceOracle.class.getName())
            .connectionPoolName(getConnectionPoolName())
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

    public void updatePoolSizes(final SimplePoolDataSource pds) throws SQLException {
        log.info(">updatePoolSizes()");

        final SimplePoolDataSourceOracle pdsOracle = (SimplePoolDataSourceOracle) pds;
        
        assert(this != pdsOracle);
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

    public String getUrl() {
        return getURL();
    }
    
    public void setUrl(String url) throws SQLException {
        setURL(url);
    }

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

    public void close() {
        ; // nothing
    }

    @Override
    default public boolean equals(Object obj) {
        if (obj == null || !(obj instanceof SimplePoolDataSourceOracle)) {
            return false;
        }

        SimplePoolDataSourceOracle other = (SimplePoolDataSourceOracle) obj;
        
        return other.toString().equals(this.toString());
    }

    @Override
    default public int hashCode() {
        return this.toString().hashCode();
    }

    @Override
    default public String toString() {
        return getPoolDataSourceConfiguration().toString();
    }
}
