package com.paulissoft.pato.jdbc;

import java.sql.SQLException;
import oracle.ucp.jdbc.PoolDataSourceImpl;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class SimplePoolDataSourceOracle extends PoolDataSourceImpl implements SimplePoolDataSource {

    public SimplePoolDataSourceOracle(final PoolDataSourceConfigurationOracle pdsConfigurationOracle) throws SQLException {
        super();
        log.info("SimplePoolDataSourceOracle(pdsConfigurationOracle={})", pdsConfigurationOracle);
        setURL(pdsConfigurationOracle.getUrl());
        setUsername(pdsConfigurationOracle.getUsername());
        setPassword(pdsConfigurationOracle.getPassword());
        setConnectionPoolName(pdsConfigurationOracle.getConnectionPoolName());
        setInitialPoolSize(pdsConfigurationOracle.getInitialPoolSize());
        setMinPoolSize(pdsConfigurationOracle.getMinPoolSize());
        setMaxPoolSize(pdsConfigurationOracle.getMaxPoolSize());
        setConnectionFactoryClassName(pdsConfigurationOracle.getConnectionFactoryClassName());
        setValidateConnectionOnBorrow(pdsConfigurationOracle.isValidateConnectionOnBorrow());
        setAbandonedConnectionTimeout(pdsConfigurationOracle.getAbandonedConnectionTimeout());
        setTimeToLiveConnectionTimeout(pdsConfigurationOracle.getTimeToLiveConnectionTimeout());
        setInactiveConnectionTimeout(pdsConfigurationOracle.getInactiveConnectionTimeout());
        setTimeoutCheckInterval(pdsConfigurationOracle.getTimeoutCheckInterval());
        setMaxStatements(pdsConfigurationOracle.getMaxStatements());
        setConnectionWaitTimeout(pdsConfigurationOracle.getConnectionWaitTimeout());
        setMaxConnectionReuseTime(pdsConfigurationOracle.getMaxConnectionReuseTime());
        setSecondsToTrustIdleConnection(pdsConfigurationOracle.getSecondsToTrustIdleConnection());
        setConnectionValidationTimeout(pdsConfigurationOracle.getConnectionValidationTimeout());
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
        log.debug(">updatePoolSizes()");

        final SimplePoolDataSourceOracle pdsOracle = (SimplePoolDataSourceOracle) pds;
        
        assert(this != pdsOracle);
        log.debug("pool sizes before: initial/minimum/maximum: {}/{}/{}",
                     getInitialPoolSize(),
                     getMinPoolSize(),
                     getMaxPoolSize());

        int oldSize, newSize;

        newSize = pdsOracle.getInitialPoolSize();
        oldSize = getInitialPoolSize();

        log.debug("initial pool sizes before setting it: old/new: {}/{}",
                     oldSize,
                     newSize);

        if (newSize >= 0) {
            setInitialPoolSize(newSize + Integer.max(oldSize, 0));
        }

        newSize = pdsOracle.getMinPoolSize();
        oldSize = getMinPoolSize();

        log.debug("minimum pool sizes before setting it: old/new: {}/{}",
                     oldSize,
                     newSize);

        if (newSize >= 0) {                
            setMinPoolSize(newSize + Integer.max(oldSize, 0));
        }
                
        newSize = pdsOracle.getMaxPoolSize();
        oldSize = getMaxPoolSize();

        log.debug("maximum pool sizes before setting it: old/new: {}/{}",
                     oldSize,
                     newSize);

        if (newSize >= 0) {
            setMaxPoolSize(newSize + Integer.max(oldSize, 0));
        }
                
        log.debug("pool sizes after: initial/minimum/maximum: {}/{}/{}",
                     getInitialPoolSize(),
                     getMinPoolSize(),
                     getMaxPoolSize());

        log.debug("<updatePoolSizes()");
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
}
