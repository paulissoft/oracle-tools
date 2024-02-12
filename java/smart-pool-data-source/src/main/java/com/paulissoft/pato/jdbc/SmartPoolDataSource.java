package com.paulissoft.pato.jdbc;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Map;
import java.util.Properties;
import java.util.Hashtable;
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

    public static final String INDENT_PREFIX = "* ";

    private static final String GRAND_TOTAL = "grand total";

    private static final String TOTAL = "total";

    private static final Logger logger = LoggerFactory.getLogger(SmartPoolDataSource.class);

    private static Method loggerInfo;

    private static Method loggerDebug;

    private static final Hashtable<String, Object> commonDataSourceStatisticsGrandTotal = new Hashtable<>();

    private static final ConcurrentHashMap<Hashtable<String, Object>, PoolDataSourceStatistics> allDataSourceStatistics = new ConcurrentHashMap<>();

    private static final ConcurrentHashMap<Hashtable<String, Object>, SimplePoolDataSource> poolDataSources = new ConcurrentHashMap<>();

    private static final ConcurrentHashMap<Hashtable<String, Object>, AtomicInteger> currentPoolCount = new ConcurrentHashMap<>();    

    static {
        logger.info("Initializing {}", SmartPoolDataSource.class.toString());
        
        try {
            loggerInfo = logger.getClass().getMethod("info", String.class, Object[].class);
        } catch (Exception e) {
            logger.error("static exception: {}", e.getMessage());
            loggerInfo = null;
        }

        try {
            loggerDebug = logger.getClass().getMethod("debug", String.class, Object[].class);
        } catch (Exception e) {
            logger.error("static exception: {}", e.getMessage());
            loggerDebug = null;
        }

        setProperty(commonDataSourceStatisticsGrandTotal, USERNAME, GRAND_TOTAL);
    }

    private interface Overrides {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;
    }
    
    @Delegate(excludes=Overrides.class)
    @Getter(AccessLevel.PACKAGE)
    private SimplePoolDataSource commonPoolDataSource = null;

    private SimplePoolDataSource pds = null; // may be equal to commonPoolDataSource

    @Getter
    @Setter
    private boolean statisticsEnabled = false;

    // see https://docs.oracle.com/en/database/oracle/oracle-database/19/jajdb/oracle/jdbc/OracleConnection.html
    // true - do not use openProxySession() but use proxyUsername[schema]
    // false - use openProxySession() (two sessions will appear in v$session)
    @Getter
    private boolean singleSessionProxyModel;

    @Getter
    private boolean useFixedUsernamePassword;

    private ConnectInfo connectInfo;

    // Same common properties for a pool data source in constructor: same commonPoolDataSource
    private final Hashtable<String, Object> commonDataSourceProperties = new Hashtable<String, Object>();

    // Same as commonDataSourceProperties, i.e. total per common pool data source.
    private final Hashtable<String, Object> commonDataSourceStatisticsTotal = new Hashtable<String, Object>();

    // Same as commonDataSourceProperties including current schema and password,
    // only for connection info like elapsed time, open/close sessions.
    private final Hashtable<String, Object> commonDataSourceStatistics = new Hashtable<String, Object>();

    /**
     * Initialize a pool data source.
     *
     * The one and only constructor.
     *
     * @param pds                         A pool data source (HikariCP or UCP).
     * @param commonDataSourceProperties  The properties of the pool data source that have to be equal to create a common pool data source.
     *                                    Mandatory properties: CLASS and URL.
     * @param username                    The username to connect to for this pool data source, may be a proxy username like BC_PROXY[BDOMAIN].
     * @param password                    The password.
     * @param singleSessionProxyModel
     * @param useFixedUsernamePassword    Only use commonPoolDataSource.getConnection(), never commonPoolDataSource.getConnection(username, password)
     */
    protected SmartPoolDataSource(final SimplePoolDataSource pds,
                                  final String username,
                                  final String password,
                                  final boolean singleSessionProxyModel,
                                  final boolean useFixedUsernamePassword) throws SQLException {
        assert(pds != null);

        this.pds = pds;
        this.connectInfo = new ConnectInfo(username, password);
        this.singleSessionProxyModel = singleSessionProxyModel;
        this.useFixedUsernamePassword = useFixedUsernamePassword;

        join();
    }
    
    protected void join() throws SQLException {
        if (this.commonPoolDataSource != null) {
            return;
        }

        final String username = connectInfo.getUsername();
        final String password = connectInfo.getPassword();
        
        logger.debug(">join(pds={}, username={}, singleSessionProxyModel={}, useFixedUsernamePassword={})",
                     pds,
                     username,
                     singleSessionProxyModel,
                     useFixedUsernamePassword);

        assert(pds != null);
        
        printDataSourceStatistics(pds, logger);

        commonDataSourceProperties.clear();
        commonDataSourceProperties.putAll(pds.getProperties());

        checkPropertyNotNull(CLASS);
        checkPropertyNotNull(URL);

        checkPropertyNull(USERNAME);
        checkPropertyNull(PASSWORD);
        checkPropertyNull(POOL_NAME);
        checkPropertyNull(INITIAL_POOL_SIZE);
        checkPropertyNull(MIN_POOL_SIZE);
        checkPropertyNull(MAX_POOL_SIZE);

        // Now we have to adjust commonDataSourceProperties and username
        // given username/singleSessionProxyModel/useFixedUsernamePassword.
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

        if (useFixedUsernamePassword) {
            // case A
            setProperty(commonDataSourceProperties, USERNAME, connectInfo.getUsernameToConnectTo());
            setProperty(commonDataSourceProperties, PASSWORD, connectInfo.getPassword());
        }

        commonPoolDataSource = poolDataSources.computeIfAbsent(commonDataSourceProperties, s -> pds);

        assert(commonPoolDataSource != null);
        
        currentPoolCount.computeIfAbsent(commonDataSourceProperties, s -> new AtomicInteger()).incrementAndGet();

        // The statistics are measured per original data source and per total.
        // Total is just a copy.
        commonDataSourceStatisticsTotal.clear();
        commonDataSourceStatisticsTotal.putAll(commonDataSourceProperties);

        // Per original data source, hence we include the username / password.
        commonDataSourceStatistics.clear();
        commonDataSourceStatistics.putAll(commonDataSourceProperties);
        setProperty(commonDataSourceStatistics, USERNAME, username);
        setProperty(commonDataSourceStatistics, PASSWORD, password);        

        // add totals if not already existent
        allDataSourceStatistics.computeIfAbsent(commonDataSourceStatisticsGrandTotal, s -> new PoolDataSourceStatistics());
        allDataSourceStatistics.computeIfAbsent(commonDataSourceStatisticsTotal, s -> new PoolDataSourceStatistics());
        allDataSourceStatistics.computeIfAbsent(commonDataSourceStatistics, s -> new PoolDataSourceStatistics());

        // update pool sizes and default username / password when the pool data source is added to an existing
        synchronized (commonPoolDataSource) {
            // Set new username/password combination of common data source before
            // you augment pool size(s) since that may trigger getConnection() calls.

            // See observations above.
            commonPoolDataSource.setUsername(connectInfo.getUsernameToConnectTo());
            commonPoolDataSource.setPassword(connectInfo.getPassword());

            if (commonPoolDataSource == pds) {
                commonPoolDataSource.setPoolName(getPoolNamePrefix()); // set the prefix the first time
                logger.debug("common pool sizes: initial/minimum/maximum: {}/{}/{}",
                             commonPoolDataSource.getInitialPoolSize(),
                             commonPoolDataSource.getMinPoolSize(),
                             commonPoolDataSource.getMaxPoolSize());
            } else {
                // for debugging purposes
                if (pds.getPoolName() == null) {
                    pds.setPoolName(String.valueOf(pds.hashCode()));
                }
                
                logger.debug("pool sizes before: initial/minimum/maximum: {}/{}/{}",
                             commonPoolDataSource.getInitialPoolSize(),
                             commonPoolDataSource.getMinPoolSize(),
                             commonPoolDataSource.getMaxPoolSize());

                int oldSize, newSize;

                newSize = pds.getInitialPoolSize();
                oldSize = commonPoolDataSource.getInitialPoolSize();

                logger.debug("initial pool sizes before setting it: old/new: {}/{}",
                             oldSize,
                             newSize);

                if (newSize >= 0) {
                    commonPoolDataSource.setInitialPoolSize(newSize + Integer.max(oldSize, 0));
                }

                newSize = pds.getMinPoolSize();
                oldSize = commonPoolDataSource.getMinPoolSize();

                logger.debug("minimum pool sizes before setting it: old/new: {}/{}",
                             oldSize,
                             newSize);

                if (newSize >= 0) {                
                    commonPoolDataSource.setMinPoolSize(newSize + Integer.max(oldSize, 0));
                }
                
                newSize = pds.getMaxPoolSize();
                oldSize = commonPoolDataSource.getMaxPoolSize();

                logger.debug("maximum pool sizes before setting it: old/new: {}/{}",
                             oldSize,
                             newSize);

                if (newSize >= 0) {
                    commonPoolDataSource.setMaxPoolSize(newSize + Integer.max(oldSize, 0));
                }
                
                logger.debug("pool sizes after: initial/minimum/maximum: {}/{}/{}",
                             commonPoolDataSource.getInitialPoolSize(),
                             commonPoolDataSource.getMinPoolSize(),
                             commonPoolDataSource.getMaxPoolSize());
            }
            commonPoolDataSource.setPoolName(commonPoolDataSource.getPoolName() + "-" + connectInfo.getSchema());
            logger.debug("Common pool name: {}", commonPoolDataSource.getPoolName());
        }

        printDataSourceStatistics(commonPoolDataSource, logger);

        final boolean result = (commonPoolDataSource == pds);
            
        logger.debug("<join()");
    }

    private void checkPropertyNull(final String name) {
        try {
            assert(commonDataSourceProperties.get(name) == null);
        } catch (AssertionError ex) {
            System.err.println(String.format("Property ({}) must be null", name));
            throw ex;
        }
    }
    
    private void checkPropertyNotNull(final String name) {
        try {
            assert(commonDataSourceProperties.get(name) != null);
        } catch (AssertionError ex) {
            System.err.println(String.format("Property ({}) must NOT be null", name));
            throw ex;
        }
    }

    protected static void setProperty(final Hashtable<String, Object> properties,
                                      final String name,
                                      final Object value) {
        if (name != null && value != null) {
            properties.put(name, value);
        }
    }    
    
    public void close() {
        if (done()) {
            commonPoolDataSource = null;
        }
    }

    // returns true if there are no more pool data sources hereafter
    final protected boolean done() {
        final boolean lastPoolDataSource = currentPoolCount.get(commonDataSourceProperties).decrementAndGet() == 0;

        if (statisticsEnabled) {
            final PoolDataSourceStatistics poolDataSourceStatistics = allDataSourceStatistics.get(commonDataSourceStatistics);
            final PoolDataSourceStatistics poolDataSourceStatisticsTotal = allDataSourceStatistics.get(commonDataSourceStatisticsTotal);
            final PoolDataSourceStatistics poolDataSourceStatisticsGrandTotal = allDataSourceStatistics.get(commonDataSourceStatisticsGrandTotal);

            if (!poolDataSourceStatistics.countersEqual(poolDataSourceStatisticsTotal)) {
                showDataSourceStatistics(poolDataSourceStatistics, connectInfo.getSchema());
            }
            allDataSourceStatistics.remove(commonDataSourceStatistics);

            if (lastPoolDataSource) {
                // show (grand) totals only when it is the last pool data source
                showDataSourceStatistics(poolDataSourceStatisticsTotal, TOTAL);
                allDataSourceStatistics.remove(commonDataSourceStatisticsGrandTotal);

                // only GrandTotal left?
                if (allDataSourceStatistics.size() == 1) {                
                    if (!poolDataSourceStatisticsGrandTotal.countersEqual(poolDataSourceStatisticsTotal)) {
                        showDataSourceStatistics(poolDataSourceStatisticsGrandTotal, GRAND_TOTAL);
                    }
                    allDataSourceStatistics.remove(commonDataSourceStatisticsGrandTotal);
                }
            }
        }
            
        if (lastPoolDataSource) {
            logger.info("Closing pool {}", getPoolName());
            poolDataSources.remove(commonDataSourceProperties);
            commonPoolDataSource = null;
        }

        return lastPoolDataSource;
    }

    public Connection getConnection() throws SQLException {
        Connection conn;
        
        conn = getConnection(this.connectInfo.getUsernameToConnectTo(),
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

        conn = getConnection(connectInfo.getUsernameToConnectTo(),
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
            
            if (useFixedUsernamePassword) {
                conn = commonPoolDataSource.getConnection();
            } else {
                // see observations in constructor
                conn = commonPoolDataSource.getConnection(usernameToConnectTo, password);
            }

            // if the current schema is not the requested schema try to open/close the proxy session
            if (!conn.getSchema().equalsIgnoreCase(schema)) {
                OracleConnection oraConn = null;
            
                try {
                    if (conn.isWrapperFor(OracleConnection.class)) {
                        oraConn = conn.unwrap(OracleConnection.class);
                    }
                } catch (SQLException ex) {
                    oraConn = null;
                }

                if (oraConn != null) {
                    if (oraConn.isProxySession()) {
                        closeProxySession(oraConn);
                    }
                    if (proxyUsername != null) {
                        openProxySession(oraConn, proxyUsername);
                    }
                }
            }

            showConnection(conn);

            logger.debug("current schema: {}; schema: {}", conn.getSchema(), schema);
            
            assert(conn.getSchema().equalsIgnoreCase(schema));            

            if (updateStatistics) {
                updateStatistics(conn, Duration.between(t1, Instant.now()).toMillis(), showStatistics);
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
        proxyProperties.setProperty(OracleConnection.CONNECTION_PROPERTY_PROXY_CLIENT_NAME, schema);

        oraConn.openProxySession(OracleConnection.PROXYTYPE_USER_NAME, proxyProperties);        
    }

    private static void closeProxySession(final OracleConnection oraConn) throws SQLException {
        oraConn.close(OracleConnection.PROXY_SESSION);
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
        final PoolDataSourceStatistics poolDataSourceStatisticsGrandTotal = allDataSourceStatistics.get(commonDataSourceStatisticsGrandTotal);
        final PoolDataSourceStatistics poolDataSourceStatisticsTotal = allDataSourceStatistics.get(commonDataSourceStatisticsTotal);
        final PoolDataSourceStatistics poolDataSourceStatistics = allDataSourceStatistics.get(commonDataSourceStatistics);
        final int activeConnections = getActiveConnections();
        final int idleConnections = getIdleConnections();
        final int totalConnections = getTotalConnections();

        try {
            poolDataSourceStatisticsGrandTotal.update(conn,
                                                    timeElapsed,
                                                    activeConnections,
                                                    idleConnections,
                                                    totalConnections);
            poolDataSourceStatisticsTotal.update(conn,
                                               timeElapsed,
                                               activeConnections,
                                               idleConnections,
                                               totalConnections);
            // no need for active/idle and total connections because that is counted on common data source level
            poolDataSourceStatistics.update(conn,
                                          timeElapsed);
        } catch (Exception e) {
            logger.error("updateStatistics() exception: {}", e.getMessage());
        }

        if (showStatistics) {
            // no need to display same statistics twice (see below for totals)
            if (!poolDataSourceStatistics.countersEqual(poolDataSourceStatisticsTotal)) {
                showDataSourceStatistics(poolDataSourceStatistics, connectInfo.getSchema(), timeElapsed, false);
            }
            showDataSourceStatistics(poolDataSourceStatisticsTotal, TOTAL, timeElapsed, false);
        }
    }

    protected void updateStatistics(final Connection conn,
                                    final long timeElapsed,
                                    final long timeElapsedProxy,
                                    final boolean showStatistics,
                                    final int logicalConnectionCountProxy,
                                    final int openProxySessionCount,
                                    final int closeProxySessionCount) {
        final PoolDataSourceStatistics poolDataSourceStatisticsGrandTotal = allDataSourceStatistics.get(commonDataSourceStatisticsGrandTotal);
        final PoolDataSourceStatistics poolDataSourceStatisticsTotal = allDataSourceStatistics.get(commonDataSourceStatisticsTotal);
        final PoolDataSourceStatistics poolDataSourceStatistics = allDataSourceStatistics.get(commonDataSourceStatistics);

        try {
            poolDataSourceStatisticsGrandTotal.update(conn,
                                                    timeElapsed,
                                                    timeElapsedProxy,
                                                    logicalConnectionCountProxy,
                                                    openProxySessionCount,
                                                    closeProxySessionCount);
            poolDataSourceStatisticsTotal.update(conn,
                                               timeElapsed,
                                               timeElapsedProxy,
                                               logicalConnectionCountProxy,
                                               openProxySessionCount,
                                               closeProxySessionCount);
            poolDataSourceStatistics.update(conn,
                                          timeElapsed,
                                          timeElapsedProxy,
                                          logicalConnectionCountProxy,
                                          openProxySessionCount,
                                          closeProxySessionCount);
        } catch (Exception e) {
            logger.error("updateStatistics() exception: {}", e.getMessage());
        }

        if (showStatistics) {
            // no need to display same statistics twice (see below for totals)
            if (!poolDataSourceStatistics.countersEqual(poolDataSourceStatisticsTotal)) {
                showDataSourceStatistics(poolDataSourceStatistics, connectInfo.getSchema(), timeElapsed, timeElapsedProxy, false);
            }
            showDataSourceStatistics(poolDataSourceStatisticsTotal, TOTAL, timeElapsed, timeElapsedProxy, false);
        }
    }

    protected void signalException(final Exception ex) {        
        final PoolDataSourceStatistics poolDataSourceStatisticsGrandTotal = allDataSourceStatistics.get(commonDataSourceStatisticsGrandTotal);
        final PoolDataSourceStatistics poolDataSourceStatisticsTotal = allDataSourceStatistics.get(commonDataSourceStatisticsTotal);
        final PoolDataSourceStatistics poolDataSourceStatistics = allDataSourceStatistics.get(commonDataSourceStatistics);

        try {
            final long nrOccurrences = poolDataSourceStatisticsGrandTotal.signalException(ex);
            
            poolDataSourceStatisticsTotal.signalException(ex);
            poolDataSourceStatistics.signalException(ex);
            // show the message
            logger.error("While connecting to {}{} this was occurrence # {} for this exception: (class={}, message={})",
                         connectInfo.getSchema(),
                         ( connectInfo.getProxyUsername() != null ? " (via " + connectInfo.getProxyUsername() + ")" : "" ),
                         nrOccurrences,
                         ex.getClass().getName(),
                         ex.getMessage());
        } catch (Exception e) {
            logger.error("signalException() exception: {}", e.getMessage());
        }
    }

    protected void signalSQLException(final SQLException ex) {        
        final PoolDataSourceStatistics poolDataSourceStatisticsGrandTotal = allDataSourceStatistics.get(commonDataSourceStatisticsGrandTotal);
        final PoolDataSourceStatistics poolDataSourceStatisticsTotal = allDataSourceStatistics.get(commonDataSourceStatisticsTotal);
        final PoolDataSourceStatistics poolDataSourceStatistics = allDataSourceStatistics.get(commonDataSourceStatistics);

        try {
            final long nrOccurrences = poolDataSourceStatisticsGrandTotal.signalSQLException(ex);
            
            poolDataSourceStatisticsTotal.signalSQLException(ex);
            poolDataSourceStatistics.signalSQLException(ex);
            // show the message
            logger.error("While connecting to {}{} this was occurrence # {} for this SQL exception: (class={}, error code={}, SQL state={}, message={})",
                         connectInfo.getSchema(),
                         ( connectInfo.getProxyUsername() != null ? " (via " + connectInfo.getProxyUsername() + ")" : "" ),
                         nrOccurrences,
                         ex.getClass().getName(),
                         ex.getErrorCode(),
                         ex.getSQLState(),
                         ex.getMessage());
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
     * @param timeElapsedProxy        The elapsed time for proxy connection (after the connection)
     * @param finalCall               Is this the final call?
     * @param schema                  The schema to display after the pool name
     */
    private void showDataSourceStatistics(final PoolDataSourceStatistics poolDataSourceStatistics,
                                          final String schema) {
        showDataSourceStatistics(poolDataSourceStatistics, schema, -1L, -1L, true);
    }
    
    private void showDataSourceStatistics(final PoolDataSourceStatistics poolDataSourceStatistics,
                                          final String schema,
                                          final long timeElapsed,
                                          final boolean finalCall) {
        showDataSourceStatistics(poolDataSourceStatistics, schema, timeElapsed, -1L, true);
    }
    
    private void showDataSourceStatistics(final PoolDataSourceStatistics poolDataSourceStatistics,
                                          final String schema,
                                          final long timeElapsed,
                                          final long timeElapsedProxy,
                                          final boolean finalCall) {
        // Only show the first time a pool has gotten a connection.
        // Not earlier because these (fixed) values may change before and after the first connection.
        if (poolDataSourceStatistics.getLogicalConnectionCount() == 1) {
            printDataSourceStatistics(commonPoolDataSource, logger);
        }

        if (!finalCall && !logger.isDebugEnabled()) {
            return;
        }
        
        final Method method = (finalCall ? loggerInfo : loggerDebug);

        final boolean isTotal = schema.equals(TOTAL);
        final boolean isGrandTotal = schema.equals(GRAND_TOTAL);
        final boolean showPoolSizes = isTotal;
        final boolean showErrors = finalCall && (isTotal || isGrandTotal);
        final String prefix = INDENT_PREFIX;
        final String poolDescription = ( isGrandTotal ? "all pools" : "pool " + getPoolName()  + " (" + schema + ")" );

        try {
            if (method != null) {
                method.invoke(logger, "statistics for {}:", (Object) new Object[]{ poolDescription });
            
                if (!finalCall) {
                    if (timeElapsed >= 0L) {
                        method.invoke(logger,
                                      "{}time needed to open last connection (ms): {}",
                                      (Object) new Object[]{ prefix, timeElapsed });
                    }
                    if (timeElapsedProxy >= 0L) {
                        method.invoke(logger,
                                      "{}time needed to open last proxy connection (ms): {}",
                                      (Object) new Object[]{ prefix, timeElapsedProxy });
                    }
                }
            
                long val1, val2, val3;

                val1 = poolDataSourceStatistics.getPhysicalConnectionCount();
                val2 = poolDataSourceStatistics.getLogicalConnectionCount();
            
                if (val1 >= 0L && val2 >= 0L) {
                    method.invoke(logger,
                                  "{}physical/logical connections opened: {}/{}",
                                  (Object) new Object[]{ prefix, val1, val2 });
                }

                val1 = poolDataSourceStatistics.getTimeElapsedMin();
                val2 = poolDataSourceStatistics.getTimeElapsedAvg();
                val3 = poolDataSourceStatistics.getTimeElapsedMax();

                if (val1 >= 0L && val2 >= 0L && val3 >= 0L) {
                    method.invoke(logger,
                                  "{}min/avg/max connection time (ms): {}/{}/{}",
                                  (Object) new Object[]{ prefix, val1, val2, val3 });
                }
            
                if (!singleSessionProxyModel && connectInfo.getProxyUsername() != null) {
                    val1 = poolDataSourceStatistics.getTimeElapsedProxyMin();
                    val2 = poolDataSourceStatistics.getTimeElapsedProxyAvg();
                    val3 = poolDataSourceStatistics.getTimeElapsedProxyMax();

                    if (val1 >= 0L && val2 >= 0L && val3 >= 0L) {
                        method.invoke(logger,
                                      "{}min/avg/max proxy connection time (ms): {}/{}/{}",
                                      (Object) new Object[]{ prefix, val1, val2, val3 });
                    }

                    val1 = poolDataSourceStatistics.getOpenProxySessionCount();
                    val2 = poolDataSourceStatistics.getCloseProxySessionCount();
                    val3 = poolDataSourceStatistics.getLogicalConnectionCountProxy();
                
                    if (val1 >= 0L && val2 >= 0L && val3 >= 0L) {
                        method.invoke(logger,
                                      "{}proxy sessions opened/closed: {}/{}; logical connections rejected while searching for optimal proxy session: {}",
                                      (Object) new Object[]{ prefix, val1, val2, val3 });
                    }
                }
            
                if (showPoolSizes) {
                    method.invoke(logger,
                                  "{}initial/min/max pool size: {}/{}/{}",
                                  (Object) new Object[]{ prefix,
                                                         getInitialPoolSize(),
                                                         getMinPoolSize(),
                                                         getMaxPoolSize() });
                }

                if (!finalCall) {
                    // current values
                    val1 = getActiveConnections();
                    val2 = getIdleConnections();
                    val3 = getTotalConnections();
                    
                    if (val1 >= 0L && val2 >= 0L && val3 >= 0L) {
                        method.invoke(logger,
                                      "{}current active/idle/total connections: {}/{}/{}",
                                      (Object) new Object[]{ prefix, val1, val2, val3 });
                    }
                } else {
                    val1 = poolDataSourceStatistics.getActiveConnectionsMin();
                    val2 = poolDataSourceStatistics.getActiveConnectionsAvg();
                    val3 = poolDataSourceStatistics.getActiveConnectionsMax();

                    if (val1 >= 0L && val2 >= 0L && val3 >= 0L) {
                        method.invoke(logger,
                                      "{}min/avg/max active connections: {}/{}/{}",
                                      (Object) new Object[]{ prefix, val1, val2, val3 });
                    }
                    
                    val1 = poolDataSourceStatistics.getIdleConnectionsMin();
                    val2 = poolDataSourceStatistics.getIdleConnectionsAvg();
                    val3 = poolDataSourceStatistics.getIdleConnectionsMax();

                    if (val1 >= 0L && val2 >= 0L && val3 >= 0L) {
                        method.invoke(logger,
                                      "{}min/avg/max idle connections: {}/{}/{}",
                                      (Object) new Object[]{ prefix, val1, val2, val3 });
                    }

                    val1 = poolDataSourceStatistics.getTotalConnectionsMin();
                    val2 = poolDataSourceStatistics.getTotalConnectionsAvg();
                    val3 = poolDataSourceStatistics.getTotalConnectionsMax();

                    if (val1 >= 0L && val2 >= 0L && val3 >= 0L) {
                        method.invoke(logger,
                                      "{}min/avg/max total connections: {}/{}/{}",
                                      (Object) new Object[]{ prefix, val1, val2, val3 });
                    }
                }
            }

            // show errors
            if (showErrors) {
                final Map<Properties, Long> errors = poolDataSourceStatistics.getErrors();

                if (errors.isEmpty()) {
                    logger.warn("no SQL exceptions signalled for {}", poolDescription);
                } else {
                    logger.warn("SQL exceptions signalled in decreasing number of occurrences for {}:", poolDescription);
                
                    errors.entrySet().stream()
                        .sorted(Collections.reverseOrder(Map.Entry.comparingByValue())) // sort by decreasing number of errors
                        .forEach(e -> {
                                final Properties key = (Properties) e.getKey();
                                final String className = key.getProperty(PoolDataSourceStatistics.EXCEPTION_CLASS_NAME);
                                final String SQLErrorCode = key.getProperty(PoolDataSourceStatistics.EXCEPTION_SQL_ERROR_CODE);
                                final String SQLState = key.getProperty(PoolDataSourceStatistics.EXCEPTION_SQL_STATE);

                                if (SQLErrorCode == null || SQLState == null) {
                                    logger.warn("{}{} occurrences for (class={})",
                                                prefix,
                                                e.getValue(),
                                                className);
                                } else {
                                    logger.warn("{}{} occurrences for (class={}, error code={}, SQL state={})",
                                                prefix,
                                                e.getValue(),
                                                className,
                                                SQLErrorCode,
                                                SQLState);
                                }
                            });
                }
            }
        } catch (IllegalAccessException | InvocationTargetException e) {
            logger.error("showDataSourceStatistics exception: {}", e.getMessage());
        }
    }

    protected int getCurrentPoolCount() {
        return currentPoolCount.get(commonDataSourceProperties).get();
    }

    private static void printDataSourceStatistics(final SimplePoolDataSource poolDataSource, final Logger logger) {
        if (!logger.isDebugEnabled()) {
            return;
        }

        final String prefix = INDENT_PREFIX;
        
        logger.debug("configuration pool data source {}:", poolDataSource.getPoolName());

        poolDataSource
            .getProperties()
            .entrySet()
            .stream()
            .sorted()
            .forEach(e -> logger.debug("{}{}={}", prefix, e.getKey(), e.getValue()));

        logger.debug("connections pool data source {}:", poolDataSource.getPoolName());
        logger.debug("{}total: {}", prefix, poolDataSource.getTotalConnections());
        logger.debug("{}active: {}", prefix, poolDataSource.getActiveConnections());
        logger.debug("{}idle: {}", prefix, poolDataSource.getIdleConnections());
    }
    
    protected abstract String getPoolNamePrefix();

    @Getter
    private class ConnectInfo {

        private String username;

        private String password;
    
        // username like:
        // * bc_proxy[bodomain] => proxyUsername = bc_proxy, schema = bodomain
        // * bodomain => proxyUsername = null, schema = bodomain
        private String proxyUsername;
    
        private String schema; // needed to build the PoolName

        /**
         * Turn a proxy connection username (bc_proxy[bodomain] or bodomain) into
         * schema (bodomain) and proxy username (bc_proxy respectively empty).
         *
         * @param username  The username to connect to.
         * @param password  The pasword.
         *
         */    
        public ConnectInfo(final String username, final String password) {
            this.username = username;
            this.password = password;
        
            final int pos1 = username.indexOf("[");
            final int pos2 = ( username.endsWith("]") ? username.length() - 1 : -1 );
      
            if (pos1 >= 0 && pos2 >= pos1) {
                // a username like bc_proxy[bodomain]
                this.proxyUsername = username.substring(0, pos1);
                this.schema = username.substring(pos1+1, pos2);
            } else {
                // a username like bodomain
                this.proxyUsername = null;
                this.schema = username;
            }

            logger.debug("ConnectInfo(username={}) = (username={}, proxyUsername={}, schema={})",
                         username,
                         this.username,
                         this.proxyUsername,
                         this.schema);
        }

        public String getUsernameToConnectTo() {
            return !singleSessionProxyModel && connectInfo.getProxyUsername() != null ?
                connectInfo.getProxyUsername() /* case 3 */ :
                connectInfo.getUsername() /* case 1 & 2 */;
        }
    }    
}
