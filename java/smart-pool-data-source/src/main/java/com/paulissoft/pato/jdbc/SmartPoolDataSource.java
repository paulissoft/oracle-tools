package com.paulissoft.pato.jdbc;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Duration;
import java.time.Instant;
import java.util.Collections;
import java.util.Map;
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

    public static final String INDENT_PREFIX = "* ";

    private static final String GRAND_TOTAL = "grand total";

    private static final String TOTAL = "total";

    private static final Logger logger = LoggerFactory.getLogger(SmartPoolDataSource.class);

    private static Method loggerInfo;

    private static Method loggerDebug;

    private static final String commonDataSourceStatisticsGrandTotal = null;
    // PoolDataSourceConfiguration.builder().username(GRAND_TOTAL).build().toString();

    private static final ConcurrentHashMap<String, PoolDataSourceStatistics> allDataSourceStatistics = new ConcurrentHashMap<>();

    private static final ConcurrentHashMap<String, SimplePoolDataSource> poolDataSources = new ConcurrentHashMap<>();

    private static final ConcurrentHashMap<String, AtomicInteger> currentPoolCount = new ConcurrentHashMap<>();    

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
    }

    private interface Overrides {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;
    }
    
    @Delegate(excludes=Overrides.class)
    @Getter(AccessLevel.PACKAGE)
    private SimplePoolDataSource commonPoolDataSource = null;

    @Getter(AccessLevel.PACKAGE)
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
    @Getter(AccessLevel.PACKAGE)
    private String commonDataSourceProperties;

    // Same as commonDataSourceProperties, i.e. total per common pool data source.
    @Getter(AccessLevel.PACKAGE)
    private String commonDataSourceStatisticsTotal = null;

    // Same as commonDataSourceProperties including current schema and password,
    // only for connection info like elapsed time, open/close sessions.
    @Getter(AccessLevel.PACKAGE)
    private String commonDataSourceStatistics;

    /**
     * Initialize a pool data source.
     *
     * The one and only constructor.
     *
     * @param pds                         A pool data source (HikariCP or UCP).
     * @param singleSessionProxyModel
     * @param useFixedUsernamePassword    Only use commonPoolDataSource.getConnection(), never commonPoolDataSource.getConnection(username, password)
     */
    protected SmartPoolDataSource(final SimplePoolDataSource pds,
                                  final boolean singleSessionProxyModel,
                                  final boolean useFixedUsernamePassword) throws SQLException {
        assert(pds != null);
        assert(pds.getUsername() != null);
        assert(pds.getPassword() != null);

        this.pds = pds;
        this.connectInfo = new ConnectInfo(pds.getUsername(), pds.getPassword());
        this.singleSessionProxyModel = singleSessionProxyModel;
        this.useFixedUsernamePassword = useFixedUsernamePassword;

        join();
    }
    
    /**
     * Join the common pool of pool data sources.
     *
     * There are three relevant join situations:
     * I   - This pool has not joined before (ignoring pool name).
     *       Next, determine the commonPoolDataSource (clearing common properties like pool name and pool sizes).
     *       Now, if the commonPoolDataSource has NOT already started (i.e. NOT total transactions > 0), we can adjust
     *       the common properties of commonPoolDataSource and initialize all other data structures.
     * II  - This pool has not joined before (ignoring pool name) but the commonPoolDataSource has already started.
     *       Now we can (or may) NOT adjust its properties, so just use this pool as the commonPoolDataSource and repeat step I.
     * III - This pool (or a similar one with the same configuration) has already joined before (ignoring pool name).
     *       Now we have the commonPoolDataSource and we are done
     *       since all has already been initialized before (especially the static fields).
     *       However we must set these member fields as well:
     *       - commonDataSourceProperties
     *       - commonDataSourceStatisticsTotal / commonDataSourceStatistics
    */
    final private void join() throws SQLException {
        if (this.commonPoolDataSource != null) {
            return;
        }

        final String username = this.connectInfo.getUsername();
        final String password = this.connectInfo.getPassword();
        
        logger.info(">join(pds={}, username={}, singleSessionProxyModel={}, useFixedUsernamePassword={})",
                     this.pds,
                     username,
                     this.singleSessionProxyModel,
                     this.useFixedUsernamePassword);

        try {
            assert(this.pds != null);
        
            printDataSourceStatistics(this.pds, logger);

            final PoolDataSourceConfiguration dataSourceProperties = this.pds.getPoolDataSourceConfiguration();

            // ignore pool name for dataSourceProperties lookup
            dataSourceProperties.clearPoolName();

            logger.debug("dataSourceProperties:\n{}", dataSourceProperties.toString());

            PoolDataSourceConfiguration commonDataSourceProperties; // there is also a this.commonDataSourceProperties

            if (logger.isDebugEnabled()) {
                logger.debug("poolDataSources before:");
                poolDataSources.forEach((k, v) -> logger.debug("\n{}\nvalue (hash code)={}; value (string)=\n{}", k, v.hashCode(), v.toString()));
            }
            
            boolean pdsIsCommonPoolDataSource = poolDataSources.containsValue(this.pds);
            boolean pdsExists = poolDataSources.containsKey(dataSourceProperties.toString());

            logger.debug("pdsIsCommonPoolDataSource: {}; pdsExists: {}",
                         pdsIsCommonPoolDataSource,
                         pdsExists);

            // same data source can be asked another time (in another thread)
            this.commonPoolDataSource =
                pdsIsCommonPoolDataSource ?
                this.pds :
                ( pdsExists ? poolDataSources.get(dataSourceProperties.toString()) : null ); // see I below

            logger.info("(similar) pool data source already joined: {}",
                        this.commonPoolDataSource != null);

            if (this.commonPoolDataSource != null) {
                logger.info("join situation III");
                commonDataSourceProperties = determineCommonDataSourceProperties(this.commonPoolDataSource.getPoolDataSourceConfiguration(),
                                                                                 this.connectInfo,
                                                                                 this.useFixedUsernamePassword);

                this.commonDataSourceProperties = commonDataSourceProperties.toString();
                this.commonDataSourceStatistics = determineCommonDataSourceStatistics(commonDataSourceProperties,
                                                                                      username,
                                                                                      password);                    
                this.commonDataSourceStatisticsTotal = null;

                return; // see I
            }
            
            commonDataSourceProperties = determineCommonDataSourceProperties(dataSourceProperties,
                                                                             this.connectInfo,
                                                                             this.useFixedUsernamePassword);

            int nr = 1;
            int maxNr = 2;

            // see II and III above
            do {
                logger.info("checking join situation {} for calculation of commonPoolDataSource", (nr == 1 ? "I" : "II"));
                switch (nr) {
                case 1:
                    break;
                    
                case 2:
                    commonDataSourceProperties = dataSourceProperties;
                    break;
                }
                this.commonDataSourceProperties = commonDataSourceProperties.toString();
                this.commonPoolDataSource = poolDataSources.computeIfAbsent(this.commonDataSourceProperties, s -> this.pds);
                assert(this.commonPoolDataSource != null);
            } while (this.commonPoolDataSource.getTotalConnections() > 0 && ++nr <= maxNr);

            logger.info("join situation {}", (nr == 1 ? "I" : "II"));

            this.currentPoolCount.computeIfAbsent(this.commonDataSourceProperties, s -> new AtomicInteger()).incrementAndGet();

            // The statistics are measured per original data source and per total.
            // Total is just a copy.
            // commonDataSourceStatisticsTotal = commonDataSourceProperties.toBuilder().build().toString();

            this.commonDataSourceStatistics = determineCommonDataSourceStatistics(commonDataSourceProperties,
                                                                                  username,
                                                                                  password);
            this.commonDataSourceStatisticsTotal = null;

            // add totals if not already existent
            if (commonDataSourceStatisticsGrandTotal != null) {
                allDataSourceStatistics.computeIfAbsent(commonDataSourceStatisticsGrandTotal, s -> new PoolDataSourceStatistics());
            }
            if (commonDataSourceStatisticsTotal != null) {
                allDataSourceStatistics.computeIfAbsent(commonDataSourceStatisticsTotal, s -> new PoolDataSourceStatistics());
            }
            allDataSourceStatistics.computeIfAbsent(commonDataSourceStatistics, s -> new PoolDataSourceStatistics());

            // only modify commonPoolDataSource when there are no connections i.e. not started yet
            if (this.commonPoolDataSource.getTotalConnections() <= 0) {
                // update default username / password when the pool data source is added to an existing
                synchronized (this.commonPoolDataSource) {
                    // Set new username/password combination of common data source before
                    // you augment pool size(s) since that may trigger getConnection() calls.

                    // See observations above.
                    this.commonPoolDataSource.setUsername(this.connectInfo.getUsernameToConnectTo());
                    this.commonPoolDataSource.setPassword(this.connectInfo.getPassword());

                    if (this.commonPoolDataSource == this.pds) {
                        this.commonPoolDataSource.setPoolName(getPoolNamePrefix()); // set the prefix the first time
                    } else {
                        this.commonPoolDataSource.updatePoolSizes(this.pds);
                    }
                    this.commonPoolDataSource.setPoolName(this.commonPoolDataSource.getPoolName() + "-" + this.connectInfo.getSchema());
                    logger.info("Common pool name: {}", this.commonPoolDataSource.getPoolName());
                }
            }

            // also register the commonPoolDataSource for any pds (not being a commonPoolDataSource)
            // because we need it above (I, II and III) in the first lookup
            if (this.commonPoolDataSource != this.pds) {
                // for debugging purposes
                if (this.pds.getPoolName() == null) {
                    this.pds.setPoolName(String.valueOf(this.pds.hashCode()));
                }
                logger.debug("adding pds\n{}", dataSourceProperties.toString());
                poolDataSources.computeIfAbsent(dataSourceProperties.toString(), s -> this.commonPoolDataSource);
            }        

            pdsIsCommonPoolDataSource = poolDataSources.containsValue(this.pds);
            pdsExists = poolDataSources.containsKey(dataSourceProperties.toString());

            logger.debug("pdsIsCommonPoolDataSource: {}; pdsExists: {}",
                         pdsIsCommonPoolDataSource,
                         pdsExists);

            if (logger.isDebugEnabled()) {
                logger.debug("poolDataSources after:");
                poolDataSources.forEach((k, v) -> logger.debug("\n{}\nvalue (hash code)={}; value (string)={}", k, v.hashCode(), v.toString()));
            }
            
            assert(pdsIsCommonPoolDataSource || pdsExists);
            assert(!(pdsIsCommonPoolDataSource && pdsExists));

            printDataSourceStatistics(this.commonPoolDataSource, logger);
        } finally {
            logger.info("<join()");
        }
    }

    private static PoolDataSourceConfiguration determineCommonDataSourceProperties(final PoolDataSourceConfiguration dataSourceProperties,
                                                                                   final ConnectInfo connectInfo,
                                                                                   final boolean useFixedUsernamePassword) {
        final PoolDataSourceConfiguration commonDataSourceProperties = dataSourceProperties.toBuilder().build(); // a copy

        logger.debug("commonDataSourceProperties before:\n{}", commonDataSourceProperties.toString());

        assert(commonDataSourceProperties.getType() != null);
        assert(commonDataSourceProperties.getUrl() != null);

        commonDataSourceProperties.clearCommonDataSourceConfiguration();

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
            commonDataSourceProperties.setUsername(connectInfo.getUsernameToConnectTo());
            commonDataSourceProperties.setPassword(connectInfo.getPassword());
        }

        logger.debug("commonDataSourceProperties after:\n{}", commonDataSourceProperties.toString());

        return commonDataSourceProperties;
    }

    private static String determineCommonDataSourceStatistics(final PoolDataSourceConfiguration commonDataSourceProperties,
                                                              final String username,
                                                              final String password) {
        // Per original data source, hence we include the username / password.
        return commonDataSourceProperties
            .toBuilder()
            .username(username)
            .password(password)
            .build()
            .toString();
    }

    public void close() {
        logger.debug(">close()");

        try {
            done();
        } catch (Exception ex) {
            logger.error("exception:", ex);
            ex.printStackTrace(System.err);
            throw ex;
        } finally {
            logger.debug("<close()");
        }
    }

    // returns true if there are no more pool data sources hereafter
    final protected boolean done() {
        logger.debug(">done()");
        
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

                    if (commonDataSourceStatisticsGrandTotal != null) {
                        final PoolDataSourceStatistics poolDataSourceStatisticsGrandTotal =
                            allDataSourceStatistics.get(commonDataSourceStatisticsGrandTotal);

                        // only GrandTotal left?
                        if (poolDataSourceStatisticsGrandTotal != null) {
                            if (allDataSourceStatistics.size() == 1) {                
                                if (!poolDataSourceStatisticsGrandTotal.countersEqual(poolDataSourceStatisticsTotal)) {
                                    showDataSourceStatistics(poolDataSourceStatisticsGrandTotal, GRAND_TOTAL);
                                }
                                allDataSourceStatistics.remove(commonDataSourceStatisticsGrandTotal);
                            }
                        }
                    }
                }
            }
            
            if (lastPoolDataSource) {
                logger.info("Closing pool {}", getPoolName());
                poolDataSources.remove(commonDataSourceProperties);
            }
        } catch (Exception ex) {
            logger.error("exception:", ex);
            ex.printStackTrace(System.err);
            logger.debug("<done()");
            throw ex;
        } 

        logger.debug("<done() = {}", lastPoolDataSource);

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
            int logicalConnectionCountProxy = 0, openProxySessionCount = 0, closeProxySessionCount = 0;        
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
                                closeProxySessionCount++;
                            }
                            break;
                            
                        case 1:
                            if (proxyUsername != null) { // proxyUsername is username to connect to
                                assert(proxyUsername.equalsIgnoreCase(usernameToConnectTo));
                        
                                openProxySession(oraConn, schema);
                                openProxySessionCount++;
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
                                     logicalConnectionCountProxy,
                                     openProxySessionCount,
                                     closeProxySessionCount);
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
        final PoolDataSourceStatistics poolDataSourceStatisticsGrandTotal =
            commonDataSourceStatisticsGrandTotal != null ? allDataSourceStatistics.get(commonDataSourceStatisticsGrandTotal) : null;
        final PoolDataSourceStatistics poolDataSourceStatisticsTotal =
            commonDataSourceStatisticsTotal != null ? allDataSourceStatistics.get(commonDataSourceStatisticsTotal) : null;
        final PoolDataSourceStatistics poolDataSourceStatistics = allDataSourceStatistics.get(commonDataSourceStatistics);
        final int activeConnections = getActiveConnections();
        final int idleConnections = getIdleConnections();
        final int totalConnections = getTotalConnections();

        try {
            if (poolDataSourceStatisticsGrandTotal != null) {
                poolDataSourceStatisticsGrandTotal.update(conn,
                                                          timeElapsed,
                                                          activeConnections,
                                                          idleConnections,
                                                          totalConnections);
            }
            if (poolDataSourceStatisticsTotal != null) {
                poolDataSourceStatisticsTotal.update(conn,
                                                     timeElapsed,
                                                     activeConnections,
                                                     idleConnections,
                                                     totalConnections);
            }
            // no need for active/idle and total connections because that is counted on common data source level
            poolDataSourceStatistics.update(conn,
                                            timeElapsed);
        } catch (Exception e) {
            logger.error("updateStatistics() exception: {}", e.getMessage());
        }

        if (showStatistics && poolDataSourceStatisticsTotal != null) {
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
        final PoolDataSourceStatistics poolDataSourceStatisticsGrandTotal =
            commonDataSourceStatisticsGrandTotal != null ? allDataSourceStatistics.get(commonDataSourceStatisticsGrandTotal) : null;
        final PoolDataSourceStatistics poolDataSourceStatisticsTotal =
            commonDataSourceStatisticsTotal != null ? allDataSourceStatistics.get(commonDataSourceStatisticsTotal) : null;
        final PoolDataSourceStatistics poolDataSourceStatistics = allDataSourceStatistics.get(commonDataSourceStatistics);

        try {
            if (poolDataSourceStatisticsGrandTotal != null) {
                poolDataSourceStatisticsGrandTotal.update(conn,
                                                          timeElapsed,
                                                          timeElapsedProxy,
                                                          logicalConnectionCountProxy,
                                                          openProxySessionCount,
                                                          closeProxySessionCount);
            }
            if (poolDataSourceStatisticsTotal != null) {
                poolDataSourceStatisticsTotal.update(conn,
                                                     timeElapsed,
                                                     timeElapsedProxy,
                                                     logicalConnectionCountProxy,
                                                     openProxySessionCount,
                                                     closeProxySessionCount);
            }
            poolDataSourceStatistics.update(conn,
                                            timeElapsed,
                                            timeElapsedProxy,
                                            logicalConnectionCountProxy,
                                            openProxySessionCount,
                                            closeProxySessionCount);
        } catch (Exception e) {
            logger.error("updateStatistics() exception: {}", e.getMessage());
        }

        if (showStatistics && poolDataSourceStatisticsTotal != null) {
            // no need to display same statistics twice (see below for totals)
            if (!poolDataSourceStatistics.countersEqual(poolDataSourceStatisticsTotal)) {
                showDataSourceStatistics(poolDataSourceStatistics, connectInfo.getSchema(), timeElapsed, timeElapsedProxy, false);
            }
            showDataSourceStatistics(poolDataSourceStatisticsTotal, TOTAL, timeElapsed, timeElapsedProxy, false);
        }
    }

    protected void signalException(final Exception ex) {        
        final PoolDataSourceStatistics poolDataSourceStatisticsGrandTotal =
            commonDataSourceStatisticsGrandTotal != null ? allDataSourceStatistics.get(commonDataSourceStatisticsGrandTotal) : null;
        final PoolDataSourceStatistics poolDataSourceStatisticsTotal =
            commonDataSourceStatisticsTotal != null ? allDataSourceStatistics.get(commonDataSourceStatisticsTotal) : null;
        final PoolDataSourceStatistics poolDataSourceStatistics = allDataSourceStatistics.get(commonDataSourceStatistics);

        try {
            final long nrOccurrences = poolDataSourceStatisticsGrandTotal != null ? poolDataSourceStatisticsGrandTotal.signalException(ex) : 0;

            if (nrOccurrences > 0) {
                if (poolDataSourceStatisticsTotal != null) {
                    poolDataSourceStatisticsTotal.signalException(ex);
                }
                poolDataSourceStatistics.signalException(ex);
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
        final PoolDataSourceStatistics poolDataSourceStatisticsGrandTotal =
            commonDataSourceStatisticsGrandTotal != null ? allDataSourceStatistics.get(commonDataSourceStatisticsGrandTotal) : null;
        final PoolDataSourceStatistics poolDataSourceStatisticsTotal =
            commonDataSourceStatisticsTotal != null ? allDataSourceStatistics.get(commonDataSourceStatisticsTotal) : null;
        final PoolDataSourceStatistics poolDataSourceStatistics = allDataSourceStatistics.get(commonDataSourceStatistics);

        try {
            final long nrOccurrences = poolDataSourceStatisticsGrandTotal != null ? poolDataSourceStatisticsGrandTotal.signalSQLException(ex) : 0;

            if (nrOccurrences > 0) {
                if (poolDataSourceStatisticsTotal != null) {
                    poolDataSourceStatisticsTotal.signalSQLException(ex);
                }
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
        showDataSourceStatistics(poolDataSourceStatistics, schema, timeElapsed, -1L, finalCall);
    }
    
    private void showDataSourceStatistics(final PoolDataSourceStatistics poolDataSourceStatistics,
                                          final String schema,
                                          final long timeElapsed,
                                          final long timeElapsedProxy,
                                          final boolean finalCall) {
        assert(poolDataSourceStatistics != null);
        
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
                    logger.info("no connection exceptions signalled for {}", poolDescription);
                } else {
                    logger.warn("connection exceptions signalled in decreasing number of occurrences for {}:", poolDescription);
                
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
        logger.debug("{}configuration: {}", prefix, poolDataSource.getPoolDataSourceConfiguration().toString());
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
