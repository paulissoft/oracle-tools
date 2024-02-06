package com.paulissoft.pato.jdbc;

import java.math.BigDecimal;
import java.util.concurrent.atomic.AtomicReference;
import java.io.Closeable;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import javax.sql.DataSource;
import lombok.experimental.Delegate;
import lombok.Getter;
import lombok.Setter;
import oracle.jdbc.OracleConnection;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public abstract class SmartPoolDataSource implements DataSource, Closeable {

    public static final String CLASS = "class";

    public static final String CONNECTION_FACTORY_CLASS_NAME = "connectionFactoryClassName";
        
    public static final String URL = "url";

    public static final String USERNAME = "username";
    
    public static final String PASSWORD = "password";
    
    public static final String POOL_NAME = "poolName";

    public static final String INITIAL_POOL_SIZE = "initialPoolSize";

    public static final String MINIMUM_POOL_SIZE = "minimumPoolSize";

    public static final String MAXIMUM_POOL_SIZE = "maximumPoolSize";

    private static final String ALL = "*";

    private static final Logger logger = LoggerFactory.getLogger(SmartPoolDataSource.class);

    private static Method loggerInfo;

    private static Method loggerDebug;

    private static Properties commonDataSourceStatisticsGrandTotal = new Properties();

    private static ConcurrentHashMap<Properties, MyDataSourceStatistics> allDataSourceStatistics = new ConcurrentHashMap<>();

    private static ConcurrentHashMap<Properties, DataSource> dataSources = new ConcurrentHashMap<>();

    private static ConcurrentHashMap<Properties, AtomicInteger> currentPoolCount = new ConcurrentHashMap<>();    

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

        setProperty(commonDataSourceStatisticsGrandTotal, USERNAME, ALL);
        setProperty(commonDataSourceStatisticsGrandTotal, PASSWORD, "");
    }

    private interface Overrides {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;
    }
    
    @Delegate(excludes=Overrides.class)
    private DataSource commonPoolDataSource;

    @Getter
    @Setter
    private boolean statisticsEnabled = false;

    // see https://docs.oracle.com/en/database/oracle/oracle-database/19/jajdb/oracle/jdbc/OracleConnection.html
    // true - do not use openProxySession() but use proxyUsername[schema]
    // false - use openProxySession() (two sessions will appear in v$session)
    private boolean singleSessionProxyModel;

    private boolean useFixedUsernamePassword;

    private ConnectInfo connectInfo;

    // Same common properties for a pool data source in constructor: same commonPoolDataSource
    private Properties commonDataSourceProperties = new Properties();

    // Same as commonDataSourceProperties, i.e. total per common pool data source.
    private Properties commonDataSourceStatisticsTotal = new Properties();

    // Same as commonDataSourceProperties including current schema and password,
    // only for connection info like elapsed time, open/close sessions.
    private Properties commonDataSourceStatistics = new Properties();

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
    protected SmartPoolDataSource(final DataSource pds,
                                  final Properties commonDataSourceProperties,
                                  final String username,
                                  final String password,
                                  final boolean singleSessionProxyModel,
                                  final boolean useFixedUsernamePassword) throws SQLException {
        logger.debug(">SmartPoolDataSource(pds={}, username={}, singleSessionProxyModel={}, useFixedUsernamePassword={})",
                     pds,
                     username,
                     singleSessionProxyModel,
                     useFixedUsernamePassword);

        assert(pds != null);
        
        printDataSourceStatistics(pds, logger);

        this.commonDataSourceProperties.putAll(commonDataSourceProperties);
        this.singleSessionProxyModel = singleSessionProxyModel;
        this.useFixedUsernamePassword = useFixedUsernamePassword;

        checkPropertyNotNull(CLASS);
        checkPropertyNotNull(URL);

        checkPropertyNull(USERNAME);
        checkPropertyNull(PASSWORD);
        checkPropertyNull(POOL_NAME);
        checkPropertyNull(INITIAL_POOL_SIZE);
        checkPropertyNull(MINIMUM_POOL_SIZE);
        checkPropertyNull(MAXIMUM_POOL_SIZE);
    
        connectInfo = new ConnectInfo(username, password);

        // Now we have to adjust this.commonDataSourceProperties and this.username
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
            setProperty(this.commonDataSourceProperties,
                        USERNAME,
                        ( !singleSessionProxyModel && connectInfo.getProxyUsername() != null ?
                          connectInfo.getProxyUsername() /* case 3 */ :
                          connectInfo.getUsername() /* case 1 & 2 */ ));
            setProperty(this.commonDataSourceProperties, PASSWORD, connectInfo.getPassword());
        }

        this.commonPoolDataSource = dataSources.computeIfAbsent(this.commonDataSourceProperties, s -> pds);

        assert(this.commonPoolDataSource != null);
        
        this.currentPoolCount.computeIfAbsent(this.commonDataSourceProperties, s -> new AtomicInteger()).incrementAndGet();

        // The statistics are measured per original data source and per total.
        // Total is just a copy.
        this.commonDataSourceStatisticsTotal = this.commonDataSourceProperties;

        // Per original data source, hence we include the username / password.
        this.commonDataSourceStatistics.putAll(commonDataSourceProperties);
        setProperty(this.commonDataSourceStatistics, USERNAME, username);
        setProperty(this.commonDataSourceStatistics, PASSWORD, password);        

        // add totals if not already existent
        this.allDataSourceStatistics.computeIfAbsent(this.commonDataSourceStatisticsGrandTotal, s -> new MyDataSourceStatistics());
        this.allDataSourceStatistics.computeIfAbsent(this.commonDataSourceStatisticsTotal, s -> new MyDataSourceStatistics());
        this.allDataSourceStatistics.computeIfAbsent(this.commonDataSourceStatistics, s -> new MyDataSourceStatistics());

        // generic part
        setCommonPoolDataSource(this.commonPoolDataSource);

        // update pool sizes and default username / password when the pool data source is added to an existing
        synchronized (this.commonPoolDataSource) {
            // Set new username/password combination of common data source before
            // you augment pool size(s) since that may trigger getConnection() calls.

            // See observations above.
            setUsername(( !singleSessionProxyModel && connectInfo.getProxyUsername() != null ?
                          connectInfo.getProxyUsername() /* case 3 */ :
                          connectInfo.getUsername() /* case 1 & 2 */ ));
            setPassword(connectInfo.getPassword());

            if (this.commonPoolDataSource == pds) {
                setPoolName(getPoolNamePrefix()); // set the prefix the first time
            } else {
                logger.info("pool sizes before: initial/minimum/maximum: {}/{}/{}",
                            getInitialPoolSize(),
                            getMinimumPoolSize(),
                            getMaximumPoolSize());

                int oldSize, newSize;

                newSize = getInitialPoolSize(pds);
                oldSize = getInitialPoolSize();

                if (newSize >= 0) {
                    setInitialPoolSize(newSize + Integer.max(oldSize, 0));
                }

                newSize = getMinimumPoolSize(pds);
                oldSize = getMinimumPoolSize();

                if (newSize >= 0) {                
                    setMinimumPoolSize(newSize + Integer.max(oldSize, 0));
                }
                
                newSize = getMaximumPoolSize(pds);
                oldSize = getMaximumPoolSize();

                if (newSize >= 0) {
                    setMaximumPoolSize(newSize + Integer.max(oldSize, 0));
                }
                
                logger.info("pool sizes after: initial/minimum/maximum: {}/{}/{}",
                            getInitialPoolSize(),
                            getMinimumPoolSize(),
                            getMaximumPoolSize());
            }
            setPoolName(getPoolName() + "-" + connectInfo.getSchema());
            logger.info("Common pool name: {}", getPoolName());
        }

        printDataSourceStatistics(this.commonPoolDataSource, logger);

        logger.debug("<SmartPoolDataSource()");
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

    protected static void setProperty(final Properties properties,
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
            final MyDataSourceStatistics myDataSourceStatistics = allDataSourceStatistics.get(commonDataSourceStatistics);
            final MyDataSourceStatistics myDataSourceStatisticsTotal = allDataSourceStatistics.get(commonDataSourceStatisticsTotal);
            final MyDataSourceStatistics myDataSourceStatisticsGrandTotal = allDataSourceStatistics.get(commonDataSourceStatisticsGrandTotal);

            if (!myDataSourceStatistics.countersEqual(myDataSourceStatisticsTotal)) {
                showDataSourceStatistics(myDataSourceStatistics, connectInfo.getSchema());
            }
            allDataSourceStatistics.remove(commonDataSourceStatistics);

            if (lastPoolDataSource) {
                // show (grand) totals only when it is the last pool data source
                showDataSourceStatistics(myDataSourceStatisticsTotal, ALL);
                allDataSourceStatistics.remove(commonDataSourceStatisticsGrandTotal);

                // only GrandTotal left?
                if (allDataSourceStatistics.size() == 1) {                
                    if (!myDataSourceStatisticsGrandTotal.countersEqual(myDataSourceStatisticsTotal)) {
                        showDataSourceStatistics(myDataSourceStatisticsGrandTotal, ALL);
                    }
                    allDataSourceStatistics.remove(commonDataSourceStatisticsGrandTotal);
                }
            }
        }
            
        if (lastPoolDataSource) {
            logger.info("Closing pool {}", getPoolName());
            dataSources.remove(commonDataSourceProperties);
            commonPoolDataSource = null;
        }

        return lastPoolDataSource;
    }

    public Connection getConnection() throws SQLException {
        Connection conn;
        
        if (singleSessionProxyModel || connectInfo.getProxyUsername() == null) {
            conn = getConnectionSimple(this.connectInfo.getUsername(),
                                       this.connectInfo.getPassword(),
                                       this.connectInfo.getSchema(),
                                       this.connectInfo.getProxyUsername());
        } else {
            conn = getConnectionSmart(this.connectInfo.getUsername(),
                                      this.connectInfo.getPassword(),
                                      this.connectInfo.getSchema(),
                                      this.connectInfo.getProxyUsername());
        }

        logger.debug("getConnection() = {}", conn);

        return conn;
    }

    @Deprecated
    public Connection getConnection(String username, String password) throws SQLException {
        final ConnectInfo connectInfo = new ConnectInfo(username, password);
        Connection conn;

        if (singleSessionProxyModel || connectInfo.getProxyUsername() == null) {
            conn = getConnectionSimple(connectInfo.getUsername(),
                                       connectInfo.getPassword(),
                                       connectInfo.getSchema(),
                                       connectInfo.getProxyUsername());
        } else {
            conn = getConnectionSmart(connectInfo.getUsername(),
                                      connectInfo.getPassword(),
                                      connectInfo.getSchema(),
                                      connectInfo.getProxyUsername());
        }
        
        logger.debug("getConnection(username={}) = {}", username, conn);

        return conn;
    }

    private Connection getConnectionSimple(final String username,
                                           final String password,
                                           final String schema,
                                           final String proxyUsername) throws SQLException {
        return getConnectionSimple(username,
                                   password,
                                   schema,
                                   proxyUsername,
                                   Instant.now(),
                                   true);
    }
    
    private Connection getConnectionSimple(final String username,
                                           final String password,
                                           final String schema,
                                           final String proxyUsername,
                                           final Instant t1,
                                           final boolean showStatistics) throws SQLException {
        Connection conn;
        
        if (useFixedUsernamePassword) {
            conn = commonPoolDataSource.getConnection();
        } else {
            // see observations in constructor
            conn = commonPoolDataSource.getConnection(( !singleSessionProxyModel && proxyUsername != null ?
                                                        proxyUsername /* case 3 */ :
                                                        username /* case 1 & 2 */ ),
                                                      password);
        }
        if (statisticsEnabled) {
            updateStatistics(conn, Duration.between(t1, Instant.now()).toMillis(), showStatistics);
        }

        logger.debug("getConnectionSimple(username={}, password={}, schema={}, proxyUsername={}) = {}",
                     username,
                     password,
                     schema,
                     proxyUsername,
                     conn);
        
        return conn;
    }    

    protected abstract Connection getConnectionSmart(final String username,
                                                     final String password,
                                                     final String schema,
                                                     final String proxyUsername) throws SQLException;    

    protected void updateStatistics(final Connection conn,
                                    final long timeElapsed,
                                    final boolean showStatistics) {
        assert(statisticsEnabled);
        
        final int activeConnections = getActiveConnections();
        final int idleConnections = getIdleConnections();
        final int totalConnections = getTotalConnections();
        final MyDataSourceStatistics myDataSourceStatisticsGrandTotal = allDataSourceStatistics.get(commonDataSourceStatisticsGrandTotal);
        final MyDataSourceStatistics myDataSourceStatisticsTotal = allDataSourceStatistics.get(commonDataSourceStatisticsTotal);
        final MyDataSourceStatistics myDataSourceStatistics = allDataSourceStatistics.get(commonDataSourceStatistics);

        try {
            myDataSourceStatisticsGrandTotal.update(conn,
                                                    timeElapsed,
                                                    activeConnections,
                                                    idleConnections,
                                                    totalConnections);
            myDataSourceStatisticsTotal.update(conn,
                                               timeElapsed,
                                               activeConnections,
                                               idleConnections,
                                               totalConnections);
            // no need for active/idle and total connections because that is counted on common data source level
            myDataSourceStatistics.update(conn,
                                          timeElapsed);
        } catch (Exception e) {
            logger.error("updateStatistics() exception: {}", e.getMessage());
        }

        if (showStatistics) {
            // no need to display same statistics twice (see below for totals)
            if (!myDataSourceStatistics.countersEqual(myDataSourceStatisticsTotal)) {
                showDataSourceStatistics(myDataSourceStatistics, connectInfo.getSchema(), timeElapsed, false);
            }
            showDataSourceStatistics(myDataSourceStatisticsTotal, ALL, timeElapsed, false);
        }
    }

    protected void updateStatistics(final int closeConnectionCount,
                                    final int openProxySessionCount,
                                    final int closeProxySessionCount,
                                    final long timeElapsed) {
        assert(statisticsEnabled);
        
        final MyDataSourceStatistics myDataSourceStatisticsGrandTotal = allDataSourceStatistics.get(commonDataSourceStatisticsGrandTotal);
        final MyDataSourceStatistics myDataSourceStatisticsTotal = allDataSourceStatistics.get(commonDataSourceStatisticsTotal);
        final MyDataSourceStatistics myDataSourceStatistics = allDataSourceStatistics.get(commonDataSourceStatistics);

        try {
            myDataSourceStatisticsGrandTotal.update(closeConnectionCount,
                                                    openProxySessionCount,
                                                    closeProxySessionCount);
            myDataSourceStatisticsTotal.update(closeConnectionCount,
                                               openProxySessionCount,
                                               closeProxySessionCount);
            myDataSourceStatistics.update(closeConnectionCount,
                                          openProxySessionCount,
                                          closeProxySessionCount);
        } catch (Exception e) {
            logger.error("updateStatistics() exception: {}", e.getMessage());
        }

        // no need to display same statistics twice (see below for totals)
        if (!myDataSourceStatistics.countersEqual(myDataSourceStatisticsTotal)) {
            showDataSourceStatistics(myDataSourceStatistics, connectInfo.getSchema(), timeElapsed, false);
        }
        showDataSourceStatistics(myDataSourceStatisticsTotal, ALL, timeElapsed, false);
    }
    
    /**
     * Show data source statistics for a schema (or ALL).
     *
     * Normally first the statistics of a schema are displayed and then the statistics
     * for all schemas in a pool (unless there is just one).
     *
     * From this it follows that first the connectin is displayed (schema and then ALL) and
     * next the pool information (ALL).
     *
     * @param myDataSourceStatistics  The statistics for a schema (or all)
     * @param timeElapsed             The elapsed time
     * @param finalCall               Is this the final call?
     * @param schema                  The schema to display after the pool name
     */
    private void showDataSourceStatistics(final MyDataSourceStatistics myDataSourceStatistics,
                                          final String schema) {
        showDataSourceStatistics(myDataSourceStatistics, schema, -1L, true);
    }
    
    private void showDataSourceStatistics(final MyDataSourceStatistics myDataSourceStatistics,
                                          final String schema,
                                          final long timeElapsed,
                                          final boolean finalCall) {
        // Only show the first time a pool has gotten a connection.
        // Not earlier because these (fixed) values may change before and after the first connection.
        if (myDataSourceStatistics.getOpenConnectionCount() == 1) {
            printDataSourceStatistics(commonPoolDataSource, logger);
        }

        if (!finalCall && !logger.isDebugEnabled()) {
            return;
        }
        
        final Method method = (finalCall ? loggerInfo : loggerDebug);

        if (method == null) {
            return;
        }

        final String poolName = getPoolName() + " (" + schema + ")";
        final boolean showPool = schema.equals(ALL);

        try {
            method.invoke(logger, "pool: {}", (Object) new Object[]{ poolName });
            if (!finalCall) {
                method.invoke(logger,
                              "- time needed to open last connection (ms): {}",
                              (Object) new Object[]{ timeElapsed });
            }
            method.invoke(logger,
                          "- min/avg/max connection time (ms): {}/{}/{}",
                          (Object) new Object[]{ myDataSourceStatistics.getTimeElapsedMin(),
                                                 myDataSourceStatistics.getTimeElapsedAvg(),
                                                 myDataSourceStatistics.getTimeElapsedMax() });
            method.invoke(logger,
                          "- physical/logical connections opened: {}/{}",
                          (Object) new Object[]{ myDataSourceStatistics.getPhysicalConnectionCount(),
                                                 myDataSourceStatistics.getOpenConnectionCount() });

            if (!singleSessionProxyModel && connectInfo.getProxyUsername() != null) {
                method.invoke(logger,
                              "- proxy sessions opened/closed: {}/{}; logical connections closed: {}",
                              (Object) new Object[]{ myDataSourceStatistics.getOpenProxySessionCount(),
                                                     myDataSourceStatistics.getCloseProxySessionCount(),
                                                     myDataSourceStatistics.getCloseConnectionCount() });
            }
            
            if (showPool) {
                if (!finalCall) {
                    method.invoke(logger,
                                  "- initial/min/max pool size: {}/{}/{}" +
                                  "; active/idle/total connections: {}/{}/{}",
                                  (Object) new Object[]{ getInitialPoolSize(),
                                                         getMinimumPoolSize(),
                                                         getMaximumPoolSize(),
                                                         getActiveConnections(),
                                                         getIdleConnections(),
                                                         getTotalConnections() });
                } else {
                    method.invoke(logger,
                                  "- initial/min/max pool size: {}/{}/{}" +
                                  "; min/avg/max active connections: {}/{}/{}" +
                                  "; min/avg/max idle connections: {}/{}/{}" +
                                  "; min/avg/max total connections: {}/{}/{}",
                                  (Object) new Object[]{ getInitialPoolSize(),
                                                         getMinimumPoolSize(),
                                                         getMaximumPoolSize(),
                                                         myDataSourceStatistics.getActiveConnectionsMin(),
                                                         myDataSourceStatistics.getActiveConnectionsAvg(),
                                                         myDataSourceStatistics.getActiveConnectionsMax(),
                                                         myDataSourceStatistics.getIdleConnectionsMin(),
                                                         myDataSourceStatistics.getIdleConnectionsAvg(),
                                                         myDataSourceStatistics.getIdleConnectionsMax(),
                                                         myDataSourceStatistics.getTotalConnectionsMin(),
                                                         myDataSourceStatistics.getTotalConnectionsAvg(),
                                                         myDataSourceStatistics.getTotalConnectionsMax() });
                }
            }
        } catch (IllegalAccessException | InvocationTargetException e) {
            logger.error("showDataSourceStatistics exception: {}", e.getMessage());
        }
    }

    protected abstract void printDataSourceStatistics(final DataSource poolDataSource, final Logger logger);
    
    protected abstract void setCommonPoolDataSource(final DataSource commonPoolDataSource);

    protected abstract String getPoolNamePrefix();

    protected abstract String getPoolName();

    protected abstract void setPoolName(String poolName) throws SQLException;

    protected abstract void setUsername(String username) throws SQLException;

    protected abstract void setPassword(String password) throws SQLException;
        
    protected abstract int getInitialPoolSize();

    protected abstract int getInitialPoolSize(DataSource pds);

    protected abstract void setInitialPoolSize(int initialPoolSize) throws SQLException;

    protected abstract int getMinimumPoolSize();

    protected abstract int getMinimumPoolSize(DataSource pds);

    protected abstract void setMinimumPoolSize(int minimumPoolSize) throws SQLException;

    protected abstract int getMaximumPoolSize();

    protected abstract int getMaximumPoolSize(DataSource pds);

    protected abstract void setMaximumPoolSize(int maximumPoolSize) throws SQLException;

    protected abstract long getConnectionTimeout(); // milliseconds

    protected final String getUrl() {
        return (String) commonDataSourceProperties.get(URL);
    }

    // statistics
    
    protected abstract int getActiveConnections();

    protected abstract int getIdleConnections();

    protected abstract int getTotalConnections();
        
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

            logger.debug("ConnectInfo(username={}, password={}) = (username={}, password={}, proxyUsername={}, schema={})",
                         username,
                         password,
                         this.username,
                         this.password,
                         this.proxyUsername,
                         this.schema);
        }
    }
    
    protected class MyDataSourceStatistics {

        private final int ROUND_SCALE = 32;

        private final int DISPLAY_SCALE = 0;

        private AtomicLong openConnectionCount = new AtomicLong();

        private AtomicLong closeConnectionCount = new AtomicLong();
        
        private AtomicLong openProxySessionCount = new AtomicLong();
        
        private AtomicLong closeProxySessionCount = new AtomicLong();

        private AtomicLong timeElapsedMin = new AtomicLong(Long.MAX_VALUE);
    
        private AtomicLong timeElapsedMax = new AtomicLong(Long.MIN_VALUE);
    
        private AtomicBigDecimal timeElapsedAvg = new AtomicBigDecimal(BigDecimal.ZERO);

        private AtomicInteger activeConnectionsMin = new AtomicInteger(Integer.MAX_VALUE);
        
        private AtomicInteger activeConnectionsMax = new AtomicInteger(Integer.MIN_VALUE);

        private AtomicBigDecimal activeConnectionsAvg = new AtomicBigDecimal(BigDecimal.ZERO);
            
        private AtomicInteger idleConnectionsMin = new AtomicInteger(Integer.MAX_VALUE);
        
        private AtomicInteger idleConnectionsMax = new AtomicInteger(Integer.MIN_VALUE);

        private AtomicBigDecimal idleConnectionsAvg = new AtomicBigDecimal(BigDecimal.ZERO);
            
        private AtomicInteger totalConnectionsMin = new AtomicInteger(Integer.MAX_VALUE);
        
        private AtomicInteger totalConnectionsMax = new AtomicInteger(Integer.MIN_VALUE);

        private AtomicBigDecimal totalConnectionsAvg = new AtomicBigDecimal(BigDecimal.ZERO);

        private Set<OracleConnection> physicalConnections;

        public MyDataSourceStatistics() {
            // see https://www.geeksforgeeks.org/how-to-create-a-thread-safe-concurrenthashset-in-java/
            final ConcurrentHashMap<Connection, Integer> dummy = new ConcurrentHashMap<>();
 
            physicalConnections = dummy.newKeySet();
        }
        
        protected void update(final Connection conn,
                              final long timeElapsed) throws SQLException {
            update(conn,
                   timeElapsed,
                   -1,
                   -1,
                   -1);
        }

        protected void update(final Connection conn,
                              final long timeElapsed,
                              final int activeConnections,
                              final int idleConnections,
                              final int totalConnections) throws SQLException {
            physicalConnections.add(conn.unwrap(OracleConnection.class));
            
            // We must use count and avg from the same connection so just synchronize.
            // If we don't synchronize we risk to get the average and count from different connections.
            synchronized (this) {                
                final BigDecimal count = new BigDecimal(this.openConnectionCount.incrementAndGet());

                // Iterative Mean, see https://www.heikohoffmann.de/htmlthesis/node134.html
                
                // See https://stackoverflow.com/questions/4591206/
                //   arithmeticexception-non-terminating-decimal-expansion-no-exact-representable
                // to prevent this error: Non-terminating decimal expansion; no exact representable decimal result.
                if (timeElapsed >= 0L) {
                    timeElapsedAvg.addAndGet(new BigDecimal(timeElapsed).subtract(timeElapsedAvg.get()).divide(count,
                                                                                                               ROUND_SCALE,
                                                                                                               RoundingMode.HALF_UP));
                }
                if (activeConnections >= 0) {
                    activeConnectionsAvg.addAndGet(new BigDecimal(activeConnections).subtract(activeConnectionsAvg.get()).divide(count,
                                                                                                                                 ROUND_SCALE,
                                                                                                                                 RoundingMode.HALF_UP));
                }
                if (idleConnections >= 0) {
                    idleConnectionsAvg.addAndGet(new BigDecimal(idleConnections).subtract(idleConnectionsAvg.get()).divide(count,
                                                                                                                           ROUND_SCALE,
                                                                                                                           RoundingMode.HALF_UP));
                }
                if (totalConnections >= 0) {
                    totalConnectionsAvg.addAndGet(new BigDecimal(totalConnections).subtract(totalConnectionsAvg.get()).divide(count,
                                                                                                                              ROUND_SCALE,
                                                                                                                              RoundingMode.HALF_UP));
                }
            }

            // The rest is using AtomicInteger/AtomicLong, hence concurrent.
            if (timeElapsed >= 0L) {
                if (timeElapsed < timeElapsedMin.get()) {
                    timeElapsedMin.set(timeElapsed);
                }
                if (timeElapsed > timeElapsedMax.get()) {
                    timeElapsedMax.set(timeElapsed);
                }
            }

            if (activeConnections >= 0) {
                if (activeConnections < activeConnectionsMin.get()) {
                    activeConnectionsMin.set(activeConnections);
                }
                if (activeConnections > activeConnectionsMax.get()) {
                    activeConnectionsMax.set(activeConnections);
                }
            }

            if (idleConnections >= 0) {
                if (idleConnections < idleConnectionsMin.get()) {
                    idleConnectionsMin.set(idleConnections);
                }
                if (idleConnections > idleConnectionsMax.get()) {
                    idleConnectionsMax.set(idleConnections);
                }
            }

            if (totalConnections >= 0) {
                if (totalConnections < totalConnectionsMin.get()) {
                    totalConnectionsMin.set(totalConnections);
                }
                if (totalConnections > totalConnectionsMax.get()) {
                    totalConnectionsMax.set(totalConnections);
                }
            }
        }

        protected void update(final int closeConnectionCount,
                              final int openProxySessionCount,
                              final int closeProxySessionCount) {
            this.closeConnectionCount.addAndGet(closeConnectionCount);
            this.openProxySessionCount.addAndGet(openProxySessionCount);
            this.closeProxySessionCount.addAndGet(closeProxySessionCount);
        }
        
        protected boolean countersEqual(final MyDataSourceStatistics compareTo) {
            return
                this.getPhysicalConnectionCount() == compareTo.getPhysicalConnectionCount() &&
                this.getOpenConnectionCount() == compareTo.getOpenConnectionCount() &&
                this.getCloseConnectionCount() == compareTo.getCloseConnectionCount() &&
                this.getOpenProxySessionCount() == compareTo.getOpenProxySessionCount() &&
                this.getCloseProxySessionCount() == compareTo.getCloseProxySessionCount();
        }
        
        // getter(s)

        protected int getPhysicalConnectionCount() {
            return physicalConnections.size();
        }
            
        protected long getOpenConnectionCount() {
            return openConnectionCount.get();
        }

        protected long getCloseConnectionCount() {
            return closeConnectionCount.get();
        }

        protected long getOpenProxySessionCount() {
            return openProxySessionCount.get();
        }
        
        protected long getCloseProxySessionCount() {
            return closeProxySessionCount.get();
        }
        
        protected long getTimeElapsedMin() {
            return timeElapsedMin.get();
        }

        protected long getTimeElapsedMax() {
            return timeElapsedMax.get();
        }

        protected BigDecimal getTimeElapsedAvg() {
            return timeElapsedAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP);
        }

        protected int getActiveConnectionsMin() {
            return activeConnectionsMin.get();
        }

        protected int getActiveConnectionsMax() {
            return activeConnectionsMax.get();
        }

        protected BigDecimal getActiveConnectionsAvg() {
            return activeConnectionsAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP);
        }

        protected int getIdleConnectionsMin() {
            return idleConnectionsMin.get();
        }

        protected int getIdleConnectionsMax() {
            return idleConnectionsMax.get();
        }
        
        protected BigDecimal getIdleConnectionsAvg() {
            return idleConnectionsAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP);
        }
        
        protected int getTotalConnectionsMin() {
            return totalConnectionsMin.get();
        }

        protected int getTotalConnectionsMax() {
            return totalConnectionsMax.get();
        }

        protected BigDecimal getTotalConnectionsAvg() {
            return totalConnectionsAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP);
        }

        /**
         * @author Alexander_Sergeev
         *
         * See https://github.com/qbit-for-money/commons/blob/master/src/main/java/com/qbit/commons/model/AtomicBigDecimal.java
         */
        private final class AtomicBigDecimal {

            private final AtomicReference<BigDecimal> valueHolder = new AtomicReference<>();

            public AtomicBigDecimal(BigDecimal value) {
                valueHolder.set(value);
            }

            public BigDecimal get() {
                return valueHolder.get();
            }

            public BigDecimal addAndGet(final BigDecimal value) {
                while (true) {
                    BigDecimal current = valueHolder.get();
                    BigDecimal next = current.add(value);
                    if (valueHolder.compareAndSet(current, next)) {
                        return next;
                    }
                }
            }

            public BigDecimal setAndGet(final BigDecimal value) {
                while (true) {
                    BigDecimal current = valueHolder.get();

                    if (valueHolder.compareAndSet(current, value)) {
                        return value;
                    }
                }
            }
        }
    }
}
