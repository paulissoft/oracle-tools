package com.paulissoft.pato.jdbc;

import java.util.concurrent.atomic.AtomicBoolean;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class SmartPoolDataSourceOracle extends CombiPoolDataSourceOracle {

    private static final String POOL_NAME_PREFIX = CombiPoolDataSourceOracle.getPoolNamePrefix();
         
    // Statistics at level 2
    private static final PoolDataSourceStatistics poolDataSourceStatisticsTotal
        = new PoolDataSourceStatistics(() -> POOL_NAME_PREFIX + ": (all)",
                                       PoolDataSourceStatistics.poolDataSourceStatisticsGrandTotal);
       
    // for all smart pool data sources the same
    private static final AtomicBoolean statisticsEnabled = new AtomicBoolean(true);
    
    private final AtomicBoolean firstConnection = new AtomicBoolean(false);    

    // Only the parent (getActiveParent() == null) must have statistics at level 3
    private final PoolDataSourceStatistics parentPoolDataSourceStatistics;

    // Every item must have statistics at level 4
    @NonNull
    private final PoolDataSourceStatistics poolDataSourceStatistics;

    /*
     * Constructors
     */
    
    public SmartPoolDataSourceOracle() {
        final PoolDataSourceStatistics[] fields = updatePoolDataSourceStatistics(null);

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
        log.debug("constructor 1: everything null, INITIALIZING");
    }

    public SmartPoolDataSourceOracle(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle) {
        super(poolDataSourceConfigurationOracle);
        
        final PoolDataSourceStatistics[] fields = updatePoolDataSourceStatistics((SmartPoolDataSourceOracle) getActiveParent());

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
        log.debug("constructor 2: poolDataSourceConfigurationOracle != null (fixed), OPEN");
    }
    
    public SmartPoolDataSourceOracle(@NonNull final SmartPoolDataSourceOracle activeParent) {
        this(new PoolDataSourceConfigurationOracle(), activeParent);
        log.debug("constructor 3: activeParent != null, INITIALIZING");
    }

    public SmartPoolDataSourceOracle(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle,
                                     @NonNull final SmartPoolDataSourceOracle activeParent) {
        super(poolDataSourceConfigurationOracle, activeParent);
        
        final PoolDataSourceStatistics[] fields = updatePoolDataSourceStatistics(activeParent);

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
        log.debug("constructor 4: poolDataSourceConfigurationOracle != null (fixed), activeParent != null, INITIALIZING");
    }
    
    public SmartPoolDataSourceOracle(@NonNull final SmartPoolDataSourceOracle activeParent,
                                     String url,
                                     String username,
                                     String password,
                                     String type)
    {
        this(PoolDataSourceConfigurationOracle.build(url,
                                                     username,
                                                     password,
                                                     type != null ? type : SmartPoolDataSourceOracle.class.getName()),
             activeParent);
        log.debug("constructor 5: connection properties != null (fixed), activeParent != null, INITIALIZING");
    }

    public SmartPoolDataSourceOracle(String url,
                                     String username,
                                     String password,
                                     String type,
                                     String connectionPoolName,
                                     int initialPoolSize,
                                     int minPoolSize,
                                     int maxPoolSize,
                                     String connectionFactoryClassName,
                                     boolean validateConnectionOnBorrow,
                                     int abandonedConnectionTimeout,
                                     int timeToLiveConnectionTimeout,
                                     int inactiveConnectionTimeout,
                                     int timeoutCheckInterval,
                                     int maxStatements,
                                     int connectionWaitTimeout,
                                     long maxConnectionReuseTime,
                                     int secondsToTrustIdleConnection,
                                     int connectionValidationTimeout)
    {
        this(PoolDataSourceConfigurationOracle.build(url,
                                                     username,
                                                     password,
                                                     // cannot reference this before supertype constructor has been called,
                                                     // hence can not use this in constructor above
                                                     type != null ? type : SmartPoolDataSourceOracle.class.getName(),
                                                     connectionPoolName,
                                                     initialPoolSize,
                                                     minPoolSize,
                                                     maxPoolSize,
                                                     connectionFactoryClassName,
                                                     validateConnectionOnBorrow,
                                                     abandonedConnectionTimeout,
                                                     timeToLiveConnectionTimeout,
                                                     inactiveConnectionTimeout,
                                                     timeoutCheckInterval,
                                                     maxStatements,
                                                     connectionWaitTimeout,
                                                     maxConnectionReuseTime,
                                                     secondsToTrustIdleConnection,
                                                     connectionValidationTimeout));
        log.debug("constructor 6: properties != null (fixed), activeParent != null, OPEN");
    }

    @Override
    protected void tearDown() {
        try {
            // close the statistics BEFORE closing the pool data source otherwise you may not use delegated methods
            poolDataSourceStatistics.close();
            if (parentPoolDataSourceStatistics != null) {
                parentPoolDataSourceStatistics.close();
            }

            super.tearDown();
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    /*
     * Connection
     */
    
    @Override
    protected Connection getConnection1(@NonNull final SimplePoolDataSourceOracle poolDataSource,
                                        @NonNull final String usernameSession1,
                                        @NonNull final String passwordSession1) throws SQLException {
        log.debug("getConnection1(usernameSession1={})", usernameSession1);

        try {    
            final Instant t1 = Instant.now();
            final Connection conn = poolDataSource.getConnection(usernameSession1, passwordSession1);
            
            assert !isFixedUsernamePassword() : "For Oracle UCP you should not have a fixed username and password.";

            if (!firstConnection.getAndSet(true)) {
                // Only show the first time a pool has gotten a connection.
                // Not earlier because these (fixed) values may change before and after the first connection.
                show(getPoolDataSourceConfiguration());
            }

            if (statisticsEnabled.get()) {
                poolDataSourceStatistics.updateStatistics(this,
                                                          conn,
                                                          Duration.between(t1, Instant.now()).toMillis(),
                                                          true);
            }

            return conn;
        } catch (SQLException ex) {
            poolDataSourceStatistics.signalSQLException(this, ex);
            throw ex;
        } catch (Exception ex) {
            poolDataSourceStatistics.signalException(this, ex);
            throw ex;
        } finally {
            log.debug("<getConnection1()");
        }
    }

    /*
     * Config
     */
    
    PoolDataSourceConfiguration getCommonPoolDataSourceConfiguration() {
        return getPoolDataSource().get();
    }

    /*
     * Statistics
     */
    
    private PoolDataSourceStatistics[] updatePoolDataSourceStatistics(final SmartPoolDataSourceOracle activeParent) {
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

        log.debug("updatePoolDataSourceStatistics({}) = ({}, {})", activeParent, parentPoolDataSourceStatistics, poolDataSourceStatistics);
        
        return new PoolDataSourceStatistics[]{ parentPoolDataSourceStatistics, poolDataSourceStatistics };
    }

    public static boolean isStatisticsEnabled() {
        return statisticsEnabled.get();
    }

    public static void setStatisticsEnabled(final boolean statisticsEnabled) {
        SmartPoolDataSourceOracle.statisticsEnabled.set(statisticsEnabled);
    }
}
