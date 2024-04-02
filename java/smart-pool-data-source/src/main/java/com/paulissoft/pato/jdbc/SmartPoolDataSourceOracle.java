package com.paulissoft.pato.jdbc;

import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;
import oracle.ucp.jdbc.PoolDataSource;


@Slf4j
public class SmartPoolDataSourceOracle extends CombiPoolDataSourceOracle {

    private static final String POOL_NAME_PREFIX = CombiPoolDataSourceOracle.POOL_NAME_PREFIX;
         
    // Statistics at level 2
    private static final PoolDataSourceStatistics poolDataSourceStatisticsTotal
        = new PoolDataSourceStatistics(() -> POOL_NAME_PREFIX + ": (all)",
                                       PoolDataSourceStatistics.poolDataSourceStatisticsGrandTotal);
       
    // Only the parent (getActiveParent() == null) must have statistics at level 3
    private final PoolDataSourceStatistics parentPoolDataSourceStatistics;

    // Every item must have statistics at level 4
    @NonNull
    private final PoolDataSourceStatistics poolDataSourceStatistics;

    public SmartPoolDataSourceOracle() {
        // super();
        assert getActiveParent() == null;
        
        final PoolDataSourceStatistics[] fields = updateStatistics(null);

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
    }

    public SmartPoolDataSourceOracle(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle) {
        super(poolDataSourceConfigurationOracle);
        
        final PoolDataSourceStatistics[] fields = updateStatistics((SmartPoolDataSourceOracle) getActiveParent());

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
    }
    
    public SmartPoolDataSourceOracle(@NonNull final SmartPoolDataSourceOracle activeParent) {
        super(activeParent);

        assert getActiveParent() != null;

        final PoolDataSourceStatistics[] fields = updateStatistics(activeParent);

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
    }

    private PoolDataSourceStatistics[] updateStatistics(final SmartPoolDataSourceOracle activeParent) {
        // level 3        
        final PoolDataSourceStatistics parentPoolDataSourceStatistics =
            activeParent == null
            ? new PoolDataSourceStatistics(() -> this.getConnectionPoolName() + ": (all)",
                                           poolDataSourceStatisticsTotal,
                                           () -> getState() != CombiPoolDataSource.State.OPEN,
                                           this::getCommonPoolDataSourceConfiguration)
            : activeParent.parentPoolDataSourceStatistics;
        
        // level 4
        final PoolDataSourceStatistics poolDataSourceStatistics =
            new PoolDataSourceStatistics(() -> this.getPoolDataSourceConfiguration().getPoolName() + ": (only " +
                                         this.getPoolDataSourceConfiguration().getSchema() + ")",
                                         parentPoolDataSourceStatistics, // level 3
                                         () -> getState() != CombiPoolDataSource.State.OPEN,
                                         this::getPoolDataSourceConfiguration);

        return new PoolDataSourceStatistics[]{ parentPoolDataSourceStatistics, poolDataSourceStatistics };
    }

    PoolDataSourceConfigurationOracle getCommonPoolDataSourceConfiguration() {
        return getCommonPoolDataSourceConfiguration(getPoolDataSource(), true);
    }
    
    static PoolDataSourceConfigurationOracle getCommonPoolDataSourceConfiguration(final PoolDataSource oracleDataSource,
                                                                           final boolean excludeNonIdConfiguration) {
        return PoolDataSourceConfigurationOracle
            .builder()
            .driverClassName(null)
            .url(oracleDataSource.getURL())
            .username(oracleDataSource.getUser())
            .password(excludeNonIdConfiguration ? null : oracleDataSource.getPassword())
            .type(oracleDataSource.getClass().getName())
            .connectionPoolName(excludeNonIdConfiguration ? null : oracleDataSource.getConnectionPoolName())
            .initialPoolSize(oracleDataSource.getInitialPoolSize())
            .minPoolSize(oracleDataSource.getMinPoolSize())
            .maxPoolSize(oracleDataSource.getMaxPoolSize())
            .connectionFactoryClassName(oracleDataSource.getConnectionFactoryClassName())
            .validateConnectionOnBorrow(oracleDataSource.getValidateConnectionOnBorrow())
            .abandonedConnectionTimeout(oracleDataSource.getAbandonedConnectionTimeout())
            .timeToLiveConnectionTimeout(oracleDataSource.getTimeToLiveConnectionTimeout())
            .inactiveConnectionTimeout(oracleDataSource.getInactiveConnectionTimeout())
            .timeoutCheckInterval(oracleDataSource.getTimeoutCheckInterval())
            .maxStatements(oracleDataSource.getMaxStatements())
            .connectionWaitTimeout(oracleDataSource.getConnectionWaitTimeout())
            .maxConnectionReuseTime(oracleDataSource.getMaxConnectionReuseTime())
            .secondsToTrustIdleConnection(oracleDataSource.getSecondsToTrustIdleConnection())
            .connectionValidationTimeout(oracleDataSource.getConnectionValidationTimeout())
            .build();
    }

    public PoolDataSourceStatistics getPoolDataSourceStatistics() {
        return poolDataSourceStatistics;
    }

    // connection statistics
    
    public int getActiveConnections() {
        try {
            return getBorrowedConnectionsCount();
        } catch (Exception ex) {
            return -1;
        }
    }

    public int getIdleConnections() {
        try {
            return getAvailableConnectionsCount();
        } catch (Exception ex) {
            return -1;
        }
    }

    public int getTotalConnections() {
        return Integer.max(getActiveConnections(), 0) + Integer.max(getIdleConnections(), 0);
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
}
