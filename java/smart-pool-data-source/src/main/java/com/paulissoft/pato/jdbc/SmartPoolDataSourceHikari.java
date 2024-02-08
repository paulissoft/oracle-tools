package com.paulissoft.pato.jdbc;

import org.springframework.beans.DirectFieldAccessor;    
import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.pool.HikariPool;
// GJP 2024-02-08
// ProxyConnection does seem to be essential to close pool proxy connections
import com.zaxxer.hikari.pool.ProxyConnection;
import java.io.Closeable;
import java.sql.Connection;
import java.util.ArrayList;
import oracle.jdbc.OracleConnection;
import javax.sql.DataSource;
import java.sql.SQLException;
import java.util.Properties;
import lombok.experimental.Delegate;
import java.time.Instant;
import java.time.Duration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SmartPoolDataSourceHikari extends SmartPoolDataSource implements HikariConfigMXBean, Closeable {

    private static final Logger logger = LoggerFactory.getLogger(SmartPoolDataSourceHikari.class);

    public static final String AUTO_COMMIT = "autoCommit";

    public static final String CONNECTION_TIMEOUT = "connectionTimeout";

    public static final String IDLE_TIMEOUT = "idleTimeout";

    public static final String MAX_LIFETIME = "maxLifetime";

    public static final String CONNECTION_TEST_QUERY = "connectionTestQuery";

    public static final String INITIALIZATION_FAIL_TIMEOUT = "initializationFailTimeout";

    public static final String ISOLATE_INTERNAL_QUERIES = "isolateInternalQueries";

    public static final String ALLOW_POOL_SUSPENSION = "allowPoolSuspension";

    public static final String READ_ONLY = "readOnly";

    public static final String REGISTER_MBEANS = "registerMbeans";

    public static final String VALIDATION_TIMEOUT = "validationTimeout";

    public static final String LEAK_DETECTION_THRESHOLD = "leakDetectionThreshold";
    
    static {
        logger.info("Initializing {}", SmartPoolDataSourceHikari.class.toString());
    }

    private interface Overrides {
        public void close();

        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;

        public int getMaximumPoolSize();
        
        public void setMaximumPoolSize(int maxPoolSize);
        
        /*
        // To solve this error:
        //
        // getDataSourceProperties() in nl.bluecurrent.backoffice.configuration.SmartPoolDataSourceHikari cannot override
        // getDataSourceProperties() in nl.bluecurrent.backoffice.configuration.SmartPoolDataSource
        // return type java.util.Properties is not compatible with org.springframework.boot.autoconfigure.jdbc.DataSourceProperties
        */
        public Properties getDataSourceProperties();
    }
    
    @Delegate(excludes=Overrides.class)
    private HikariDataSource commonPoolDataSourceHikari;

    public SmartPoolDataSourceHikari(final HikariDataSource pds,
                                     final String username,
                                     final String password) throws SQLException {
        /*
         * NOTE 1.
         *
         * HikariCP does not support getConnection(String username, String password) so set
         * singleSessionProxyModel to false and useFixedUsernamePassword to true so the
         * common properties will include the proxy user name ("bc_proxy" from "bc_proxy[bodomain]")
         * if any else just the username. Meaning "bc_proxy[bodomain]", "bc_proxy[boauth]" and so one
         * will have ONE common pool data source.
         */
        super(pds, determineCommonDataSourceProperties(pds), username, password, false, true);

        logger.debug("commonPoolDataSourceHikari: {}", commonPoolDataSourceHikari.getPoolName());

        // pool name, sizes and username / password already done in super constructor
        synchronized (commonPoolDataSourceHikari) {
            if (commonPoolDataSourceHikari != pds) {
                final int newValue = pds.getMinimumIdle();
                final int oldValue = getMinimumIdle();

                logger.debug("minimum idle before: {}", oldValue);

                if (newValue >= 0) {
                    setMinimumIdle(newValue + Integer.max(oldValue, 0));
                }

                logger.debug("minimum idle after: {}", getMinimumIdle());
            }
        }
    }

    private static Properties determineCommonDataSourceProperties(final HikariDataSource pds) {
        final Properties commonDataSourceProperties = new Properties();

        SmartPoolDataSource.setProperty(commonDataSourceProperties, SmartPoolDataSource.CLASS, pds.getClass().getName());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, SmartPoolDataSource.URL, pds.getJdbcUrl());
        // by first setting getDriverClassName(), getDataSourceClassName() will overwrite that one
        SmartPoolDataSource.setProperty(commonDataSourceProperties, SmartPoolDataSource.CONNECTION_FACTORY_CLASS_NAME, pds.getDriverClassName());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, SmartPoolDataSource.CONNECTION_FACTORY_CLASS_NAME, pds.getDataSourceClassName());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, AUTO_COMMIT, pds.isAutoCommit());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, CONNECTION_TIMEOUT, pds.getConnectionTimeout());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, IDLE_TIMEOUT, pds.getIdleTimeout());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, MAX_LIFETIME, pds.getMaxLifetime());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, CONNECTION_TEST_QUERY, pds.getConnectionTestQuery());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, INITIALIZATION_FAIL_TIMEOUT, pds.getInitializationFailTimeout());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, ISOLATE_INTERNAL_QUERIES, pds.isIsolateInternalQueries());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, ALLOW_POOL_SUSPENSION, pds.isAllowPoolSuspension());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, READ_ONLY, pds.isReadOnly());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, REGISTER_MBEANS, pds.isRegisterMbeans());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, VALIDATION_TIMEOUT, pds.getValidationTimeout());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, LEAK_DETECTION_THRESHOLD, pds.getLeakDetectionThreshold());

        return commonDataSourceProperties;
    }

    protected void printDataSourceStatistics(final DataSource poolDataSource, final Logger logger) {
        if (!logger.isDebugEnabled()) {
            return;
        }
        
        final HikariDataSource poolDataSourceHikari = ((HikariDataSource)poolDataSource);
        final String prefix = INDENT_PREFIX;
        
        logger.debug("configuration pool data source {}:", poolDataSourceHikari.getPoolName());
        logger.debug("{}driverClassName: {}", prefix, poolDataSourceHikari.getDriverClassName());
        logger.debug("{}dataSourceClassName: {}", prefix, poolDataSourceHikari.getDataSourceClassName());
        logger.debug("{}jdbcUrl: {}", prefix, poolDataSourceHikari.getJdbcUrl());
        logger.debug("{}username: {}", prefix, poolDataSourceHikari.getUsername());
        logger.debug("{}autoCommit: {}", prefix, poolDataSourceHikari.isAutoCommit());
        logger.debug("{}connectionTimeout: {}", prefix, poolDataSourceHikari.getConnectionTimeout());
        logger.debug("{}idleTimeout: {}", prefix, poolDataSourceHikari.getIdleTimeout());
        logger.debug("{}maxLifetime: {}", prefix, poolDataSourceHikari.getMaxLifetime());
        logger.debug("{}connectionTestQuery: {}", prefix, poolDataSourceHikari.getConnectionTestQuery());
        logger.debug("{}minimumIdle: {}", prefix, poolDataSourceHikari.getMinimumIdle());
        logger.debug("{}maximumPoolSize: {}", prefix, poolDataSourceHikari.getMaximumPoolSize());
        logger.debug("{}metricRegistry: {}", prefix, poolDataSourceHikari.getMetricRegistry());
        logger.debug("{}healthCheckRegistry: {}", prefix, poolDataSourceHikari.getHealthCheckRegistry());
        logger.debug("{}initializationFailTimeout: {}", prefix, poolDataSourceHikari.getInitializationFailTimeout());
        logger.debug("{}isolateInternalQueries: {}", prefix, poolDataSourceHikari.isIsolateInternalQueries());
        logger.debug("{}allowPoolSuspension: {}", prefix, poolDataSourceHikari.isAllowPoolSuspension());
        logger.debug("{}readOnly: {}", prefix, poolDataSourceHikari.isReadOnly());
        logger.debug("{}registerMbeans: {}", prefix, poolDataSourceHikari.isRegisterMbeans());
        logger.debug("{}catalog: {}", prefix, poolDataSourceHikari.getCatalog());
        logger.debug("{}connectionInitSql: {}", prefix, poolDataSourceHikari.getConnectionInitSql());
        logger.debug("{}driverClassName: {}", prefix, poolDataSourceHikari.getDriverClassName());
        logger.debug("{}dataSourceClassName: {}", prefix, poolDataSourceHikari.getDataSourceClassName());
        logger.debug("{}transactionIsolation: {}", prefix, poolDataSourceHikari.getTransactionIsolation());
        logger.debug("{}validationTimeout: {}", prefix, poolDataSourceHikari.getValidationTimeout());
        logger.debug("{}leakDetectionThreshold: {}", prefix, poolDataSourceHikari.getLeakDetectionThreshold());
        logger.debug("{}dataSource: {}", prefix, poolDataSourceHikari.getDataSource());
        logger.debug("{}schema: {}", prefix, poolDataSourceHikari.getSchema());
        logger.debug("{}threadFactory: {}", prefix, poolDataSourceHikari.getThreadFactory());
        logger.debug("{}scheduledExecutor: {}", prefix, poolDataSourceHikari.getScheduledExecutor());

        logger.debug("connections pool data source {}:", poolDataSourceHikari.getPoolName());
        logger.debug("{}total: {}", prefix, getTotalConnections(poolDataSourceHikari));
        logger.debug("{}active: {}", prefix, getActiveConnections(poolDataSourceHikari));
        logger.debug("{}idle: {}", prefix, getIdleConnections(poolDataSourceHikari));
    }

    @SuppressWarnings("deprecation")
    @Override
    public Connection getConnection(String username, String password) throws SQLException {
        return super.getConnection(username, password);
    }

    public void close() {
        if (done()) {
            commonPoolDataSourceHikari.close();
            commonPoolDataSourceHikari = null;
        }
    }

    /**
     * Get a connection in a smart way for proxy sessions.
     *
     * Retrieve a connection from the pool until one of the following conditions occurs:
     * 1. there is a last connection and the operation timed out (not(now &lt; doNotConnectAfter))
     * 2. there is a last connection and there are no more idle connections
     * 3. the last connection retrieved has the same current schema as the requested schema
     *
     * In situation 1 or 2 the best other candidate is chosen. Best in terms of current schema equal
     * to the username and not another proxy schema.
     *
     */
    protected Connection getConnectionSmart(final String username,
                                            final String password,
                                            final String schema,
                                            final String proxyUsername,
                                            final boolean updateStatistics,
                                            final boolean showStatistics) throws SQLException {
        try {
            logger.debug(">getConnectionSmart(username={}, schema={}, proxyUsername={}, updateStatistics={}, showStatistics={})",
                         username,
                         schema,
                         proxyUsername,
                         updateStatistics,
                         showStatistics);
        
            assert(schema != null);

            final Instant t1 = Instant.now();
            final Instant doNotConnectAfter = t1.plusMillis(getConnectionTimeout());
            ProxyConnection connOK = (ProxyConnection) commonPoolDataSourceHikari.getConnection();
            OracleConnection oraConnOK = connOK.unwrap(OracleConnection.class);
            int costOK = determineCost(connOK, oraConnOK, schema);
            int logicalConnectionCountProxy = 0, openProxySessionCount = 0, closeProxySessionCount = 0;        
            final Instant t2 = Instant.now();

            if (costOK != 0) {
                // =============================================================================================
                // The first connection above is there because then:
                // - we can measure the time elapsed for the first part of the proxy connection.
                // - we need not define the variables (especiall ArrayList) below and thus save some CPU cycles.
                // =============================================================================================
                ProxyConnection conn = connOK;
                OracleConnection oraConn = oraConnOK;
                int cost = costOK;
                int nrGetConnectionsLeft = getCurrentPoolCount();
            
                assert(nrGetConnectionsLeft > 0); // at least this instance needs to be part of it
            
                final ArrayList<ProxyConnection> connectionsNotOK = new ArrayList<>(nrGetConnectionsLeft);

                try {
                    /**/                                                 // reasons to stop searching:
                    while (costOK != 0 &&                                // 1 - cost 0 is optimal
                           nrGetConnectionsLeft-- > 0 &&                 // 2 - we try just a few times
                           getIdleConnections() > 0 &&                   // 3 - when there no idle connections we stop as well, otherwise it may take too much time
                           Instant.now().isBefore(doNotConnectAfter)) {  // 4 - the accumulated elapsed time is more than we agreed upon for 1 logical connection
                        conn = (ProxyConnection) commonPoolDataSourceHikari.getConnection();
                        oraConn = conn.unwrap(OracleConnection.class);
                        cost = determineCost(conn, oraConn, schema);

                        if (cost < costOK) {
                            // fount a lower cost: switch places
                            connectionsNotOK.add(connOK);
                            connOK = conn;
                            oraConnOK = oraConn;
                            costOK = cost;
                        } else {
                            connectionsNotOK.add(conn);
                        }
                    }

                    assert(connOK != null);

                    // connOK should not be in the list
                    assert(!connectionsNotOK.remove(connOK));

                    logicalConnectionCountProxy = connectionsNotOK.size();

                    logger.debug("tried {} connections before finding one that meets the criteria",
                                 logicalConnectionCountProxy);
                } finally {
                    // (soft) close all connections that are not optimal
                    connectionsNotOK.stream().forEach(c -> {
                            try {
                                c.close();
                            } catch (SQLException ex) {
                                ; // ignore
                            }
                        });
                }
            }

            if (costOK == 0) {
                logger.debug("no need to close/open a proxy session since the current schema is the requested schema");
            } else {
                if (costOK == 2) {
                    logger.debug("closing proxy session since the current schema is not the requested schema");
                
                    logger.debug("current schema before = {}", oraConnOK.getCurrentSchema());

                    oraConnOK.close(OracleConnection.PROXY_SESSION);
                    closeProxySessionCount++;
                }        

                // set up proxy session
                Properties proxyProperties = new Properties();
            
                proxyProperties.setProperty(OracleConnection.PROXY_USER_NAME, schema);

                logger.debug("opening proxy session");

                oraConnOK.openProxySession(OracleConnection.PROXYTYPE_USER_NAME, proxyProperties);
                connOK.setSchema(schema);
                openProxySessionCount++;

                logger.debug("current schema after = {}", oraConnOK.getCurrentSchema());
            }

            if (updateStatistics) {
                updateStatistics(connOK,
                                 Duration.between(t1, t2).toMillis(),
                                 Duration.between(t2, Instant.now()).toMillis(),
                                 showStatistics,
                                 logicalConnectionCountProxy,
                                 openProxySessionCount,
                                 closeProxySessionCount);
            }

            logger.debug("<getConnectionSmart() = {}", connOK);

            return connOK;
        } catch (SQLException ex) {
            signalSQLException(ex);
            throw ex;
        }
    }

    private int determineCost(final Connection conn, final OracleConnection oraConn, final String schema) throws SQLException {
        final String currentSchema = conn.getSchema();        
        int cost;
            
        if (schema != null && currentSchema != null && schema.equalsIgnoreCase(currentSchema)) {
            cost = 0;
        } else {
            // if not a proxy session only oraConn.openProxySession() must be invoked
            // otherwise oraConn.close(OracleConnection.PROXY_SESSION) must be invoked as well
            // hence more expensive.
            cost = (!oraConn.isProxySession() ? 1 : 2);
        }

        logger.debug("determineCost(currentSchema={}, isProxySession={}, schema={}) = {}",
                     currentSchema,
                     oraConn.isProxySession(),
                     schema,
                     cost);
        
        return cost;
    }    

    protected void setCommonPoolDataSource(final DataSource commonPoolDataSource) {
        commonPoolDataSourceHikari = (HikariDataSource) commonPoolDataSource;
    }

    protected String getPoolNamePrefix() {
        return "HikariPool";
    }

    protected String getPoolName(DataSource pds) {
        return ((HikariDataSource)pds).getPoolName();
    }

    protected void setPoolName(DataSource pds, String poolName) throws SQLException {
        ((HikariDataSource)pds).setPoolName(poolName);
    }

    // HikariCP does NOT know of an initial pool size
    protected int getInitialPoolSize() {
        return getInitialPoolSize(commonPoolDataSourceHikari);
    }

    protected int getInitialPoolSize(DataSource pds) {
        final int result = -1;
        
        logger.trace("getInitialPoolSize({}) = {}", getPoolName(pds), result);
        
        return result;
    }

    protected void setInitialPoolSize(int initialPoolSize) {
        setInitialPoolSize(commonPoolDataSourceHikari, initialPoolSize);
    }        

    private void setInitialPoolSize(DataSource pds, int initialPoolSize) {
        logger.trace("setInitialPoolSize({}, {})", getPoolName(pds), initialPoolSize);
    }        

    // HikariCP does NOT know of a minimum pool size
    protected int getMinimumPoolSize() {
        return getMinimumPoolSize(commonPoolDataSourceHikari);
    }

    protected int getMinimumPoolSize(DataSource pds) {
        final int result = -1;
        
        logger.trace("getMinimumPoolSize({}) = {}", getPoolName(pds), result);
        
        return result;
    }

    protected void setMinimumPoolSize(int minimumPoolSize) {
        setMinimumPoolSize(commonPoolDataSourceHikari, minimumPoolSize);
    }        

    private void setMinimumPoolSize(DataSource pds, int minimumPoolSize) {
        logger.trace("setMinimumPoolSize({}, {})", getPoolName(pds), minimumPoolSize);
    }        

    // HikariCP does know of a maximum pool size but it is overriden anyway
    public int getMaximumPoolSize() {
        return getMaximumPoolSize(commonPoolDataSourceHikari);
    }

    protected int getMaximumPoolSize(DataSource pds) {
        final int result = ((HikariDataSource)pds).getMaximumPoolSize();
        
        logger.trace("getMaximumPoolSize({}) = {}", getPoolName(pds), result);
        
        return result;
    }

    public void setMaximumPoolSize(int maximumPoolSize) {
        setMaximumPoolSize(commonPoolDataSourceHikari, maximumPoolSize);
    }        

    private void setMaximumPoolSize(DataSource pds, int maximumPoolSize) {
        logger.trace("setMaximumPoolSize({}, {})", getPoolName(pds), maximumPoolSize);
        ((HikariDataSource)pds).setMaximumPoolSize(maximumPoolSize);
    }        

    // https://stackoverflow.com/questions/40784965/how-to-get-the-number-of-active-connections-for-hikaricp
    private static HikariPool getHikariPool(final HikariDataSource poolDataSource) {
        return (HikariPool) new DirectFieldAccessor(poolDataSource).getPropertyValue("pool");
    }

    protected int getActiveConnections() {
        return getActiveConnections(commonPoolDataSourceHikari);
    }

    private static int getActiveConnections(final HikariDataSource poolDataSource) {
        final HikariPool hikariPool = getHikariPool(poolDataSource);
        
        return hikariPool != null ? hikariPool.getActiveConnections() : -1;
    }

    protected int getIdleConnections() {
        return getIdleConnections(commonPoolDataSourceHikari);
    }

    private static int getIdleConnections(final HikariDataSource poolDataSource) {
        final HikariPool hikariPool = getHikariPool(poolDataSource);
        
        return hikariPool != null ? hikariPool.getIdleConnections() : -1;
    }

    protected int getTotalConnections() {
        return getTotalConnections(commonPoolDataSourceHikari);
    }

    private static int getTotalConnections(final HikariDataSource poolDataSource) {
        final HikariPool hikariPool = getHikariPool(poolDataSource);
        
        return hikariPool != null ? hikariPool.getTotalConnections() : -1;
    }
}
