package com.paulissoft.pato.jdbc;

import java.time.Instant;
import java.util.concurrent.atomic.AtomicBoolean;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class SmartPoolDataSourceHikari extends OverflowPoolDataSourceHikari {

    private static final String POOL_NAME_PREFIX = SmartPoolDataSourceHikari.class.getSimpleName();
         
    // Statistics at level 2
    private static final PoolDataSourceStatistics poolDataSourceStatisticsTotal
        = new PoolDataSourceStatistics(() -> POOL_NAME_PREFIX + ": (all)",
                                       PoolDataSourceStatistics.poolDataSourceStatisticsGrandTotal);
       
    // for all smart pool data sources the same
    private static final AtomicBoolean statisticsEnabled = new AtomicBoolean(true);
    
    private final AtomicBoolean firstConnection = new AtomicBoolean(false);    

    private volatile PoolDataSourceStatistics parentPoolDataSourceStatistics;

    // Every item must have statistics at level 4
    private volatile PoolDataSourceStatistics poolDataSourceStatistics;

    private volatile PoolDataSourceStatistics poolDataSourceStatisticsOverflow;

    /*
     * Constructor(s)
     */
    
    public SmartPoolDataSourceHikari() {
    }

    public SmartPoolDataSourceHikari(String driverClassName,
                                     String url,
                                     String username,
                                     String password,
                                     String type) {
        set(PoolDataSourceConfigurationHikari.build(driverClassName,
                                                    url,
                                                    username,
                                                    password,
                                                    type != null ? type : CombiPoolDataSourceHikari.class.getName()));
    }

    @Override
    protected void setUp() {
        try {
            if (getState() == State.INITIALIZING) {
                updatePoolDataSourceStatistics();
            }
            super.setUp();
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }
    
    @Override
    protected void tearDown() {
        try {
            // close the statistics BEFORE closing the pool data source otherwise you may not use delegated methods
            if (poolDataSourceStatistics != null) {
                poolDataSourceStatistics.close();
            }
            if (poolDataSourceStatisticsOverflow != null) {
                poolDataSourceStatisticsOverflow.close();
            }
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
    protected Connection getConnection(final boolean useOverflow) throws SQLException {
        final Instant tm = Instant.now();
        Connection conn = null;

        try {
            conn = super.getConnection(useOverflow);
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
            getPoolDataSource().show(get());
        }

        if (statisticsEnabled.get()) {
            poolDataSourceStatistics.updateStatistics(this,
                                                      conn,
                                                      Duration.between(tm, Instant.now()).toMillis(),
                                                      true);
        }

        return conn;
    }

    /*
     * Statistics
     */
    
    private void updatePoolDataSourceStatistics() {
        final PoolDataSourceConfigurationHikari pdsConfig =
            (PoolDataSourceConfigurationHikari) getPoolDataSource().get();

        pdsConfig.determineConnectInfo(); // determine schema

        // level 3        
        parentPoolDataSourceStatistics =
            new PoolDataSourceStatistics(() -> this.getPoolDescription() + ": (all)",
                                         poolDataSourceStatisticsTotal,
                                         () -> !isOpen(),
                                         this::get);
        
        // level 4
        poolDataSourceStatistics =
            new PoolDataSourceStatistics(() -> this.getPoolDescription() + ": (only " +
                                         pdsConfig.getSchema() + ")",
                                         parentPoolDataSourceStatistics, // level 3
                                         () -> !isOpen(),
                                         this::get);

        // level 4
        poolDataSourceStatisticsOverflow =
            !hasOverflow() ?
            null :
            new PoolDataSourceStatistics(() -> this.getPoolDescription() + ": (only " +
                                         pdsConfig.getSchema() + ")",
                                         parentPoolDataSourceStatistics, // level 3
                                         () -> !isOpen(),
                                         this::get);
    }

    public static boolean isStatisticsEnabled() {
        return statisticsEnabled.get();
    }

    public static void setStatisticsEnabled(final boolean statisticsEnabled) {
        SmartPoolDataSourceHikari.statisticsEnabled.set(statisticsEnabled);
    }
}
