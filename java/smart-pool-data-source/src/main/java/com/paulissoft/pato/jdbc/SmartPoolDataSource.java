package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Duration;
import java.time.Instant;
import java.util.Properties;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import lombok.experimental.Delegate;
import lombok.Getter;
import lombok.Setter;
import lombok.AccessLevel;
import oracle.jdbc.OracleConnection;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public abstract class SmartPoolDataSource implements SimplePoolDataSource {

    private static final String INDENT_PREFIX = PoolDataSourceStatistics.INDENT_PREFIX;

    private static final String GRAND_TOTAL = PoolDataSourceStatistics.GRAND_TOTAL;

    private static final String TOTAL = PoolDataSourceStatistics.TOTAL;

    private static final Logger logger = LoggerFactory.getLogger(SmartPoolDataSource.class);

    // every constructed item shows up here
    private static final ConcurrentHashMap<PoolDataSourceConfigurationId, SmartPoolDataSource> cacheSmartPoolDataSources = new ConcurrentHashMap<>();

    private static final ConcurrentHashMap<PoolDataSourceConfigurationId, SimplePoolDataSource> cacheSimplePoolDataSources = new ConcurrentHashMap<>();

    static {
        logger.info("Initializing {}", SmartPoolDataSource.class.toString());
    }

    private interface Overrides {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;
    }

    // member fields
    private PoolDataSourceConfiguration pdsConfiguration = null;
        
    @Delegate(excludes=Overrides.class)
    @Getter(AccessLevel.PACKAGE)
    private SimplePoolDataSource commonPoolDataSource = null;

    private PoolDataSourceStatistics pdsStatistics = null;

    // see https://docs.oracle.com/en/database/oracle/oracle-database/19/jajdb/oracle/jdbc/OracleConnection.html
    // true - do not use openProxySession() but use proxyUsername[schema]
    // false - use openProxySession() (two sessions will appear in v$session)
    @Getter
    private boolean singleSessionProxyModel;

    @Getter
    private boolean useFixedUsernamePassword;

    @Getter(AccessLevel.PACKAGE)
    private ConnectInfo connectInfo;

    @Getter
    @Setter
    private boolean statisticsEnabled = false;

    /**
     * Initialize a smart pool data source.
     *
     * The one and only constructor.
     *
     * @param pdsConfiguration            The pool data source configuraion
     * @param commonPoolDataSource        The common pool data source (HikariCP or UCP).
     * @param singleSessionProxyModel
     * @param useFixedUsernamePassword    Only use commonPoolDataSource.getConnection(), never commonPoolDataSource.getConnection(username, password)
     */
    SmartPoolDataSource(final PoolDataSourceConfiguration pdsConfiguration,
                        final SimplePoolDataSource commonPoolDataSource,
                        final boolean singleSessionProxyModel,
                        final boolean useFixedUsernamePassword) throws SQLException {
        logger.info(">SmartPoolDataSource()");

        try {
            assert(pdsConfiguration != null);
            assert(pdsConfiguration.getUsername() != null);
            assert(pdsConfiguration.getPassword() != null);
            assert(commonPoolDataSource != null);

            this.pdsConfiguration = pdsConfiguration;
            this.connectInfo = new ConnectInfo(pdsConfiguration.getUsername(), pdsConfiguration.getPassword());
            this.commonPoolDataSource = commonPoolDataSource;
            this.pdsStatistics = new PoolDataSourceStatistics(this.commonPoolDataSource::getPoolName, commonPoolDataSource.getPoolDataSourceStatistics());
            this.singleSessionProxyModel = singleSessionProxyModel;
            this.useFixedUsernamePassword = useFixedUsernamePassword;

            // Now we have to adjust the username/password of commonPoolDataSource
            // given pool data source username/singleSessionProxyModel/useFixedUsernamePassword.
            //
            // Some observations:
            // 1 - when username does NOT contain proxy info (like "bodomain", not "bc_proxy[bodomain]")
            //     the username to connect must be connectInfo.username (e.g. "bodomain", connectInfo.proxyUsername is null)
            // 2 - else, when singleSessionProxyModel is true,
            //     the username to connect to MUST be connectInfo.username (e.g. "bc_proxy[bodomain]") and
            //     never connectInfo.proxyUsername ("bc_proxy")
            // 3 - else, when singleSessionProxyModel is false,
            //     the username to connect to must be connectInfo.proxyUsername ("bc_proxy") and
            //     then later on OracleConnection.openProxySession() will be invoked to connect to connectInfo.schema.
            //
            // So you use connectInfo.proxyUsername only if not null and when singleSessionProxyModel is false (case 3).
            //
            // A - when useFixedUsernamePassword is true,
            //     every data source having the same common data source MUST use the same username/password to connect to.
            //     Meaning that these properties MUST be part of the commonDataSourceProperties!

            this.commonPoolDataSource.setUsername(this.connectInfo.getUsernameToConnectTo(singleSessionProxyModel));
            this.commonPoolDataSource.setPassword(this.connectInfo.getPassword());
        } finally {
            logger.info("<SmartPoolDataSource()");
        }
    }

    public static SmartPoolDataSource build(final PoolDataSourceConfiguration dataSourceConfiguration,
                                            final PoolDataSourceConfiguration... pdsConfigurations) throws SQLException {
        final Class cls = dataSourceConfiguration.getType();

        if (cls != null && SimplePoolDataSourceOracle.class.isAssignableFrom(cls)) {
            for (PoolDataSourceConfiguration pdsConfiguration: pdsConfigurations) {
                if (pdsConfiguration instanceof PoolDataSourceConfigurationOracle) {
                    final PoolDataSourceConfigurationOracle pdsConfigurationOracle =
                        (PoolDataSourceConfigurationOracle) pdsConfiguration;
                    pdsConfigurationOracle.copy(dataSourceConfiguration);
                        
                    return build(pdsConfigurationOracle);
                }
            }
        } else if (cls != null && SimplePoolDataSourceHikari.class.isAssignableFrom(cls)) {
            for (PoolDataSourceConfiguration pdsConfiguration: pdsConfigurations) {
                if (pdsConfiguration instanceof PoolDataSourceConfigurationHikari) {
                    final PoolDataSourceConfigurationHikari pdsConfigurationHikari =
                        (PoolDataSourceConfigurationHikari) pdsConfiguration;
                    pdsConfigurationHikari.copy(dataSourceConfiguration);
                        
                    return build(pdsConfigurationHikari);
                }
            }
        } else {
            throw new IllegalArgumentException("Unknown type: " + cls);
        }
        
        return null;
    }
    
    /*
     * For both:
     * - build(final PoolDataSourceConfigurationOracle pdsConfiguration) and
     * - build(final PoolDataSourceConfigurationHikari pdsConfiguration)
     *
     * Is this id already cached (as SmartPoolDataSource)?
     * 1. yes: return that one
     * 2. no, but there is a SimplePoolDataSource for its commonId does and join() works: return that one
     * 3. no, but there is a SimplePoolDataSource for its commonId does and join() does NOT work:
     *    create a SimplePoolDataSource and store it as the most specific, i.e. thisId
     * 4. else, create a SimplePoolDataSource and store it as the commonId
     */

    public static SmartPoolDataSource build(final PoolDataSourceConfigurationOracle pdsConfiguration) {
        final PoolDataSourceConfigurationId thisId = new PoolDataSourceConfigurationId(pdsConfiguration, false);
        
        // case 1: if not absent
        return cacheSmartPoolDataSources.computeIfAbsent(thisId, key -> {
                PoolDataSourceConfigurationId commonId = new PoolDataSourceConfigurationId(pdsConfiguration, true);
                SimplePoolDataSourceOracle simplePoolDataSource = null;
                
                // cases 2, 3 and 4
                try {                    
                    if ((simplePoolDataSource = ((SimplePoolDataSourceOracle) cacheSimplePoolDataSources.get(thisId))) == null) {
                        // there is no specific one so try the common one and join() it
                        simplePoolDataSource = ((SimplePoolDataSourceOracle) cacheSimplePoolDataSources.get(commonId));

                        if (simplePoolDataSource != null) {
                            try {
                                // case 2 or 3
                                simplePoolDataSource.join(pdsConfiguration); // must amend pool sizes
                                // case 2
                            } catch (Exception ex) {
                                // case 3
                                simplePoolDataSource = null;
                                commonId = thisId; // join() failed so we must be very specific when we put it into the cache
                            }
                        }
                        if (simplePoolDataSource == null) {
                            simplePoolDataSource = new SimplePoolDataSourceOracle(pdsConfiguration);
                            cacheSimplePoolDataSources.put(commonId, simplePoolDataSource);
                        }
                    }
                    return new SmartPoolDataSourceOracle(pdsConfiguration, simplePoolDataSource);
                } catch (SQLException ex) {
                    throw new RuntimeException(ex.getMessage());
                }
            });
    }

    public static SmartPoolDataSource build(final PoolDataSourceConfigurationHikari pdsConfiguration) {
        final PoolDataSourceConfigurationId thisId = new PoolDataSourceConfigurationId(pdsConfiguration, false);

        // case 1: if not absent
        return cacheSmartPoolDataSources.computeIfAbsent(thisId, key -> {
                PoolDataSourceConfigurationId commonId = new PoolDataSourceConfigurationId(pdsConfiguration, true);
                SimplePoolDataSourceHikari simplePoolDataSource = null;
                
                // cases 2, 3 and 4
                try {                    
                    if ((simplePoolDataSource = ((SimplePoolDataSourceHikari) cacheSimplePoolDataSources.get(thisId))) == null) {
                        // there is no specific one so try the common one and join() it
                        simplePoolDataSource = ((SimplePoolDataSourceHikari) cacheSimplePoolDataSources.get(commonId));

                        if (simplePoolDataSource != null) {
                            try {
                                // case 2 or 3
                                simplePoolDataSource.join(pdsConfiguration); // must amend pool sizes
                                // case 2
                            } catch (Exception ex) {
                                // case 3
                                simplePoolDataSource = null;
                                commonId = thisId; // join() failed so we must be very specific when we put it into the cache
                            }
                        }
                        if (simplePoolDataSource == null) {
                            simplePoolDataSource = new SimplePoolDataSourceHikari(pdsConfiguration);
                            cacheSimplePoolDataSources.put(commonId, simplePoolDataSource);
                        }
                    }
                    return new SmartPoolDataSourceHikari(pdsConfiguration, simplePoolDataSource);
                } catch (SQLException ex) {
                    throw new RuntimeException(ex.getMessage());
                }
            });
    }        

    public void close() {
        logger.debug(">close()");

        try {
            done();
        } catch (Exception ex) {
            logger.error(String.format("{}:", ex.getClass().getSimpleName()), ex);
            ex.printStackTrace(System.err);
            throw ex;
        } finally {
            logger.debug("<close()");
        }
    }

    // returns true if there are no more pool data sources hereafter
    final protected void done() {
        logger.debug(">done()");

        /*
        final boolean lastPoolDataSource = currentPoolCount.get(commonDataSourceProperties).decrementAndGet() == 0;

        try {
            if (statisticsEnabled) {
                final PoolDataSourceStatistics poolDataSourceStatistics = allDataSourceStatistics.get(commonDataSourceStatistics);
                final PoolDataSourceStatistics poolDataSourceStatisticsTotal =
                    commonDataSourceStatisticsTotal != null ? allDataSourceStatistics.get(commonDataSourceStatisticsTotal) : null;

                if (poolDataSourceStatistics != null) {
                    if (poolDataSourceStatisticsTotal == null ||
                        !poolDataSourceStatistics.countersEqual(poolDataSourceStatisticsTotal)) {
                        showDataSourceStatistics(poolDataSourceStatistics, connectInfo.getSchema());
                    }
                    allDataSourceStatistics.remove(commonDataSourceStatistics);
                }

                // show (grand) totals only when it is the last pool data source
                if (poolDataSourceStatisticsTotal != null && lastPoolDataSource) {
                    showDataSourceStatistics(poolDataSourceStatisticsTotal, TOTAL);
                    allDataSourceStatistics.remove(commonDataSourceStatisticsTotal);
                }
            }
            
            if (lastPoolDataSource) {
                logger.info("Closing pool {}", getPoolName());
                poolDataSources.remove(commonDataSourceProperties);
            }
        } catch (Exception ex) {
            logger.error(String.format("{}:", ex.getClass().getSimpleName()), ex);
            logger.debug("<done()");
            throw ex;
        }
        */

        logger.debug("<done()");
    }

    public Connection getConnection() throws SQLException {
        Connection conn;
        
        conn = getConnection(this.connectInfo.getUsernameToConnectTo(singleSessionProxyModel),
                             this.connectInfo.getPassword(),
                             this.connectInfo.getSchema(),
                             this.connectInfo.getProxyUsername(),
                             statisticsEnabled,
                             true);

        logger.debug("getConnection() = {}", conn);

        return conn;
    }

    @Deprecated
    public Connection getConnection(String username, String password) throws SQLException {
        final ConnectInfo connectInfo = new ConnectInfo(username, password);
        Connection conn;

        conn = getConnection(connectInfo.getUsernameToConnectTo(singleSessionProxyModel),
                             connectInfo.getPassword(),
                             connectInfo.getSchema(),
                             connectInfo.getProxyUsername(),
                             statisticsEnabled,
                             true);

        logger.debug("getConnection(username={}) = {}", username, conn);

        return conn;
    }

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
            
            if (useFixedUsernamePassword) {
                if (!commonPoolDataSource.getUsername().equalsIgnoreCase(usernameToConnectTo)) {
                    commonPoolDataSource.setUsername(usernameToConnectTo);
                    commonPoolDataSource.setPassword(password);
                }
                conn = commonPoolDataSource.getConnection();
            } else {
                // see observations in constructor
                conn = commonPoolDataSource.getConnection(usernameToConnectTo, password);
            }

            // if the current schema is not the requested schema try to open/close the proxy session
            if (!conn.getSchema().equalsIgnoreCase(schema)) {
                assert(!singleSessionProxyModel);

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
                            throw new RuntimeException(String.format("Wrong value for nr ({}): must be between 0 and 2", nr));
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

    private static void openProxySession(final OracleConnection oraConn, final String schema) throws SQLException {
        final Properties proxyProperties = new Properties();

        proxyProperties.setProperty(OracleConnection.PROXY_USER_NAME, schema);
        oraConn.openProxySession(OracleConnection.PROXYTYPE_USER_NAME, proxyProperties);        
        oraConn.setSchema(schema);
    }

    private static void closeProxySession(final OracleConnection oraConn, final String proxyUsername) throws SQLException {
        oraConn.close(OracleConnection.PROXY_SESSION);
        oraConn.setSchema(proxyUsername);
    }

    protected void showConnection(final Connection conn) throws SQLException {
        if (!logger.isTraceEnabled()) {
            return;
        }

        logger.trace(">showConnection({})", conn);

        try {
            conn.setAutoCommit(false);

            final OracleConnection oraConn = conn.unwrap(OracleConnection.class);

            logger.trace("current schema = {}; proxy session?: {}",
                         oraConn.getCurrentSchema(),
                         oraConn.isProxySession());
            
            oraConn.getProperties().list(System.out);

            // Prepare a statement to execute the SQL Queries.
            try (final Statement statement = conn.createStatement()) {
                final String newLine = System.getProperty("line.separator");
                final String[] parameters = {
                    null,
                    "AUTHENTICATED_IDENTITY", // 1
                    "AUTHENTICATION_METHOD", // 2
                    "CURRENT_SCHEMA", // 3
                    "CURRENT_USER", // 4
                    "PROXY_USER", // 5
                    "SESSION_USER", // 6
                    "SESSIONID", // 7
                    "SID"  // 8
                };
                final String sessionParametersQuery = String.join(newLine,
                                                                  "select  sys_context('USERENV', '" + parameters[1] + "')",
                                                                  ",       sys_context('USERENV', '" + parameters[2] + "')",
                                                                  ",       sys_context('USERENV', '" + parameters[3] + "')",
                                                                  ",       sys_context('USERENV', '" + parameters[4] + "')",
                                                                  ",       sys_context('USERENV', '" + parameters[5] + "')",
                                                                  ",       sys_context('USERENV', '" + parameters[6] + "')",
                                                                  ",       sys_context('USERENV', '" + parameters[7] + "')",
                                                                  ",       sys_context('USERENV', '" + parameters[8] + "')",
                                                                  "from    dual");
            
                try (final ResultSet resultSet = statement.executeQuery(sessionParametersQuery)) {
                    while (resultSet.next()) {
                        for (int i = 1; i < parameters.length; i++) {
                            logger.trace(parameters[i] + ": " + resultSet.getString(i));
                        }
                    }
                }
            }
        } finally {
            logger.trace("<showConnection()");
        }
    }

    protected void updateStatistics(final Connection conn,
                                    final long timeElapsed,
                                    final boolean showStatistics) {
        final int activeConnections = getActiveConnections();
        final int idleConnections = getIdleConnections();
        final int totalConnections = getTotalConnections();

        try {
            pdsStatistics.update(conn, timeElapsed, activeConnections, idleConnections, totalConnections);
        } catch (Exception e) {
            logger.error("updateStatistics() exception: {}", e.getMessage());
        }

        if (showStatistics) {
            showDataSourceStatistics(connectInfo.getSchema(), timeElapsed, false);
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
            pdsStatistics.update(conn,
                                 timeElapsed,
                                 proxyTimeElapsed,
                                 proxyLogicalConnectionCount,
                                 proxyOpenSessionCount,
                                 proxyCloseSessionCount);
        } catch (Exception e) {
            logger.error("updateStatistics() exception: {}", e.getMessage());
        }

        if (showStatistics) {
            showDataSourceStatistics(connectInfo.getSchema(), timeElapsed, proxyTimeElapsed, false);
        }
    }

    protected void signalException(final Exception ex) {        
        try {
            final long nrOccurrences = 0;

            if (nrOccurrences > 0) {
                pdsStatistics.signalException(ex);
                // show the message
                logger.error("While connecting to {}{} this was occurrence # {} for this exception: (class={}, message={})",
                             connectInfo.getSchema(),
                             ( connectInfo.getProxyUsername() != null ? " (via " + connectInfo.getProxyUsername() + ")" : "" ),
                             nrOccurrences,
                             ex.getClass().getName(),
                             ex.getMessage());
            }
        } catch (Exception e) {
            logger.error("signalException() exception: {}", e.getMessage());
        }
    }

    protected void signalSQLException(final SQLException ex) {        
        try {
            final long nrOccurrences = 0;

            if (nrOccurrences > 0) {
                pdsStatistics.signalSQLException(ex);
                // show the message
                logger.error("While connecting to {}{} this was occurrence # {} for this SQL exception: (class={}, error code={}, SQL state={}, message={})",
                             connectInfo.getSchema(),
                             ( connectInfo.getProxyUsername() != null ? " (via " + connectInfo.getProxyUsername() + ")" : "" ),
                             nrOccurrences,
                             ex.getClass().getName(),
                             ex.getErrorCode(),
                             ex.getSQLState(),
                             ex.getMessage());
            }
        } catch (Exception e) {
            logger.error("signalSQLException() exception: {}", e.getMessage());
        }
    }

    /**
     * Show data source statistics for a schema (or TOTAL/GRAND_TOTAL).
     *
     * Normally first the statistics of a schema are displayed and then the statistics
     * for all schemas in a pool (unless there is just one).
     *
     * From this it follows that first the connectin is displayed (schema and then TOTAL/GRAND_TOTAL) and
     * next the pool size information (TOTAL only).
     *
     * @param poolDataSourceStatistics  The statistics for a schema (or totals)
     * @param timeElapsed             The elapsed time
     * @param proxyTimeElapsed        The elapsed time for proxy connection (after the connection)
     * @param finalCall               Is this the final call?
     * @param schema                  The schema to display after the pool name
     */
    private void showDataSourceStatistics(final String schema) {
        showDataSourceStatistics(schema, -1L, -1L, true);
    }
    
    private void showDataSourceStatistics(final String schema,
                                          final long timeElapsed,
                                          final boolean finalCall) {
        showDataSourceStatistics(schema, timeElapsed, -1L, finalCall);
    }
    
    private void showDataSourceStatistics(final String schema,
                                          final long timeElapsed,
                                          final long proxyTimeElapsed,
                                          final boolean finalCall) {
        assert(pdsStatistics != null);

        pdsStatistics.showStatistics(this, schema, timeElapsed, proxyTimeElapsed, finalCall);
    }

    private static void printDataSourceStatistics(final SimplePoolDataSource poolDataSource, final Logger logger) {
        if (!logger.isDebugEnabled()) {
            return;
        }

        final String prefix = INDENT_PREFIX;
        
        logger.debug("configuration pool data source {}:", poolDataSource.getPoolName());
        logger.debug("{}configuration: {}", prefix, poolDataSource.getPoolDataSourceConfiguration().toString());
        logger.debug("connections pool data source {}:", poolDataSource.getPoolName());
        logger.debug("{}total: {}", prefix, poolDataSource.getTotalConnections());
        logger.debug("{}active: {}", prefix, poolDataSource.getActiveConnections());
        logger.debug("{}idle: {}", prefix, poolDataSource.getIdleConnections());
    }
    
    protected abstract String getPoolNamePrefix();
}
