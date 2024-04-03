package com.paulissoft.pato.jdbc;

import java.util.concurrent.atomic.AtomicBoolean;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
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
       
    // for all smart pool data sources the same
    private static AtomicBoolean statisticsEnabled = new AtomicBoolean(true);
    
    // Only the parent (getActiveParent() == null) must have statistics at level 3
    private final PoolDataSourceStatistics parentPoolDataSourceStatistics;

    // Every item must have statistics at level 4
    @NonNull
    private final PoolDataSourceStatistics poolDataSourceStatistics;

    private AtomicBoolean firstConnection = new AtomicBoolean(false);    

    public SmartPoolDataSourceOracle() {
        // super();
        assert getActiveParent() == null;
        
        final PoolDataSourceStatistics[] fields = updatePoolDataSourceStatistics(null);

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
    }

    public SmartPoolDataSourceOracle(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle) {
        super(poolDataSourceConfigurationOracle);
        
        final PoolDataSourceStatistics[] fields = updatePoolDataSourceStatistics((SmartPoolDataSourceOracle) getActiveParent());

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
    }
    
    public SmartPoolDataSourceOracle(@NonNull final SmartPoolDataSourceOracle activeParent) {
        super(activeParent);

        assert getActiveParent() != null;

        final PoolDataSourceStatistics[] fields = updatePoolDataSourceStatistics(activeParent);

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
    }

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

    @Override
    protected Connection getConnection1(@NonNull final PoolDataSource poolDataSource,
                                        @NonNull final String usernameSession1,
                                        @NonNull final String passwordSession1) throws SQLException {
        log.debug("getConnection1(usernameSession1={}, passwordSession1={})", usernameSession1, passwordSession1);

        return getConnection(poolDataSource, usernameSession1, passwordSession1, statisticsEnabled.get(), true);
    }

    private Connection getConnection(final PoolDataSource poolDataSource,
                                     final String usernameToConnectTo,
                                     final String password,
                                     final boolean updateStatistics,
                                     final boolean showStatistics) throws SQLException {
        log.debug(">getConnection(usernameToConnectTo={}, updateStatistics={}, showStatistics={})",
                  usernameToConnectTo,
                  updateStatistics,
                  showStatistics);

        try {    
            final Instant t1 = Instant.now();
            Connection conn;
            int proxyLogicalConnectionCount = 0, proxyOpenSessionCount = 0, proxyCloseSessionCount = 0;        
            Instant t2 = null;
            
            if (isFixedUsernamePassword()) {
                if (!poolDataSource.getUser().equalsIgnoreCase(usernameToConnectTo)) {
                    poolDataSource.setUser(usernameToConnectTo);
                    poolDataSource.setPassword(password);
                }
                conn = poolDataSource.getConnection();
            } else {
                // see observations in constructor
                conn = poolDataSource.getConnection(usernameToConnectTo, password);
            }

            if (!firstConnection.getAndSet(true)) {
                // Only show the first time a pool has gotten a connection.
                // Not earlier because these (fixed) values may change before and after the first connection.
                show(getPoolDataSourceConfiguration());
            }

            if (updateStatistics) {
                if (t2 == null) {
                    updateStatistics(conn,
                                     Duration.between(t1, Instant.now()).toMillis(),
                                     showStatistics);
                } else {
                    updateStatistics(conn,
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
            signalSQLException(ex);
            log.debug("<getConnection()");
            throw ex;
        } catch (Exception ex) {
            signalException(ex);
            log.debug("<getConnection()");
            throw ex;
        }        
    }    

    public static boolean isStatisticsEnabled() {
        return statisticsEnabled.get();
    }

    public static void setStatisticsEnabled(final boolean statisticsEnabled) {
        SmartPoolDataSourceOracle.statisticsEnabled.set(statisticsEnabled);
    }

    protected void updateStatistics(final Connection conn,
                                    final long timeElapsed,
                                    final boolean showStatistics) {
        try {
            poolDataSourceStatistics.update(conn,
                                            timeElapsed,
                                            getActiveConnections(),
                                            getIdleConnections(),
                                            getTotalConnections());
        } catch (Exception e) {
            log.error(SimplePoolDataSource.exceptionToString(e));
        }

        if (showStatistics) {
            showDataSourceStatistics(timeElapsed, false);
        }
    }

    protected void updateStatistics(final Connection conn,
                                    final long timeElapsed,
                                    final long proxyTimeElapsed,
                                    final boolean showStatistics,
                                    final int proxyLogicalConnectionCount,
                                    final int proxyOpenSessionCount,
                                    final int proxyCloseSessionCount) {
        try {
            poolDataSourceStatistics.update(conn,
                                            timeElapsed,
                                            proxyTimeElapsed,
                                            proxyLogicalConnectionCount,
                                            proxyOpenSessionCount,
                                            proxyCloseSessionCount,
                                            getActiveConnections(),
                                            getIdleConnections(),
                                            getTotalConnections());
        } catch (Exception e) {
            log.error(SimplePoolDataSource.exceptionToString(e));
        }

        if (showStatistics) {
            showDataSourceStatistics(timeElapsed, proxyTimeElapsed, false);
        }
    }

    protected void signalException(final Exception ex) {        
        try {
            final long nrOccurrences = 0;

            if (nrOccurrences > 0) {
                poolDataSourceStatistics.signalException(ex);
                // show the message
                log.error("While connecting to {}{} this was occurrence # {} for this exception: ({})",
                          getPoolDataSourceConfiguration().getSchema(),
                          ( getPoolDataSourceConfiguration().getProxyUsername() != null
                            ? " (via " + getPoolDataSourceConfiguration().getProxyUsername() + ")"
                            : "" ),
                          nrOccurrences,
                          SimplePoolDataSource.exceptionToString(ex));
            }
        } catch (Exception e) {
            log.error(SimplePoolDataSource.exceptionToString(e));
        }
    }

    protected void signalSQLException(final SQLException ex) {        
        try {
            final long nrOccurrences = 0;

            if (nrOccurrences > 0) {
                poolDataSourceStatistics.signalSQLException(ex);
                // show the message
                log.error("While connecting to {}{} this was occurrence # {} for this SQL exception: (error code={}, SQL state={}, {})",
                          getPoolDataSourceConfiguration().getSchema(),
                          ( getPoolDataSourceConfiguration().getProxyUsername() != null
                            ? " (via " + getPoolDataSourceConfiguration().getProxyUsername() + ")"
                            : "" ),
                          nrOccurrences,
                          ex.getErrorCode(),
                          ex.getSQLState(),
                          SimplePoolDataSource.exceptionToString(ex));
            }
        } catch (Exception e) {
            log.error(SimplePoolDataSource.exceptionToString(e));
        }
    }

    /**
     * Show data source statistics.
     *
     * Normally first the statistics of a schema are displayed and then the statistics
     * for all schemas in a pool (unless there is just one).
     *
     * From this it follows that first the connection is displayed.
     *
     * @param timeElapsed             The elapsed time
     * @param proxyTimeElapsed        The elapsed time for proxy connection (after the connection)
     * @param showTotals               Is this the final call?
     */
    private void showDataSourceStatistics(final long timeElapsed,
                                          final boolean showTotals) {
        showDataSourceStatistics(timeElapsed, -1L, showTotals);
    }
    
    private void showDataSourceStatistics(final long timeElapsed,
                                          final long proxyTimeElapsed,
                                          final boolean showTotals) {
        assert(poolDataSourceStatistics != null);

        poolDataSourceStatistics.showStatistics(timeElapsed, proxyTimeElapsed, showTotals);
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
