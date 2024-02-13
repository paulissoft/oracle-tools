package com.paulissoft.pato.jdbc;

import java.sql.SQLException;
import oracle.ucp.jdbc.PoolDataSourceImpl;


public class SimplePoolDataSourceOracle extends PoolDataSourceImpl implements SimplePoolDataSource {

    public SimplePoolDataSourceOracle(final PoolDataSourceConfigurationOracle pdsConfigurationOracle) throws SQLException {
        super();
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
        
    public String getPoolName() {
        return getConnectionPoolName();
    }

    public void setPoolName(String poolName) throws SQLException {
        setConnectionPoolName(poolName);
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
