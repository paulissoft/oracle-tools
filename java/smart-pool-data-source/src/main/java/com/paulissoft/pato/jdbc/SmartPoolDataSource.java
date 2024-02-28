package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import java.io.Closeable;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Duration;
import java.time.Instant;
import java.util.Properties;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Supplier;
import javax.sql.DataSource;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.experimental.Delegate;
import oracle.jdbc.OracleConnection;
import oracle.ucp.jdbc.PoolDataSourceImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class SmartPoolDataSource implements DataSource, Closeable, /*SimplePoolDataSource,*/ ConnectInfo {

    private static final Logger logger = LoggerFactory.getLogger(SmartPoolDataSource.class);

    // every constructed item shows up here
    private static final ConcurrentHashMap<PoolDataSourceConfigurationId, SmartPoolDataSource> cachedSmartPoolDataSources = new ConcurrentHashMap<>();

    private static final ConcurrentHashMap<PoolDataSourceConfigurationId, SimplePoolDataSource> cachedSimplePoolDataSources = new ConcurrentHashMap<>();

    // for all smart pool data sources the same
    private static AtomicBoolean statisticsEnabled = new AtomicBoolean(true);

    static {
        logger.info("Initializing {}", SmartPoolDataSource.class.toString());
    }

    private interface ToOverride {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;

        public PoolDataSourceConfiguration getPoolDataSourceConfiguration();
    }

    // member fields
    @Getter
    @Delegate(types=ConnectInfo.class)
    private PoolDataSourceConfiguration poolDataSourceConfiguration = null;
        
    @Getter(AccessLevel.PACKAGE)
    @Delegate(types=DataSource.class,excludes=ToOverride.class)
    private SimplePoolDataSource commonPoolDataSource = null;

    private AtomicBoolean opened = new AtomicBoolean(false);

    private AtomicBoolean firstConnection = new AtomicBoolean(false);
    
    private PoolDataSourceStatistics pdsStatistics = null;

    // for test purposes
    static void clear() {
        cachedSmartPoolDataSources.clear();
        cachedSimplePoolDataSources.clear();
        PoolDataSourceStatistics.clear();
        SimplePoolDataSourceHikari.clear();
        SimplePoolDataSourceOracle.clear();
    }

    /**
     * Initialize a smart pool data source.
     *
     * The one and only constructor.
     *
     * @param poolDataSourceConfiguration            The pool data source configuraion
     * @param commonPoolDataSource        The common pool data source (HikariCP or UCP).
     */
    private SmartPoolDataSource(final PoolDataSourceConfiguration poolDataSourceConfiguration,
                                final SimplePoolDataSource commonPoolDataSource) {
        logger.debug(">SmartPoolDataSource()");

        try {
            assert(poolDataSourceConfiguration != null);
            assert(poolDataSourceConfiguration.getUsername() != null);
            assert(poolDataSourceConfiguration.getPassword() != null);
            assert(commonPoolDataSource != null);

            this.poolDataSourceConfiguration = poolDataSourceConfiguration.toBuilder().build(); // make a copy
            this.poolDataSourceConfiguration.determineConnectInfo();
            
            this.commonPoolDataSource = commonPoolDataSource;
            this.pdsStatistics = new PoolDataSourceStatistics(() -> this.commonPoolDataSource.getPoolName() + ": (only " +
                                                              this.poolDataSourceConfiguration.getSchema() + ")",
                                                              commonPoolDataSource.getPoolDataSourceStatistics(),
                                                              this::isClosed,
                                                              this::getPoolDataSourceConfiguration);
            this.commonPoolDataSource.setUsername(this.poolDataSourceConfiguration.getUsernameToConnectTo());
            this.commonPoolDataSource.setPassword(this.poolDataSourceConfiguration.getPassword());
            this.commonPoolDataSource.join(this.poolDataSourceConfiguration); // must amend pool sizes
        } catch (SQLException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        } finally {
            logger.debug("<SmartPoolDataSource()");
        }
    }

    public static SmartPoolDataSource build(final PoolDataSourceConfiguration dataSourceConfiguration,
                                            final PoolDataSourceConfiguration... poolDataSourceConfigurations) throws SQLException {
        final Class cls = dataSourceConfiguration.getType();

        logger.debug(">build(type={}) (1)", cls);

        try {
            if (cls != null && PoolDataSourceImpl.class.isAssignableFrom(cls)) {
                for (PoolDataSourceConfiguration poolDataSourceConfiguration: poolDataSourceConfigurations) {
                    if (poolDataSourceConfiguration instanceof PoolDataSourceConfigurationOracle) {
                        // make a copy
                        final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle =
                            (PoolDataSourceConfigurationOracle) poolDataSourceConfiguration.toBuilder().build();
                        poolDataSourceConfigurationOracle.copy(dataSourceConfiguration);

                        return build(poolDataSourceConfigurationOracle);
                    }
                }
            } else if (cls == null || HikariDataSource.class.isAssignableFrom(cls)) {
                for (PoolDataSourceConfiguration poolDataSourceConfiguration: poolDataSourceConfigurations) {
                    if (poolDataSourceConfiguration instanceof PoolDataSourceConfigurationHikari) {
                        // make a copy
                        final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari =
                            (PoolDataSourceConfigurationHikari) poolDataSourceConfiguration.toBuilder().build();
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
    
    public static SmartPoolDataSource build(final PoolDataSourceConfigurationOracle poolDataSourceConfiguration) {
        logger.debug(">build(type={}) (2)", poolDataSourceConfiguration.getType());

        try {
            final SmartPoolDataSource smartPoolDataSource = build(poolDataSourceConfiguration,
                                                                  () -> SimplePoolDataSourceOracle.build(poolDataSourceConfiguration));

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
                                                                  () -> SimplePoolDataSourceHikari.build(poolDataSourceConfiguration));

            smartPoolDataSource.open();

            return smartPoolDataSource;
        } finally {
            logger.debug("<build() (3)");
        }
    }        

    /*
     * For both:
     * - build(final PoolDataSourceConfigurationOracle poolDataSourceConfiguration) and
     * - build(final PoolDataSourceConfigurationHikari poolDataSourceConfiguration)
     *
     * Is thisId already cached (as SmartPoolDataSource)?
     * 1. yes: return that one
     * 2. no, but there is a SimplePoolDataSource for thisId (or commonId and join() works (in constructor)): return that one
     * 3. no, but there is a SimplePoolDataSource for its commonId does and join() does NOT work:
     *    create a SimplePoolDataSource and store it as the most specific, i.e. thisId
     * 4. else, create a SimplePoolDataSource and store it as the commonId
     */

    private static SmartPoolDataSource build(final PoolDataSourceConfiguration poolDataSourceConfiguration,
                                             final Supplier<SimplePoolDataSource> newSimplePoolDataSource) {
        logger.debug(">build(type={}) (4)", poolDataSourceConfiguration.getType());

        try {
            final PoolDataSourceConfigurationId thisId = new PoolDataSourceConfigurationId(poolDataSourceConfiguration);

            logger.debug("thisId: {}", thisId);

            // case 1: if not absent, the computeIfAbsent method will return the value belonging to the key, i.e. thisId
            return cachedSmartPoolDataSources.computeIfAbsent(thisId, key -> {
                PoolDataSourceConfigurationId commonId = new PoolDataSourceConfigurationCommonId(poolDataSourceConfiguration);
                SimplePoolDataSource simplePoolDataSource = null;
                SmartPoolDataSource smartPoolDataSource = null;

                logger.debug("commonId: {}", commonId);

                logger.debug("cases 2, 3 or 4");

                // cases 2, 3 and 4
                if ((simplePoolDataSource = cachedSimplePoolDataSources.get(thisId)) == null) {
                    // there is no specific one so try the common one and join() it by invoking the constructor
                    simplePoolDataSource = cachedSimplePoolDataSources.get(commonId);

                    if (simplePoolDataSource != null) {
                        try {
                            logger.debug("cases 2 or 3");
                            // case 2 or 3
                            smartPoolDataSource = new SmartPoolDataSource(poolDataSourceConfiguration, simplePoolDataSource);
                            logger.debug("case 2");
                            // case 2
                        } catch (Exception ex) {
                            // probably join() failed
                            logger.warn(SimplePoolDataSource.exceptionToString(ex), ex);
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
                    logger.debug("case 2"); // since the simplePoolDataSource is stored for just thisId, join() must have been called before
                }
                assert(simplePoolDataSource != null);
                if (smartPoolDataSource == null) {
                    smartPoolDataSource = new SmartPoolDataSource(poolDataSourceConfiguration, simplePoolDataSource);
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

    final public boolean isClosed() {
        return !opened.get();
    }

    private void open() {
        logger.debug(">open()");

        opened.set(true);
        commonPoolDataSource.open(this.getPoolDataSourceConfiguration());
        
        logger.debug("<open()");
    }

    // to implement interface Closeable
    final public void close() {
        logger.debug(">close()");

        try {
            if (opened.getAndSet(false)) {
                // switched from open to closed:
                // - inform the common pool data source that this item has closed
                // - close statistics
                commonPoolDataSource.close(this.getPoolDataSourceConfiguration());
                pdsStatistics.close();
            }
        } finally {
            logger.debug("<close()");
        }
    }

    public Connection getConnection() throws SQLException {
        checkIsOpen();

        final Connection conn = getConnection(this.poolDataSourceConfiguration.getUsernameToConnectTo(),
                                              this.poolDataSourceConfiguration.getPassword(),
                                              this.poolDataSourceConfiguration.getSchema(),
                                              this.poolDataSourceConfiguration.getProxyUsername(),
                                              statisticsEnabled.get(),
                                              true);

        logger.debug("getConnection() = {}", conn);

        return conn;
    }

    @Deprecated
    public Connection getConnection(String username, String password) throws SQLException {
        checkIsOpen();

        // make a copy
        final PoolDataSourceConfiguration poolDataSourceConfiguration = this.poolDataSourceConfiguration.toBuilder().build();

        poolDataSourceConfiguration.determineConnectInfo(username, password);

        final Connection conn = getConnection(poolDataSourceConfiguration.getUsernameToConnectTo(),
                                              poolDataSourceConfiguration.getPassword(),
                                              poolDataSourceConfiguration.getSchema(),
                                              poolDataSourceConfiguration.getProxyUsername(),
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
            
            if (isUseFixedUsernamePassword()) {
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
                commonPoolDataSource.show();
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

    private void checkIsOpen() {
        if (!opened.get()) {
            throw new IllegalStateException("Smart pool data source (" +
                                            (poolDataSourceConfiguration != null ? poolDataSourceConfiguration.toString() : "UNKNOWN") +
                                            ") must be open.");
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
            pdsStatistics.update(conn,
                                 timeElapsed,
                                 commonPoolDataSource.getActiveConnections(),
                                 commonPoolDataSource.getIdleConnections(),
                                 commonPoolDataSource.getTotalConnections());
        } catch (Exception e) {
            logger.error(SimplePoolDataSource.exceptionToString(e));
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
                                 proxyCloseSessionCount,
                                 commonPoolDataSource.getActiveConnections(),
                                 commonPoolDataSource.getIdleConnections(),
                                 commonPoolDataSource.getTotalConnections());
        } catch (Exception e) {
            logger.error(SimplePoolDataSource.exceptionToString(e));
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
                logger.error("While connecting to {}{} this was occurrence # {} for this exception: ({})",
                             poolDataSourceConfiguration.getSchema(),
                             ( poolDataSourceConfiguration.getProxyUsername() != null ? " (via " + poolDataSourceConfiguration.getProxyUsername() + ")" : "" ),
                             nrOccurrences,
                             SimplePoolDataSource.exceptionToString(ex));
            }
        } catch (Exception e) {
            logger.error(SimplePoolDataSource.exceptionToString(e));
        }
    }

    protected void signalSQLException(final SQLException ex) {        
        try {
            final long nrOccurrences = 0;

            if (nrOccurrences > 0) {
                pdsStatistics.signalSQLException(ex);
                // show the message
                logger.error("While connecting to {}{} this was occurrence # {} for this SQL exception: (error code={}, SQL state={}, {})",
                             poolDataSourceConfiguration.getSchema(),
                             ( poolDataSourceConfiguration.getProxyUsername() != null ? " (via " + poolDataSourceConfiguration.getProxyUsername() + ")" : "" ),
                             nrOccurrences,
                             ex.getErrorCode(),
                             ex.getSQLState(),
                             SimplePoolDataSource.exceptionToString(ex));
            }
        } catch (Exception e) {
            logger.error(SimplePoolDataSource.exceptionToString(e));
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
        assert(pdsStatistics != null);

        pdsStatistics.showStatistics(timeElapsed, proxyTimeElapsed, showTotals);
    }

    protected static int getTotalSmartPoolCount() {
        return cachedSmartPoolDataSources.size();
    }

    protected static int getTotalSimplePoolCount() {
        return cachedSimplePoolDataSources.size();
    }

    @Override
    public boolean equals(Object obj) {
        if (obj == null || !(obj instanceof SmartPoolDataSource)) {
            return false;
        }

        final SmartPoolDataSource other = (SmartPoolDataSource) obj;
        
        return other.getPoolDataSourceConfiguration().equals(this.getPoolDataSourceConfiguration());
    }

    @Override
    public int hashCode() {
        return this.getPoolDataSourceConfiguration().hashCode();
    }

    @Override
    public String toString() {
        return this.getPoolDataSourceConfiguration().toString();
    }
}
