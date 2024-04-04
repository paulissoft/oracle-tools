package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class SmartPoolDataSourceHikari extends CombiPoolDataSourceHikari {

    private static final String POOL_NAME_PREFIX = CombiPoolDataSourceHikari.POOL_NAME_PREFIX;
         
    // Statistics at level 2
    private static final PoolDataSourceStatistics poolDataSourceStatisticsTotal
        = new PoolDataSourceStatistics(() -> POOL_NAME_PREFIX + ": (all)",
                                       PoolDataSourceStatistics.poolDataSourceStatisticsGrandTotal);
       
    // Only the parent (getActiveParent() == null) must have statistics at level 3
    private final PoolDataSourceStatistics parentPoolDataSourceStatistics;

    // Every item must have statistics at level 4
    @NonNull
    private final PoolDataSourceStatistics poolDataSourceStatistics;

    public SmartPoolDataSourceHikari() {
        // super();
        assert getActiveParent() == null;
        
        final PoolDataSourceStatistics[] fields = updateStatistics(null);

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
    }

    public SmartPoolDataSourceHikari(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari) {
        super(poolDataSourceConfigurationHikari);
        
        final PoolDataSourceStatistics[] fields = updateStatistics((SmartPoolDataSourceHikari) getActiveParent());

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
    }
    
    public SmartPoolDataSourceHikari(@NonNull final SmartPoolDataSourceHikari activeParent) {
        super(activeParent);

        assert getActiveParent() != null;

        final PoolDataSourceStatistics[] fields = updateStatistics(activeParent);

        parentPoolDataSourceStatistics = fields[0];
        poolDataSourceStatistics = fields[1];
    }

    private PoolDataSourceStatistics[] updateStatistics(final SmartPoolDataSourceHikari activeParent) {
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

    PoolDataSourceConfigurationHikari getCommonPoolDataSourceConfiguration() {
        return getCommonPoolDataSourceConfiguration(getPoolDataSource(), true);
    }
    
    PoolDataSourceConfigurationHikari getCommonPoolDataSourceConfiguration(final HikariDataSource hikariDataSource,
                                                                           final boolean excludeNonIdConfiguration) {
        return PoolDataSourceConfigurationHikari
            .builder()
            .driverClassName(hikariDataSource.getDriverClassName())
            .url(hikariDataSource.getJdbcUrl())
            .username(hikariDataSource.getUsername())
            .password(excludeNonIdConfiguration ? null : hikariDataSource.getPassword())
            .type(hikariDataSource.getClass().getName())
            .poolName(excludeNonIdConfiguration ? null : hikariDataSource.getPoolName())
            .maximumPoolSize(hikariDataSource.getMaximumPoolSize())
            .minimumIdle(hikariDataSource.getMinimumIdle())
            .autoCommit(hikariDataSource.isAutoCommit())
            .connectionTimeout(hikariDataSource.getConnectionTimeout())
            .idleTimeout(hikariDataSource.getIdleTimeout())
            .maxLifetime(hikariDataSource.getMaxLifetime())
            .connectionTestQuery(hikariDataSource.getConnectionTestQuery())
            .initializationFailTimeout(hikariDataSource.getInitializationFailTimeout())
            .isolateInternalQueries(hikariDataSource.isIsolateInternalQueries())
            .allowPoolSuspension(hikariDataSource.isAllowPoolSuspension())
            .readOnly(hikariDataSource.isReadOnly())
            .registerMbeans(hikariDataSource.isRegisterMbeans())
            .validationTimeout(hikariDataSource.getValidationTimeout())
            .leakDetectionThreshold(hikariDataSource.getLeakDetectionThreshold())
            .build();
    }
    
    public int getActiveConnections() {
        try {
            return getHikariPoolMXBean().getActiveConnections();
        } catch (NullPointerException ex) {
            return -1;
        }
    }

    public int getIdleConnections() {
        try {
            return getHikariPoolMXBean().getIdleConnections();
        } catch (NullPointerException ex) {
            return -1;
        }
    }

    public int getTotalConnections() {
        try {
            return getHikariPoolMXBean().getTotalConnections();
        } catch (NullPointerException ex) {
            return -1;
        }
    }

    public void show(final PoolDataSourceConfiguration pds) {
        show((PoolDataSourceConfigurationHikari)pds);
    }
    
    private void show(final PoolDataSourceConfigurationHikari pds) {
        final String indentPrefix = PoolDataSourceStatistics.INDENT_PREFIX;

        /* Smart Pool Data Source */
        
        log.info("Properties for smart pool connecting to schema {} via {}", pds.getSchema(), pds.getUsernameToConnectTo());

        /* info from PoolDataSourceConfiguration */
        log.info("{}url: {}", indentPrefix, pds.getUrl());
        log.info("{}username: {}", indentPrefix, pds.getUsername());
        // do not log passwords
        log.info("{}type: {}", indentPrefix, pds.getType());

        /* info from PoolDataSourceConfigurationHikari */
        log.info("{}maximumPoolSize: {}", indentPrefix, pds.getMaximumPoolSize());
        log.info("{}minimumIdle: {}", indentPrefix, pds.getMinimumIdle());
        log.info("{}dataSourceClassName: {}", indentPrefix, pds.getDataSourceClassName());
        log.info("{}autoCommit: {}", indentPrefix, pds.isAutoCommit());
        log.info("{}connectionTimeout: {}", indentPrefix, pds.getConnectionTimeout());
        log.info("{}idleTimeout: {}", indentPrefix, pds.getIdleTimeout());
        log.info("{}maxLifetime: {}", indentPrefix, pds.getMaxLifetime());
        log.info("{}connectionTestQuery: {}", indentPrefix, pds.getConnectionTestQuery());
        log.info("{}initializationFailTimeout: {}", indentPrefix, pds.getInitializationFailTimeout());
        log.info("{}isolateInternalQueries: {}", indentPrefix, pds.isIsolateInternalQueries());
        log.info("{}allowPoolSuspension: {}", indentPrefix, pds.isAllowPoolSuspension());
        log.info("{}readOnly: {}", indentPrefix, pds.isReadOnly());
        log.info("{}registerMbeans: {}", indentPrefix, pds.isRegisterMbeans());
        log.info("{}validationTimeout: {}", indentPrefix, pds.getValidationTimeout());
        log.info("{}leakDetectionThreshold: {}", indentPrefix, pds.getLeakDetectionThreshold());

        /* Common Simple Pool Data Source */
        
        log.info("Properties for common simple pool: {}", getPoolName());
        
        /* info from PoolDataSourceConfiguration */
        log.info("{}driverClassName: {}", indentPrefix, getDriverClassName());
        log.info("{}url: {}", indentPrefix, getJdbcUrl());
        log.info("{}username: {}", indentPrefix, getUsername());
        // do not log passwords
        /* info from PoolDataSourceConfigurationHikari */
        log.info("{}maximumPoolSize: {}", indentPrefix, getMaximumPoolSize());
        log.info("{}minimumIdle: {}", indentPrefix, getMinimumIdle());
        log.info("{}dataSourceClassName: {}", indentPrefix, getDataSourceClassName());
        log.info("{}autoCommit: {}", indentPrefix, isAutoCommit());
        log.info("{}connectionTimeout: {}", indentPrefix, getConnectionTimeout());
        log.info("{}idleTimeout: {}", indentPrefix, getIdleTimeout());
        log.info("{}maxLifetime: {}", indentPrefix, getMaxLifetime());
        log.info("{}connectionTestQuery: {}", indentPrefix, getConnectionTestQuery());
        log.info("{}initializationFailTimeout: {}", indentPrefix, getInitializationFailTimeout());
        log.info("{}isolateInternalQueries: {}", indentPrefix, isIsolateInternalQueries());
        log.info("{}allowPoolSuspension: {}", indentPrefix, isAllowPoolSuspension());
        log.info("{}readOnly: {}", indentPrefix, isReadOnly());
        log.info("{}registerMbeans: {}", indentPrefix, isRegisterMbeans());
        log.info("{}validationTimeout: {}", indentPrefix, getValidationTimeout());
        log.info("{}leakDetectionThreshold: {}", indentPrefix, getLeakDetectionThreshold());
        /*
        log.info("metricRegistry: {}", getMetricRegistry());
        log.info("healthCheckRegistry: {}", getHealthCheckRegistry());
        log.info("catalog: {}", getCatalog());
        log.info("connectionInitSql: {}", getConnectionInitSql());
        log.info("transactionIsolation: {}", getTransactionIsolation());
        log.info("dataSource: {}", getDataSource());
        log.info("schema: {}", getSchema());
        log.info("threadFactory: {}", getThreadFactory());
        log.info("scheduledExecutor: {}", getScheduledExecutor());
        */
    }

    /*
    // one may override this one
    protected Connection getConnection(final String usernameToConnectTo,
                                       final String password,
                                       final String schema,
                                       final String proxyUsername,
                                       final boolean updateStatistics,
                                       final boolean showStatistics) throws SQLException {
        logger.debug(">getConnection(usernameToConnectTo={}, schema={}, proxyUsername={}, updateStatistics={}, showStatistics={})",
                     usernameToConnectTo,
                     schema,
                     proxyUsername,
                     updateStatistics,
                     showStatistics);

        try {    
            final Instant t1 = Instant.now();
            Connection conn;
            int proxyLogicalConnectionCount = 0, proxyOpenSessionCount = 0, proxyCloseSessionCount = 0;        
            Instant t2 = null;
            
            if (isFixedUsernamePassword()) {
                if (!commonPoolDataSource.getUsername().equalsIgnoreCase(usernameToConnectTo)) {
                    commonPoolDataSource.setUsername(usernameToConnectTo);
                    commonPoolDataSource.setPassword(password);
                }
                conn = commonPoolDataSource.getConnection();
            } else {
                // see observations in constructor
                conn = commonPoolDataSource.getConnection(usernameToConnectTo, password);
            }

            if (!firstConnection.getAndSet(true)) {
                // Only show the first time a pool has gotten a connection.
                // Not earlier because these (fixed) values may change before and after the first connection.
                commonPoolDataSource.show(getPoolDataSourceConfiguration());
            }

            // if the current schema is not the requested schema try to open/close the proxy session
            if (!conn.getSchema().equalsIgnoreCase(schema)) {
                assert(!isSingleSessionProxyModel());

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
                        logger.debug("current schema: {}; schema: {}", conn.getSchema(), schema);

                        switch(nr) {
                        case 0:
                            if (oraConn.isProxySession()) {
                                closeProxySession(oraConn, proxyUsername != null ? proxyUsername : schema);
                                proxyCloseSessionCount++;
                            }
                            break;
                            
                        case 1:
                            if (proxyUsername != null) { // proxyUsername is username to connect to
                                assert(proxyUsername.equalsIgnoreCase(usernameToConnectTo));
                        
                                openProxySession(oraConn, schema);
                                proxyOpenSessionCount++;
                            }
                            break;
                            
                        case 2:
                            oraConn.setSchema(schema);
                            break;
                            
                        default:
                            throw new IllegalArgumentException(String.format("Wrong value for nr (%d): must be between 0 and 2", nr));
                        }
                    } while (!conn.getSchema().equalsIgnoreCase(schema) && nr++ < 3);
                }                
            }

            assert(conn.getSchema().equalsIgnoreCase(schema));
            
            showConnection(conn);

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

            logger.debug("<getConnection() = {}", conn);
        
            return conn;
        } catch (SQLException ex) {
            signalSQLException(ex);
            logger.debug("<getConnection()");
            throw ex;
        } catch (Exception ex) {
            signalException(ex);
            logger.debug("<getConnection()");
            throw ex;
        }        
    }    
    */
}
