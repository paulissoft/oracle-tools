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
    @Getter
    private DataSource commonPoolDataSource = null;

    @Getter
    @Setter
    private boolean statisticsEnabled = false;

    // see https://docs.oracle.com/en/database/oracle/oracle-database/19/jajdb/oracle/jdbc/OracleConnection.html
    // true - do not use openProxySsession() but use proxyUsername[schema]
    // false - use openProxySsession() (two sessions will appear in v$session)
    @Getter
    @Setter
    private boolean singleSessionProxyModel = true;

    private ConnectInfo connectInfo;

    // Same properties for URL, username (without schema), password and data source class: same pool DataSource.
    private Properties commonDataSourceProperties = new Properties();

    // Same as commonDataSourceProperties, i.e. total per common data source.
    private Properties commonDataSourceStatisticsTotal = new Properties();

    // Same as commonDataSourceProperties including username and password,
    // only connection info like elapsed time, open/close sessions.
    private Properties commonDataSourceStatistics = new Properties();

    /**
     * Initialize a pool data source.
     *
     * @param pds                         A pool data source (HikariCP or UCP).
     * @param commonDataSourceProperties  The properties of the pool data source that have to be equal to create a common pool data source.
     *                                    Mandatory properties: CLASS and URL.
     * @param username                    The username to connect to, may be a proxy username like BC_PROXY[BDOMAIN].
     *                                    Username must NOT be part of the commonDataSourceProperties
     *                                    since a pool data source allows connections to different users.
     * @param password                    The password.
     *                                    Must also NOT be part of the commonDataSourceProperties.
     */
    protected SmartPoolDataSource(final DataSource pds,
                                 final Properties commonDataSourceProperties,
                                 final String username,
                                 final String password) {
        logger.debug(">SmartPoolDataSource(pds={}, username={})", pds, username);

        this.commonDataSourceProperties.putAll(commonDataSourceProperties);

        checkPropertyNotNull(CLASS);
        checkPropertyNotNull(URL);

        checkPropertyNull(USERNAME);
        checkPropertyNull(PASSWORD);
        checkPropertyNull(POOL_NAME);
    
        connectInfo = new ConnectInfo(username, password);

        this.commonPoolDataSource = dataSources.computeIfAbsent(this.commonDataSourceProperties, s -> pds);
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
                showDataSourceStatistics(myDataSourceStatistics, getSchema());
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
        return getConnectionSmart(this.connectInfo.getUsername(),
                                  this.connectInfo.getPassword(),
                                  this.connectInfo.getSchema(),
                                  this.connectInfo.getProxyUsername());
    }

    public Connection getConnection(String username, String password) throws SQLException {
        final ConnectInfo connectInfo = new ConnectInfo(username, password);

        return getConnectionSmart(connectInfo.getUsername(),
                                  connectInfo.getPassword(),
                                  connectInfo.getSchema(),
                                  connectInfo.getProxyUsername());
    }

    // can be overridden
    protected Connection getConnectionSimple(String username, String password) throws SQLException {
        return commonPoolDataSource.getConnection(username, password);
    }
    
    private Connection getConnectionSmart(final String username,
                                          final String password,
                                          final String schema,
                                          final String proxyUsername) throws SQLException {
        final Instant t1 = Instant.now();
        int countOpenSession = 0, countCloseSession = 0, countOpenProxySession = 0, countCloseProxySession = 0;

        logger.trace(">getConnectionSmart(username={}, password={}, schema={}, proxyUsername={})",
                     username,
                     password,
                     schema,
                     proxyUsername);

        Connection conn = null;
        
        if (singleSessionProxyModel || proxyUsername == null || proxyUsername.length() <= 0) {
            conn = getConnectionSimple(username, password);
            countOpenSession++;
        } else {
            conn = getConnectionSimple(proxyUsername, password);
            countOpenSession++;

            OracleConnection oraConn = conn.unwrap(OracleConnection.class);
            final String currentSchema = oraConn.getCurrentSchema();
        
            logger.trace("current schema before = {}; oracle connection = {}", currentSchema, oraConn);

            if (oraConn.isProxySession()) {
                if (currentSchema.equals(schema)) {
                    logger.trace("no need to close/open a proxy session since the current schema is the requested schema");
                
                    oraConn = null; // we are done
                } else {
                    logger.trace("closing proxy session since the current schema is not the requested schema");
                
                    oraConn.close(OracleConnection.PROXY_SESSION);
                    countCloseProxySession++;
                }
            }

            if (oraConn != null) { // set up proxy session
                Properties proxyProperties = new Properties();
            
                proxyProperties.setProperty(OracleConnection.PROXY_USER_NAME, schema);

                logger.trace("opening proxy session");

                oraConn.openProxySession(OracleConnection.PROXYTYPE_USER_NAME, proxyProperties);
                conn.setSchema(schema);
                countOpenProxySession++;

                logger.trace("current schema after = {}", oraConn.getCurrentSchema());
            }
        }

        if (statisticsEnabled) {
            updateStatistics(conn,
                             Duration.between(t1, Instant.now()).toMillis(),
                             countOpenSession,
                             countCloseSession,
                             countOpenProxySession,
                             countCloseProxySession);
        }

        logger.trace(">getConnectionSmart() = {}", conn);

        return conn;
    }

    private void updateStatistics(final Connection conn,
                                  final long timeElapsed,
                                  final int countOpenSession,
                                  final int countCloseSession,
                                  final int countOpenProxySession,
                                  final int countCloseProxySession) {
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
                                                    countOpenSession,
                                                    countCloseSession,
                                                    countOpenProxySession,
                                                    countCloseProxySession,
                                                    activeConnections,
                                                    idleConnections,
                                                    totalConnections);
            myDataSourceStatisticsTotal.update(conn,
                                               timeElapsed,
                                               countOpenSession,
                                               countCloseSession,
                                               countOpenProxySession,
                                               countCloseProxySession,
                                               activeConnections,
                                               idleConnections,
                                               totalConnections);
            // no need for active/idle and total connections because that is counted on common data source level
            myDataSourceStatistics.update(conn,
                                          timeElapsed,
                                          countOpenSession,
                                          countCloseSession,
                                          countOpenProxySession,
                                          countCloseProxySession);
        } catch (Exception e) {
            logger.error("updateStatistics() exception: {}", e.getMessage());
        }

        // no need to display same statistics twice (see below for totals)
        if (!myDataSourceStatistics.countersEqual(myDataSourceStatisticsTotal)) {
            showDataSourceStatistics(myDataSourceStatistics, getSchema(), timeElapsed, false);
        }
        showDataSourceStatistics(myDataSourceStatisticsTotal, ALL, timeElapsed, false);
    }

    protected void printDataSourceStatistics(final MyDataSourceStatistics myDataSourceStatistics, final Logger logger) {
        // Only show the first time a pool has gotten a connection.
        // Not earlier because these (fixed) values may change before and after the first connection.
        if (myDataSourceStatistics.getCountOpenSession() == 1) {
            logger.info("poolName: {}", getPoolName());
            logger.info("connectionFactoryClassName: {}", getConnectionFactoryClassName());
            logger.info("jdbcUrl: {}", getUrl());
            logger.info("username: {}", getUsername());
        }
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
        printDataSourceStatistics(myDataSourceStatistics, logger);

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
                          "- physical/logical/proxy sessions opened: {}/{}/{}",
                          (Object) new Object[]{ myDataSourceStatistics.getCountConnections(),
                                                 myDataSourceStatistics.getCountOpenSession(),
                                                 myDataSourceStatistics.getCountOpenProxySession() });
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

    protected abstract String getPoolName();

    protected String getConnectionFactoryClassName() {
        return (String) commonDataSourceProperties.get(CONNECTION_FACTORY_CLASS_NAME);
    }

    protected String getUrl() {
        return (String) commonDataSourceProperties.get(URL);
    }

    protected String getUsername() {
        return connectInfo.getUsername();
    }

    protected String getPassword() {
        return connectInfo.getPassword();
    }

    protected String getSchema() {
        return connectInfo.getSchema();
    }

    protected String getProxyUsername() {
        return connectInfo.getProxyUsername();
    }

    protected abstract int getActiveConnections();

    protected abstract int getIdleConnections();

    protected abstract int getTotalConnections();

    protected abstract int getInitialPoolSize();
        
    protected abstract int getMinimumPoolSize();

    protected abstract int getMaximumPoolSize();

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
        }
    }
    
    protected class MyDataSourceStatistics {

        private final int ROUND_SCALE = 32;

        private final int DISPLAY_SCALE = 0;

        private AtomicLong countOpenSession = new AtomicLong();
        
        private AtomicLong countCloseSession = new AtomicLong();
        
        private AtomicLong countOpenProxySession = new AtomicLong();
        
        private AtomicLong countCloseProxySession = new AtomicLong();

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

        private Set<Connection> connections;

        public MyDataSourceStatistics() {
            // see https://www.geeksforgeeks.org/how-to-create-a-thread-safe-concurrenthashset-in-java/
            final ConcurrentHashMap<Connection, Integer> dummy = new ConcurrentHashMap<>();
 
            connections = dummy.newKeySet();
        }
        
        protected void update(final Connection conn,
                              final long timeElapsed,
                              final int countOpenSession,
                              final int countCloseSession,
                              final int countOpenProxySession,
                              final int countCloseProxySession) {
            update(conn,
                   timeElapsed,
                   countOpenSession,
                   countCloseSession,
                   countOpenProxySession,
                   countCloseProxySession,
                   -1,
                   -1,
                   -1);
        }

        protected void update(final Connection conn,
                              final long timeElapsed,
                              final int countOpenSession,
                              final int countCloseSession,
                              final int countOpenProxySession,
                              final int countCloseProxySession,
                              final int activeConnections,
                              final int idleConnections,
                              final int totalConnections) {
            // We must use count and avg from the same connection so just synchronize.
            // If we don't synchronize we risk to get the average and count from different connections.
            synchronized (this) {
                connections.add(conn);
                
                final BigDecimal count = new BigDecimal(this.countOpenSession.addAndGet(countOpenSession));

                this.countCloseSession.addAndGet(countCloseSession);
                this.countOpenProxySession.addAndGet(countOpenProxySession);
                this.countCloseProxySession.addAndGet(countCloseProxySession);

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

        protected boolean countersEqual(final MyDataSourceStatistics compareTo) {
            return
                this.getCountOpenSession() == compareTo.getCountOpenSession() &&
                this.getCountCloseSession() == compareTo.getCountCloseSession() &&
                this.getCountOpenProxySession() == compareTo.getCountOpenProxySession() &&
                this.getCountCloseProxySession() == compareTo.getCountCloseProxySession();
        }
        
        // getter(s)

        protected int getCountConnections() {
            return connections.size();
        }
            
        protected long getCountOpenSession() {
            return countOpenSession.get();
        }

        protected long getCountCloseSession() {
            return countCloseSession.get();
        }

        protected long getCountOpenProxySession() {
            return countOpenProxySession.get();
        }
        
        protected long getCountCloseProxySession() {
            return countCloseProxySession.get();
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
