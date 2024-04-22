package com.paulissoft.pato.jdbc;

import java.util.concurrent.atomic.AtomicBoolean;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class SmartPoolDataSourceHikari extends CombiPoolDataSourceHikari {

    private static final String POOL_NAME_PREFIX = CombiPoolDataSourceHikari.POOL_NAME_PREFIX;
         
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
    
    public SmartPoolDataSourceHikari() {
        final PoolDataSourceStatistics[] fields = updatePoolDataSourceStatistics(null);

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
    }

    public SmartPoolDataSourceHikari(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari) {
        super(poolDataSourceConfigurationHikari);
        
        final PoolDataSourceStatistics[] fields = updatePoolDataSourceStatistics((SmartPoolDataSourceHikari) getActiveParent());

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
    }
    
    public SmartPoolDataSourceHikari(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari,
                                     @NonNull final SmartPoolDataSourceHikari activeParent) {
        super(poolDataSourceConfigurationHikari, activeParent);
        
        final PoolDataSourceStatistics[] fields = updatePoolDataSourceStatistics(activeParent);

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
    }
    
    public SmartPoolDataSourceHikari(@NonNull final SmartPoolDataSourceHikari activeParent) {
        this(new PoolDataSourceConfigurationHikari(), activeParent);
    }

    public SmartPoolDataSourceHikari(@NonNull final SmartPoolDataSourceHikari activeParent,
                                     String driverClassName,
                                     String url,
                                     String username,
                                     String password,
                                     String type) {
        this(PoolDataSourceConfigurationHikari.build(driverClassName,
                                                     url,
                                                     username,
                                                     password,
                                                     type != null ? type : SmartPoolDataSourceHikari.class.getName()),
             activeParent);
    }

    public SmartPoolDataSourceHikari(String driverClassName,
                                     String url,
                                     String username,
                                     String password,
                                     String type,
                                     String poolName,
                                     int maximumPoolSize,
                                     int minimumIdle,
                                     String dataSourceClassName,
                                     boolean autoCommit,
                                     long connectionTimeout,
                                     long idleTimeout,
                                     long maxLifetime,
                                     String connectionTestQuery,
                                     long initializationFailTimeout,
                                     boolean isolateInternalQueries,
                                     boolean allowPoolSuspension,
                                     boolean readOnly,
                                     boolean registerMbeans,    
                                     long validationTimeout,
                                     long leakDetectionThreshold) {
        this(PoolDataSourceConfigurationHikari.build(driverClassName,
                                                     url,
                                                     username,
                                                     password,
                                                     type != null ? type : SmartPoolDataSourceHikari.class.getName(),
                                                     poolName,
                                                     maximumPoolSize,
                                                     minimumIdle,
                                                     dataSourceClassName,
                                                     autoCommit,
                                                     connectionTimeout,
                                                     idleTimeout,
                                                     maxLifetime,
                                                     connectionTestQuery,
                                                     initializationFailTimeout,
                                                     isolateInternalQueries,
                                                     allowPoolSuspension,
                                                     readOnly,
                                                     registerMbeans,    
                                                     validationTimeout,
                                                     leakDetectionThreshold));
    }

    /*
     * Connection
     */

    @Override
    protected Connection getConnection(@NonNull final SimplePoolDataSourceHikari poolDataSource,
                                       @NonNull final String usernameSession1,
                                       @NonNull final String passwordSession1,
                                       @NonNull final String usernameSession2) throws SQLException {
        final Instant tm[] = new Instant[2];
        final int counters[] = new int[3];
        Connection conn = null;

        try {
            conn = getConnection2(poolDataSource,
                                  usernameSession1,
                                  passwordSession1,
                                  usernameSession2,
                                  getActiveChildren(),
                                  tm,
                                  counters);
        } catch (SQLException ex) {
            poolDataSourceStatistics.signalSQLException(this, ex);
            throw ex;
        } catch (Exception ex) {
            poolDataSourceStatistics.signalException(this, ex);
            throw ex;
        }

        if (!firstConnection.getAndSet(true)) {
            // Only show the first time a pool has gotten a connection.
            // Not earlier because these (fixed) values may change before and after the first connection.
            poolDataSource.show(getPoolDataSourceConfiguration());
        }

        if (statisticsEnabled.get()) {
            if (tm[1] == null) {
                poolDataSourceStatistics.updateStatistics(this,
                                                          conn,
                                                          Duration.between(tm[0], Instant.now()).toMillis(),
                                                          true);
            } else {
                poolDataSourceStatistics.updateStatistics(this,
                                                          conn,
                                                          Duration.between(tm[0], tm[1]).toMillis(),
                                                          Duration.between(tm[1], Instant.now()).toMillis(),
                                                          true,
                                                          counters[0],
                                                          counters[1],
                                                          counters[2]);
            }
        }

        return conn;
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
    
    private PoolDataSourceStatistics[] updatePoolDataSourceStatistics(final SmartPoolDataSourceHikari activeParent) {
        // level 3        
        final PoolDataSourceStatistics parentPoolDataSourceStatistics =
            activeParent == null
            ? new PoolDataSourceStatistics(() -> this.getPoolName() + ": (all)",
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

    public static boolean isStatisticsEnabled() {
        return statisticsEnabled.get();
    }

    public static void setStatisticsEnabled(final boolean statisticsEnabled) {
        SmartPoolDataSourceHikari.statisticsEnabled.set(statisticsEnabled);
    }
}
