package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Duration;
import java.time.Instant;
import java.util.Properties;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Function;
import java.util.function.Supplier;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.experimental.Delegate;
import oracle.jdbc.OracleConnection;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public abstract class SmartPoolDataSource implements SimplePoolDataSource {

    private static final Logger logger = LoggerFactory.getLogger(SmartPoolDataSource.class);

    // every constructed item shows up here
    private static final ConcurrentHashMap<PoolDataSourceConfigurationId, SmartPoolDataSource> cachedSmartPoolDataSources = new ConcurrentHashMap<>();

    private static final ConcurrentHashMap<PoolDataSourceConfigurationId, SimplePoolDataSource> cachedSimplePoolDataSources = new ConcurrentHashMap<>();

    // for all smart pool data sources the same
    private static AtomicBoolean statisticsEnabled = new AtomicBoolean(false);

    static {
        logger.info("Initializing {}", SmartPoolDataSource.class.toString());
    }

    private interface Excludes {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;

        public PoolDataSourceConfiguration getPoolDataSourceConfiguration();
    }

    // member fields
    @Getter
    private PoolDataSourceConfiguration poolDataSourceConfiguration = null;
        
    private SimplePoolDataSource commonPoolDataSource = null;

    private AtomicBoolean opened = new AtomicBoolean(false);
    
    @Delegate(excludes=Excludes.class)
    SimplePoolDataSource getCommonPoolDataSource() {
        checkIsOpen();
        
        return commonPoolDataSource;
    }   

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

    /**
     * Initialize a smart pool data source.
     *
     * The one and only constructor.
     *
     * @param poolDataSourceConfiguration            The pool data source configuraion
     * @param commonPoolDataSource        The common pool data source (HikariCP or UCP).
     * @param singleSessionProxyModel
     * @param useFixedUsernamePassword    Only use commonPoolDataSource.getConnection(), never commonPoolDataSource.getConnection(username, password)
     */
    SmartPoolDataSource(final PoolDataSourceConfiguration poolDataSourceConfiguration,
                        final SimplePoolDataSource commonPoolDataSource,
                        final boolean singleSessionProxyModel,
                        final boolean useFixedUsernamePassword) {
        logger.debug(">SmartPoolDataSource()");

        try {
            assert(poolDataSourceConfiguration != null);
            assert(poolDataSourceConfiguration.getUsername() != null);
            assert(poolDataSourceConfiguration.getPassword() != null);
            assert(commonPoolDataSource != null);

            this.poolDataSourceConfiguration = poolDataSourceConfiguration;
            this.connectInfo = new ConnectInfo(poolDataSourceConfiguration.getUsername(), poolDataSourceConfiguration.getPassword());
            this.commonPoolDataSource = commonPoolDataSource;
            this.pdsStatistics = new PoolDataSourceStatistics(() -> this.commonPoolDataSource.getPoolName() + ": (only " +  this.connectInfo.getSchema() + ")",
                                                              commonPoolDataSource.getPoolDataSourceStatistics());
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

            this.commonPoolDataSource.join(poolDataSourceConfiguration, this.connectInfo.getSchema()); // must amend pool sizes
        } catch (SQLException ex) {
            throw new RuntimeException(String.format("{}: {}", ex.getClass().getName(), ex.getMessage()));
        } finally {
            logger.debug("<SmartPoolDataSource()");
        }
    }

    public static SmartPoolDataSource build(final PoolDataSourceConfiguration dataSourceConfiguration,
                                            final PoolDataSourceConfiguration... poolDataSourceConfigurations) throws SQLException {
        final Class cls = dataSourceConfiguration.getType();

        logger.debug(">build(type={}) (1)", cls);

        try {
            if (cls != null && SimplePoolDataSourceOracle.class.isAssignableFrom(cls)) {
                for (PoolDataSourceConfiguration poolDataSourceConfiguration: poolDataSourceConfigurations) {
                    if (poolDataSourceConfiguration instanceof PoolDataSourceConfigurationOracle) {
                        final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle =
                            (PoolDataSourceConfigurationOracle) poolDataSourceConfiguration;
                        poolDataSourceConfigurationOracle.copy(dataSourceConfiguration);
                        
                        return build(poolDataSourceConfigurationOracle);
                    }
                }
            } else if (cls != null && SimplePoolDataSourceHikari.class.isAssignableFrom(cls)) {
                for (PoolDataSourceConfiguration poolDataSourceConfiguration: poolDataSourceConfigurations) {
                    if (poolDataSourceConfiguration instanceof PoolDataSourceConfigurationHikari) {
                        final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari =
                            (PoolDataSourceConfigurationHikari) poolDataSourceConfiguration;
                        poolDataSourceConfigurationHikari.copy(dataSourceConfiguration);
                        
                        return build(poolDataSourceConfigurationHikari);
                    }
                }
            } else {
                throw new IllegalArgumentException("Unknown type: " + cls);
            }
        } finally {
            logger.debug("<build() (1)");
        }

        return null;
    }
    
    /*
     * For both:
     * - build(final PoolDataSourceConfigurationOracle poolDataSourceConfiguration) and
     * - build(final PoolDataSourceConfigurationHikari poolDataSourceConfiguration)
     *
     * Is this id already cached (as SmartPoolDataSource)?
     * 1. yes: return that one
     * 2. no, but there is a SimplePoolDataSource for its Id (or commonId and join() works (in constructor)): return that one
     * 3. no, but there is a SimplePoolDataSource for its commonId does and join() does NOT work:
     *    create a SimplePoolDataSource and store it as the most specific, i.e. thisId
     * 4. else, create a SimplePoolDataSource and store it as the commonId
     */

    public static SmartPoolDataSource build(final PoolDataSourceConfigurationOracle poolDataSourceConfiguration) {
        logger.debug(">build(type={}) (2)", poolDataSourceConfiguration.getType());

        try {
            final SmartPoolDataSource smartPoolDataSource = build(poolDataSourceConfiguration,
                                                                  () -> SimplePoolDataSourceOracle.build(poolDataSourceConfiguration),
                                                                  p -> SmartPoolDataSourceOracle.build(poolDataSourceConfiguration,
                                                                                                       (SimplePoolDataSourceOracle) p));

            smartPoolDataSource.open();

            return smartPoolDataSource;
        } finally {
            logger.debug("<build() (2)");
        }
    }

    public static SmartPoolDataSource build(final PoolDataSourceConfigurationHikari poolDataSourceConfiguration) {
        logger.debug(">build(type={}) (3)", poolDataSourceConfiguration.getType());

        try {
            final SmartPoolDataSource smartPoolDataSource = build(poolDataSourceConfiguration,
                                                                  () -> SimplePoolDataSourceHikari.build(poolDataSourceConfiguration),
                                                                  p -> SmartPoolDataSourceHikari.build(poolDataSourceConfiguration,
                                                                                                       (SimplePoolDataSourceHikari) p));

            smartPoolDataSource.open();

            return smartPoolDataSource;
        } finally {
            logger.debug("<build() (3)");
        }
    }        

    private static SmartPoolDataSource build(final PoolDataSourceConfiguration poolDataSourceConfiguration,
                                             final Supplier<SimplePoolDataSource> newSimplePoolDataSource,
                                             final Function<SimplePoolDataSource, SmartPoolDataSource> newSmartPoolDataSource) {
        logger.debug(">build(type={}) (4)", poolDataSourceConfiguration.getType());

        try {
            final PoolDataSourceConfigurationId thisId = new PoolDataSourceConfigurationId(poolDataSourceConfiguration, false);

            logger.debug("thisId: {}", thisId);

            // case 1: if not absent
            return cachedSmartPoolDataSources.computeIfAbsent(thisId, key -> {
                PoolDataSourceConfigurationId commonId = new PoolDataSourceConfigurationId(poolDataSourceConfiguration, true);
                SimplePoolDataSource simplePoolDataSource = null;
                SmartPoolDataSource smartPoolDataSource = null;

                logger.debug("commonId: {}", commonId);

                logger.debug("cases 2, 3 or 4");

                // cases 2, 3 and 4
                if ((simplePoolDataSource = cachedSimplePoolDataSources.get(thisId)) == null) {
                    // there is no specific one so try the common one and join() it
                    simplePoolDataSource = cachedSimplePoolDataSources.get(commonId);

                    if (simplePoolDataSource != null) {
                        try {
                            logger.debug("cases 2 or 3");
                            // case 2 or 3
                            smartPoolDataSource = newSmartPoolDataSource.apply(simplePoolDataSource);
                            logger.debug("case 2");
                            // case 2
                        } catch (Exception ex) {
                            logger.debug("case 3");
                            // case 3
                            simplePoolDataSource = null;
                            commonId = thisId; // join() failed so we must be very specific when we put it into the cache
                        }
                    } else {
                        logger.debug("case 4");
                    }
                    if (simplePoolDataSource == null) {
                        simplePoolDataSource = newSimplePoolDataSource.get();
                        cachedSimplePoolDataSources.put(commonId, simplePoolDataSource);
                    }
                } else {
                    logger.debug("case 2"); // since the simplePoolDataSource is stored for just this Id, join() must have been called before
                }
                assert(simplePoolDataSource != null);
                if (smartPoolDataSource == null) {
                    smartPoolDataSource = newSmartPoolDataSource.apply(simplePoolDataSource);
                }
                return smartPoolDataSource;
            });
        } finally {
            logger.debug("<build() (4)");
        }            
    }

    public static boolean isStatisticsEnabled() {
        return statisticsEnabled.get();
    }

    public static void setStatisticsEnabled(final boolean statisticsEnabled) {
        SmartPoolDataSource.statisticsEnabled.set(statisticsEnabled);
    }

    private void checkIsOpen() {
        if (!opened.get()) {
            throw new IllegalStateException(String.format("Smart pool data source ({}) must be open.",
                                                          poolDataSourceConfiguration != null ? poolDataSourceConfiguration.toString() : "UNKNOWN"));
        }
    }

    private void open() {
        logger.debug(">open()");

        if (!opened.getAndSet(true)) {
            // old value was false: give the parent a sign that this one has just opened
            commonPoolDataSource.open(poolDataSourceConfiguration);
        }
        
        logger.debug("<open()");
    }

    // to implement interface Closeable
    final public void close() {
        logger.debug(">close()");

        try {
            if (opened.getAndSet(false)) {
                // old value was true: give the parent a sign that this one has just closed
                final boolean statisticsEnabled = isStatisticsEnabled();
                
                if (statisticsEnabled) {
                    showDataSourceStatistics();
                }
                commonPoolDataSource.close(poolDataSourceConfiguration, statisticsEnabled);
            }
        } catch (Exception ex) {
            logger.error(String.format("{}:", ex.getClass().getName()), ex);
            ex.printStackTrace(System.err);
            throw ex;
        } finally {
            logger.debug("<close()");
        }
    }

    public Connection getConnection() throws SQLException {
        checkIsOpen();

        Connection conn;
        
        conn = getConnection(this.connectInfo.getUsernameToConnectTo(singleSessionProxyModel),
                             this.connectInfo.getPassword(),
                             this.connectInfo.getSchema(),
                             this.connectInfo.getProxyUsername(),
                             statisticsEnabled.get(),
                             true);

        logger.debug("getConnection() = {}", conn);

        return conn;
    }

    @Deprecated
    public Connection getConnection(String username, String password) throws SQLException {
        checkIsOpen();
        
        final ConnectInfo connectInfo = new ConnectInfo(username, password);
        Connection conn;

        conn = getConnection(connectInfo.getUsernameToConnectTo(singleSessionProxyModel),
                             connectInfo.getPassword(),
                             connectInfo.getSchema(),
                             connectInfo.getProxyUsername(),
                             statisticsEnabled.get(),
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
                            throw new IllegalArgumentException(String.format("Wrong value for nr ({}): must be between 0 and 2", nr));
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
        try {
            pdsStatistics.update(conn, timeElapsed);
            commonPoolDataSource.updateStatistics();
        } catch (Exception e) {
            logger.error("updateStatistics() exception: {}", e.getMessage());
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
            pdsStatistics.update(conn,
                                 timeElapsed,
                                 proxyTimeElapsed,
                                 proxyLogicalConnectionCount,
                                 proxyOpenSessionCount,
                                 proxyCloseSessionCount);
            commonPoolDataSource.updateStatistics();
        } catch (Exception e) {
            logger.error("updateStatistics() exception: {}", e.getMessage());
        }

        if (showStatistics) {
            showDataSourceStatistics(timeElapsed, proxyTimeElapsed, false);
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
    private void showDataSourceStatistics() {
        showDataSourceStatistics(-1L, -1L, true);
    }
    
    private void showDataSourceStatistics(final long timeElapsed,
                                          final boolean showTotals) {
        showDataSourceStatistics(timeElapsed, -1L, showTotals);
    }
    
    private void showDataSourceStatistics(final long timeElapsed,
                                          final long proxyTimeElapsed,
                                          final boolean showTotals) {
        assert(pdsStatistics != null);

        pdsStatistics.showStatistics(this, timeElapsed, proxyTimeElapsed, showTotals);
    }

    protected static int getTotalSmartPoolCount() {
        return cachedSmartPoolDataSources.size();
    }

    protected static int getTotalSimplePoolCount() {
        return cachedSimplePoolDataSources.size();
    }
}
