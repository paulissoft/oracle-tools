package com.paulissoft.pato.jdbc;

import java.util.concurrent.atomic.AtomicBoolean;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import java.util.Properties;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;
import oracle.jdbc.OracleConnection;


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
        return getConnection(getPoolDataSource(), usernameSession1, passwordSession1, usernameSession2, statisticsEnabled.get(), true);
    }

    // A combination of CombiPoolDataSourceHikari.getConnection1() and CombiPoolDataSource.getConnection2()
    private Connection getConnection(final SimplePoolDataSourceHikari poolDataSource,
                                     final String usernameSession1,
                                     final String passwordSession1,
                                     final String usernameSession2,
                                     final boolean updateStatistics,
                                     final boolean showStatistics) throws SQLException {
        log.debug(">getConnection(usernameSession1={}, usernameSession2={}, updateStatistics={}, showStatistics={})",
                  usernameSession1,
                  usernameSession2,
                  updateStatistics,
                  showStatistics);

        try {    
            final Instant t1 = Instant.now();
            Connection conn = getConnection1(poolDataSource, usernameSession1, passwordSession1);
            int proxyLogicalConnectionCount = 0, proxyOpenSessionCount = 0, proxyCloseSessionCount = 0;        
            Instant t2 = null;

            if (!firstConnection.getAndSet(true)) {
                // Only show the first time a pool has gotten a connection.
                // Not earlier because these (fixed) values may change before and after the first connection.
                poolDataSource.show(getPoolDataSourceConfiguration());
            }

            // if the current schema is not the requested schema try to open/close the proxy session
            if (!conn.getSchema().equalsIgnoreCase(usernameSession2)) {
                assert !isSingleSessionProxyModel()
                    : "Requested schema name should be the same as the current schema name in the single-session proxy model";

                t2 = Instant.now();

                OracleConnection oraConn = null;

                try {
                    if (conn.isWrapperFor(OracleConnection.class)) {
                        oraConn = conn.unwrap(OracleConnection.class);
                    }
                } catch (SQLException ex) {
                    oraConn = null;
                }

                if (oraConn != null) {
                    int nr = 0;
                    
                    do {
                        log.debug("current schema: {}; usernameSession2: {}", conn.getSchema(), usernameSession2);

                        switch(nr) {
                        case 0:
                            if (oraConn.isProxySession()) {
                                // go back to the session with the first username
                                oraConn.close(OracleConnection.PROXY_SESSION);
                                oraConn.setSchema(usernameSession1);
                                
                                proxyCloseSessionCount++;
                            }
                            break;
                            
                        case 1:
                            if (!usernameSession1.equals(usernameSession2)) {
                                // open a proxy session with the second username
                                final Properties proxyProperties = new Properties();

                                proxyProperties.setProperty(OracleConnection.PROXY_USER_NAME, usernameSession2);
                                oraConn.openProxySession(OracleConnection.PROXYTYPE_USER_NAME, proxyProperties);        
                                oraConn.setSchema(usernameSession2);
                                
                                proxyOpenSessionCount++;
                            }
                            break;
                            
                        case 2:
                            oraConn.setSchema(usernameSession2);
                            break;
                            
                        default:
                            throw new IllegalArgumentException(String.format("Wrong value for nr (%d): must be between 0 and 2", nr));
                        }
                    } while (!conn.getSchema().equalsIgnoreCase(usernameSession2) && nr++ < 3);
                }                
            }

            if (updateStatistics) {
                if (t2 == null) {
                    poolDataSourceStatistics.updateStatistics(this,
                                                              conn,
                                                              Duration.between(t1, Instant.now()).toMillis(),
                                                              showStatistics);
                } else {
                    poolDataSourceStatistics.updateStatistics(this,
                                                              conn,
                                                              Duration.between(t1, t2).toMillis(),
                                                              Duration.between(t2, Instant.now()).toMillis(),
                                                              showStatistics,
                                                              proxyLogicalConnectionCount,
                                                              proxyOpenSessionCount,
                                                              proxyCloseSessionCount);
                }
            }

            log.debug("<getConnection() = {}", conn);
        
            return conn;
        } catch (SQLException ex) {
            poolDataSourceStatistics.signalSQLException(this, ex);
            log.debug("<getConnection()");
            throw ex;
        } catch (Exception ex) {
            poolDataSourceStatistics.signalException(this, ex);
            log.debug("<getConnection()");
            throw ex;
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
