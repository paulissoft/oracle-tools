package com.paulissoft.pato.jdbc;

import java.time.Instant;
import java.util.concurrent.atomic.AtomicBoolean;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class SmartPoolDataSourceHikari extends OverflowPoolDataSourceHikari implements SmartPoolDataSource {

    private static final String POOL_NAME_PREFIX = SmartPoolDataSourceHikari.class.getSimpleName();
         
    // Statistics at level 2
    private static final PoolDataSourceStatistics poolDataSourceStatisticsTotal
        = new PoolDataSourceStatistics(() -> POOL_NAME_PREFIX + ": (all)",
                                       PoolDataSourceStatistics.poolDataSourceStatisticsGrandTotal);
       
    // for all smart pool data sources the same
    private static final AtomicBoolean statisticsEnabled = new AtomicBoolean(true);
    
    private final AtomicBoolean firstConnection = new AtomicBoolean(false);    

    private volatile PoolDataSourceStatistics parentPoolDataSourceStatistics = null;

    // Every item must have statistics at level 4
    private volatile PoolDataSourceStatistics poolDataSourceStatistics = null;

    private volatile PoolDataSourceStatistics poolDataSourceStatisticsOverflow = null;

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

                assert parentPoolDataSourceStatistics != null;
                assert poolDataSourceStatistics != null;
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
            if (poolDataSourceStatistics != null) {
                poolDataSourceStatistics.signalSQLException(this, ex);
            }
            throw ex;
        } catch (Exception ex) {
            if (poolDataSourceStatistics != null) {
                poolDataSourceStatistics.signalException(this, ex);
            }
            throw ex;
        }

        if (!firstConnection.getAndSet(true)) {
            // Only show the first time a pool has gotten a connection.
            // Not earlier because these (fixed) values may change before and after the first connection.
            getPoolDataSource().show(get());
        }

        if (statisticsEnabled.get()) {
            if (poolDataSourceStatistics != null) {
                poolDataSourceStatistics.updateStatistics(this,
                                                          conn,
                                                          Duration.between(tm, Instant.now()).toMillis(),
                                                          true);
            }
        }

        return conn;
    }

    /*
     * Statistics
     */
    
    private void updatePoolDataSourceStatistics() {
        final PoolDataSourceStatistics[] fields =
            SmartPoolDataSource.updatePoolDataSourceStatistics(getPoolDataSource(),
                                                               hasOverflow() ? getPoolDataSourceOverflow() : null,
                                                               poolDataSourceStatisticsTotal,
                                                               () -> !isOpen());

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
        poolDataSourceStatisticsOverflow = fields[2];
    }

    public static boolean isStatisticsEnabled() {
        return statisticsEnabled.get();
    }

    public static void setStatisticsEnabled(final boolean statisticsEnabled) {
        SmartPoolDataSourceHikari.statisticsEnabled.set(statisticsEnabled);
    }
}
