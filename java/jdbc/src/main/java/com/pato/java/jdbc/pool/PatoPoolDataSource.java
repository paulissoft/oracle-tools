package com.pato.java.jdbc.pool;

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
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import javax.sql.DataSource;
import lombok.experimental.Delegate;
import oracle.jdbc.OracleConnection;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public abstract class PatoPoolDataSource implements DataSource, Closeable {
    public static final String CLASS = "class";

    public static final String CONNECTION_FACTORY_CLASS_NAME = "connectionFactoryClassName";
        
    public static final String URL = "url";

    public static final String USERNAME = "username";
    
    public static final String PASSWORD = "password";
    
    public static final String POOL_NAME = "poolName";

    private static final String ALL = "*";

    private static final Logger logger = LoggerFactory.getLogger(PatoPoolDataSource.class);

    private static Method loggerInfo;

    private static Method loggerDebug;

    private static Properties keyDataSourceStatisticsAll = new Properties();

    protected static Map<Properties, MyDataSourceStatistics> allDataSourceStatistics = new ConcurrentHashMap<>();

    static {
        logger.info("Initializing {}", PatoPoolDataSource.class.toString());
        
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

        setProperty(keyDataSourceStatisticsAll, USERNAME, ALL);
        setProperty(keyDataSourceStatisticsAll, PASSWORD, "");
    }

    private interface Overrides {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;
    }
    
    @Delegate(excludes=Overrides.class)
    protected DataSource commonPoolDataSource = null;

    protected boolean statisticsEnabled = false;

    // see https://docs.oracle.com/en/database/oracle/oracle-database/19/jajdb/oracle/jdbc/OracleConnection.html
    // true - do not use openProxySsession() but use proxyUsername[schema]
    // false - use openProxySsession() (two sessions will appear in v$session)
    protected boolean singleSessionProxyModel = true; 

    protected String username;

    protected String password;
    
    // username like:
    // * bc_proxy[bodomain] => proxyUsername = bc_proxy, schema = bodomain
    // * bodomain => proxyUsername = null, schema = bodomain
    private StringBuffer proxyUsername;
    
    protected StringBuffer schema; // needed to build the PoolName
    
    // same properties for URL, username (without schema), password and data source class: same pool DataSource
    private Properties key;

    // properties include URL, username (with an optional schema), password and data source class
    private Properties keyDataSourceStatistics;

    private static Map<Properties, DataSource> dataSources = new ConcurrentHashMap<>();

    private static Map<Properties, AtomicInteger> currentPoolCount = new ConcurrentHashMap<>();    

    private static Map<Properties, AtomicInteger> maximumPoolCount = new ConcurrentHashMap<>();    

    /**
     * Initialize a pool data source.
     *
     * @param pds       A pool data source (HikariCP or UCP).
     * @param key       The properties of the pool data source that have to be equal to create a common pool data source.
     *                  Mandatory properties: "class" and "url".
     * @param username  The username to connect to, may be a proxy username like BC_PROXY[BDOMAIN].
     *                  Username must NOT be part of the key since a pool data source allows connections to different users.
     * @param password  The password.
     */
    protected PatoPoolDataSource(final DataSource pds,
                               final Properties key,
                               final String username,
                               final String password) {
        logger.debug(">PatoPoolDataSource(pds={}, username={})", pds, username);

        this.key = key;

        checkKeyPropertyNotNull(CLASS);
        checkKeyPropertyNotNull(URL);

        checkKeyPropertyNull(USERNAME);
        checkKeyPropertyNull(PASSWORD);
        checkKeyPropertyNull(POOL_NAME);
    
        this.username = username;
        this.password = password;
        
        this.schema = new StringBuffer(this.username.length());
        this.proxyUsername = new StringBuffer(this.username.length());

        getSchemaProxyUsername(this.username, this.schema, this.proxyUsername);

        this.commonPoolDataSource = dataSources.computeIfAbsent(this.key, s -> pds);
        this.currentPoolCount.computeIfAbsent(this.key, s -> new AtomicInteger()).incrementAndGet();
        this.maximumPoolCount.computeIfAbsent(this.key, s -> new AtomicInteger()).incrementAndGet();

        // The statistics are measured per original data source.
        // So we include the username / password.
        this.keyDataSourceStatistics = new Properties(this.key);
        setProperty(this.keyDataSourceStatistics, USERNAME, this.username);
        setProperty(this.keyDataSourceStatistics, PASSWORD, this.password);        
        // add total if not already existent
        this.allDataSourceStatistics.computeIfAbsent(this.keyDataSourceStatisticsAll, s -> new MyDataSourceStatistics());
        this.allDataSourceStatistics.computeIfAbsent(this.keyDataSourceStatistics, s -> new MyDataSourceStatistics());

        logger.debug("<PatoPoolDataSource()");
    }

    protected static void setProperty(final Properties key,
                                      final String name,
                                      final Object value) {
        if (name != null && value != null) {
            key.put(name, value);
        }
    }
    
    private void checkKeyPropertyNull(final String name) {
        try {
            assert(key.get(name) == null);
        } catch (AssertionError ex) {
            System.err.println(String.format("Property ({}) must be null", name));
            throw ex;
        }
    }
    
    private void checkKeyPropertyNotNull(final String name) {
        try {
            assert(key.get(name) != null);
        } catch (AssertionError ex) {
            System.err.println(String.format("Property ({}) must NOT be null", name));
            throw ex;
        }
    }

    /**
     * Turn a proxy connection username (bc_proxy[bodomain] or bodomain) into
     * schema (bodomain) and proxy username (bc_proxy respectively empty).
     *
     * @param username       The username to connect to.
     * @param schema         An empty (mutable) string buffer for schema.
     * @param proxyUsername  An empty (mutable) string buffer for proxy username.
     *
     */    
    private void getSchemaProxyUsername(final String username,
                                        final StringBuffer schema,
                                        final StringBuffer proxyUsername) {
        assert(schema.length() <= 0);
        assert(proxyUsername.length() <= 0);
        
        final int pos1 = username.indexOf("[");
        final int pos2 = ( username.endsWith("]") ? username.length() - 1 : -1 );
      
        if (pos1 >= 0 && pos2 >= pos1) {
            // a username like bc_proxy[bodomain]
            proxyUsername.append(username.substring(0, pos1));
            schema.append(username.substring(pos1+1, pos2));
        } else {
            // a username like bodomain
            proxyUsername.append("");
            schema.append(username);
        }
    }

    public void close() {
        if (done()) {
            commonPoolDataSource = null;
        }
    }

    // returns true if there are no more pool data sources hereafter
    final protected boolean done() {
        final boolean lastPoolDataSource = currentPoolCount.get(key).decrementAndGet() == 0;

        if (statisticsEnabled) {
            final MyDataSourceStatistics myDataSourceStatistics = allDataSourceStatistics.get(keyDataSourceStatistics);

            // no need to display same statistics twice (see below for ALL)
            if (!lastPoolDataSource || maximumPoolCount.get(key).get() > 1) {
                showDataSourceStatistics(myDataSourceStatistics, -1L, true, schema.toString());
            }
            allDataSourceStatistics.remove(keyDataSourceStatistics);

            if (lastPoolDataSource) {
                final MyDataSourceStatistics myDataSourceStatisticsAll = allDataSourceStatistics.get(keyDataSourceStatisticsAll);
                
                // show (and remove) totals
                showDataSourceStatistics(myDataSourceStatisticsAll, -1L, true, ALL);
                allDataSourceStatistics.remove(keyDataSourceStatisticsAll);
            }
        }
            
        if (lastPoolDataSource) {
            logger.info("Closing pool {}", getPoolName());
            dataSources.remove(key);
            commonPoolDataSource = null;
        }

        return lastPoolDataSource;
    }

    public Connection getConnection() throws SQLException {
        return getConnectionSmart(this.username,
                                  this.password,
                                  this.schema.toString(),
                                  this.proxyUsername.toString());
    }

    public Connection getConnection(String username, String password) throws SQLException {
        final StringBuffer schema = new StringBuffer(username.length());
        final StringBuffer proxyUsername = new StringBuffer(username.length());

        getSchemaProxyUsername(username, schema, proxyUsername);

        return getConnectionSmart(username,
                                  password,
                                  schema.toString(),
                                  proxyUsername.toString());
    }

    protected Connection getConnectionSimple(String username, String password) throws SQLException {
        return commonPoolDataSource.getConnection(username, password);
    }
    
    private Connection getConnectionSmart(final String username,
                                          final String password,
                                          final String schema,
                                          final String proxyUsername) throws SQLException {
        logger.trace(">getConnectionSmart(username={}, password={}, schema={}, proxyUsername={})",
                     username,
                     password,
                     schema,
                     proxyUsername);

        final Instant t1 = Instant.now();
        Connection conn = null;
        
        if (proxyUsername == null || proxyUsername.length() <= 0 || singleSessionProxyModel) {
            conn = getConnectionSimple(username, password);
        } else {
            conn = getConnectionSimple(proxyUsername, password); // see NOTE 1

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
                }
            }

            if (oraConn != null) { // set up proxy session
                Properties proxyProperties = new Properties();
            
                proxyProperties.setProperty(OracleConnection.PROXY_USER_NAME, schema);

                logger.trace("opening proxy session");

                oraConn.openProxySession(OracleConnection.PROXYTYPE_USER_NAME, proxyProperties);
                conn.setSchema(schema);

                logger.trace("current schema after = {}", oraConn.getCurrentSchema());

                try {
                    if (statisticsEnabled) {
                        allDataSourceStatistics.get(keyDataSourceStatistics).incrementProxySessionCount();
                    }
                } catch (Exception e) {
                    logger.error("MyDataSourceStatistics.incrementProxySessionCount() exception: {}", e.getMessage());
                }
            }
        }

        if (statisticsEnabled) {
            showElapsedTime(t1);
        }

        logger.trace(">getConnectionSmart() = {}", conn);

        return conn;
    }

    private void showElapsedTime(final Instant t1) {
        if (!statisticsEnabled) {
            return;
        }
        
        final MyDataSourceStatistics myDataSourceStatistics = allDataSourceStatistics.get(keyDataSourceStatistics);
        final MyDataSourceStatistics myDataSourceStatisticsAll = allDataSourceStatistics.get(keyDataSourceStatisticsAll);
        final Instant t2 = Instant.now();
        long timeElapsed;

        try {
            timeElapsed = myDataSourceStatisticsAll.updateAndGetTimeElapsed(t1,
                                                                            t2,
                                                                            getActiveConnections(),
                                                                            getIdleConnections(),
                                                                            getTotalConnections());
            myDataSourceStatistics.update(timeElapsed);
        } catch (Exception e) {
            timeElapsed = -1L;
            
            logger.error("getElapsedTime() exception: {}", e.getMessage());
        }

        // no need to display same statistics twice (see below for totals)
        if (maximumPoolCount.get(key).get() > 1) {
            showDataSourceStatistics(myDataSourceStatistics, timeElapsed, false, schema.toString());
        }
        showDataSourceStatistics(myDataSourceStatisticsAll, timeElapsed, false, ALL);
    }

    protected void printDataSourceStatistics(final MyDataSourceStatistics myDataSourceStatistics, final Logger logger) {
        // Only show the first time a pool has gotten a connection.
        // Not earlier because these (fixed) values may change before and after the first connection.
        if (myDataSourceStatistics.getCount() == 1) {
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
                                          final long timeElapsed,
                                          final boolean finalCall,
                                          final String schema) {
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
                              "- proxy sessions/connections: {}/{}" +
                              "; time needed to open last connection (ms): {}" +
                              "; min/avg/max connection time (ms): {}/{}/{}",
                              (Object) new Object[]{ myDataSourceStatistics.getProxySessionCount(),
                                                     myDataSourceStatistics.getCount(),
                                                     timeElapsed,
                                                     myDataSourceStatistics.getTimeElapsedMin(),
                                                     myDataSourceStatistics.getTimeElapsedAvg(),
                                                     myDataSourceStatistics.getTimeElapsedMax() });
                if (showPool) {
                    method.invoke(logger,
                                  "- initial/min/max pool size: {}/{}/{}" +
                                  "; active/idle/total connections: {}/{}/{}",
                                  (Object) new Object[]{ getInitialPoolSize(),
                                                         getMinimumPoolSize(),
                                                         getMaximumPoolSize(),
                                                         getActiveConnections(),
                                                         getIdleConnections(),
                                                         getTotalConnections() });
                }
            } else {
                method.invoke(logger,
                              "- proxy sessions/connections: {}/{}; min/avg/max connection time (ms): {}/{}/{}",
                              (Object) new Object[]{ myDataSourceStatistics.getProxySessionCount(),
                                                     myDataSourceStatistics.getCount(),
                                                     myDataSourceStatistics.getTimeElapsedMin(),
                                                     myDataSourceStatistics.getTimeElapsedAvg(),
                                                     myDataSourceStatistics.getTimeElapsedMax() });
                if (showPool) {
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
        return (String) key.get("connectionFactoryClassName");
    }

    protected String getUrl() {
        return (String) key.get("url");
    }

    protected String getUsername() {
        return username;
    }

    protected String getPassword() {
        return password;
    }

    protected void setStatisticsEnabled(final boolean statisticsEnabled) {
        this.statisticsEnabled = statisticsEnabled;
    }

    protected void setSingleSessionProxyModel(final boolean singleSessionProxyModel) {
        this.singleSessionProxyModel = singleSessionProxyModel;
    }

    protected abstract int getActiveConnections();

    protected abstract int getIdleConnections();

    protected abstract int getTotalConnections();

    protected abstract int getInitialPoolSize();
        
    protected abstract int getMinimumPoolSize();

    protected abstract int getMaximumPoolSize();

    protected class MyDataSourceStatistics {

        private final int ROUND_SCALE = 32;

        private final int DISPLAY_SCALE = 0;

        private AtomicLong count = new AtomicLong();

        private AtomicLong proxySessionCount = new AtomicLong();

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

        protected long updateAndGetTimeElapsed(final Instant t1,
                                               final Instant t2,
                                               final int activeConnections,
                                               final int idleConnections,
                                               final int totalConnections) {
            final long timeElapsed = Duration.between(t1, t2).toMillis();

            assert(timeElapsed >= 0L);

            update(timeElapsed, activeConnections, idleConnections, totalConnections);

            return timeElapsed;
        }

        protected void update(final long timeElapsed) {
            update(timeElapsed, -1, -1, -1);
        }

        private void update(final long timeElapsed,
                            final int activeConnections,
                            final int idleConnections,
                            final int totalConnections) {
            // We must use count and avg from the same connection so just synchronize.
            // If we don't synchronize we risk to get the average and count from different connections.
            synchronized (this) {
                final BigDecimal count = new BigDecimal(this.count.incrementAndGet());

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

        // getter(s)
        protected long getCount() {
            return count.get();
        }

        protected long getProxySessionCount() {
            return proxySessionCount.get();
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

        // setter(s)
        protected void incrementProxySessionCount() {
            proxySessionCount.incrementAndGet();
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
