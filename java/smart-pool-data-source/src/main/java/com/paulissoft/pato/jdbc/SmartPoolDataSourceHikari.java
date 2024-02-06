package com.paulissoft.pato.jdbc;

import org.springframework.beans.DirectFieldAccessor;    
import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.pool.HikariPool;
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

        logger.debug("commonPoolDataSourceHikari: {}", commonPoolDataSourceHikari);

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
        
        logger.debug("configuration pool data source {}:", poolDataSourceHikari.getPoolName());
        logger.debug("- driverClassName: {}", poolDataSourceHikari.getDriverClassName());
        logger.debug("- dataSourceClassName: {}", poolDataSourceHikari.getDataSourceClassName());
        logger.debug("- jdbcUrl: {}", poolDataSourceHikari.getJdbcUrl());
        logger.debug("- username: {}", poolDataSourceHikari.getUsername());
        logger.debug("- autoCommit: {}", poolDataSourceHikari.isAutoCommit());
        logger.debug("- connectionTimeout: {}", poolDataSourceHikari.getConnectionTimeout());
        logger.debug("- idleTimeout: {}", poolDataSourceHikari.getIdleTimeout());
        logger.debug("- maxLifetime: {}", poolDataSourceHikari.getMaxLifetime());
        logger.debug("- connectionTestQuery: {}", poolDataSourceHikari.getConnectionTestQuery());
        logger.debug("- minimumIdle: {}", poolDataSourceHikari.getMinimumIdle());
        logger.debug("- maximumPoolSize: {}", poolDataSourceHikari.getMaximumPoolSize());
        logger.debug("- metricRegistry: {}", poolDataSourceHikari.getMetricRegistry());
        logger.debug("- healthCheckRegistry: {}", poolDataSourceHikari.getHealthCheckRegistry());
        logger.debug("- initializationFailTimeout: {}", poolDataSourceHikari.getInitializationFailTimeout());
        logger.debug("- isolateInternalQueries: {}", poolDataSourceHikari.isIsolateInternalQueries());
        logger.debug("- allowPoolSuspension: {}", poolDataSourceHikari.isAllowPoolSuspension());
        logger.debug("- readOnly: {}", poolDataSourceHikari.isReadOnly());
        logger.debug("- registerMbeans: {}", poolDataSourceHikari.isRegisterMbeans());
        logger.debug("- catalog: {}", poolDataSourceHikari.getCatalog());
        logger.debug("- connectionInitSql: {}", poolDataSourceHikari.getConnectionInitSql());
        logger.debug("- driverClassName: {}", poolDataSourceHikari.getDriverClassName());
        logger.debug("- dataSourceClassName: {}", poolDataSourceHikari.getDataSourceClassName());
        logger.debug("- transactionIsolation: {}", poolDataSourceHikari.getTransactionIsolation());
        logger.debug("- validationTimeout: {}", poolDataSourceHikari.getValidationTimeout());
        logger.debug("- leakDetectionThreshold: {}", poolDataSourceHikari.getLeakDetectionThreshold());
        logger.debug("- dataSource: {}", poolDataSourceHikari.getDataSource());
        logger.debug("- schema: {}", poolDataSourceHikari.getSchema());
        logger.debug("- threadFactory: {}", poolDataSourceHikari.getThreadFactory());
        logger.debug("- scheduledExecutor: {}", poolDataSourceHikari.getScheduledExecutor());

        if (poolDataSourceHikari == commonPoolDataSourceHikari) {
            logger.debug("connections pool data source {}:", getPoolName());
            logger.debug("- total={}", getTotalConnections());
            logger.debug("- active={}", getActiveConnections());
            logger.debug("- idle={}", getIdleConnections());
        }
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
                                            final String proxyUsername) throws SQLException {
        assert(schema != null);

        Instant t1 = Instant.now();
        final Instant doNotConnectAfter = t1.plusMillis(getConnectionTimeout());
        final ArrayList<ProxyConnection> nonMatchingConnections = new ArrayList<>(10);
        ProxyConnection conn = null;
        ProxyConnection nonMatchingConnection = null;
        OracleConnection oraConn = null;
        boolean found = false;
        final Integer closeConnectionCount = Integer.valueOf(0);
        int openProxySessionCount = 0, closeProxySessionCount = 0;
        int nr = 0;

        try {
            while (!found) {
                logger.trace("try: {}", ++nr);
                
                // when there are no idle connections: pick the non matching connection
                final boolean mustMatchSessionSchema = getIdleConnections() > 0;

                if (nonMatchingConnection != null && (!mustMatchSessionSchema || !Instant.now().isBefore(doNotConnectAfter))) {
                    // no idle connections or operation timed out: pick nonMatchingConnection
                    conn = nonMatchingConnection;
                    assert(nonMatchingConnections.remove(nonMatchingConnection));
                    found = true;
                } else {
                    final Instant t2 = Instant.now();
                    conn = (ProxyConnection) commonPoolDataSourceHikari.getConnection();
                    if (isStatisticsEnabled()) {
                        updateStatistics(conn, Duration.between(t1, t2).toMillis(), false);
                    }
                    t1 = t2;
                }
            
                oraConn = conn.unwrap(OracleConnection.class);

                if (found) {
                    // pick the non matching connection
                    ;
                } else if (mustMatchSessionSchema && oraConn.isProxySession() && !oraConn.getCurrentSchema().equals(schema)) {
                    // add the connection with the non matching Oracle session so we can close it later
                    nonMatchingConnections.add(conn);
                
                    if (nonMatchingConnection == null) {
                        nonMatchingConnection = conn; // last resort
                    }
                } else {
                    found = true;
                }

                if (found) {                
                    logger.debug("found this connection after {} time(s) with current schema {} (mustMatchSessionSchema={})",
                                 nr,
                                 oraConn.getCurrentSchema(),
                                 mustMatchSessionSchema);
        
                    final String currentSchema = oraConn.getCurrentSchema();
        
                    logger.debug("current schema before = {}; oracle connection = {}", currentSchema, oraConn);

                    // MyProxySession.setProxy(oraConn, schema);
                    if (oraConn.isProxySession()) {
                        if (currentSchema.equals(schema)) {
                            logger.debug("no need to close/open a proxy session since the current schema is the requested schema");
                
                            oraConn = null; // we are done
                        } else {
                            logger.debug("closing proxy session since the current schema is not the requested schema");
                
                            oraConn.close(OracleConnection.PROXY_SESSION);
                            closeProxySessionCount++;
                        }
                    }            

                    if (oraConn != null) { // set up proxy session
                        Properties proxyProperties = new Properties();
            
                        proxyProperties.setProperty(OracleConnection.PROXY_USER_NAME, schema);
                        proxyProperties.setProperty(OracleConnection.CONNECTION_PROPERTY_PROXY_CLIENT_NAME, schema);

                        logger.debug("opening proxy session");

                        oraConn.openProxySession(OracleConnection.PROXYTYPE_USER_NAME, proxyProperties);
                        conn.setSchema(schema);
                        openProxySessionCount++;

                        logger.debug("current schema after = {}", oraConn.getCurrentSchema());
                    }
                }
            }

            logger.debug("tried {} connections before finding one that meets the criteria", nonMatchingConnections.size());
        } finally {
            // (soft) close all connections that do not meet the criteria
            nonMatchingConnections.stream().forEach(c -> {
                    try {
                        c.close();
                    } catch (SQLException ex) {
                        ; // ignore
                    } finally {
                        closeConnectionCount.sum(closeConnectionCount.intValue(), 1);
                    }
                });
        }

        if (isStatisticsEnabled()) {
            updateStatistics(closeConnectionCount.intValue(),
                             openProxySessionCount,
                             closeProxySessionCount,
                             Duration.between(t1, Instant.now()).toMillis());
        }

        return conn;
    }

    /*
    protected Connection getConnectionSmart(final String username,
                                            final String password,
                                            final String schema,
                                            final String proxyUsername) throws SQLException {
        Instant t1 = Instant.now();
        final ArrayList<ProxyConnection> connectionsToSkip = new ArrayList<>(100);
        ProxyConnection conn = null;
        OracleConnection oraConn = null;
        String currentSchema = null;
        final Instant doNotConnectAfter = t1.plusMillis(getConnectionTimeout());
        final Integer closeConnectionCount = Integer.valueOf(0);
        int openProxySessionCount = 0, closeProxySessionCount = 0;
        int nr = 0;

        try {
            while (true) {
                logger.debug("try: {}", ++nr);

                // only update statistics do not show them here but at the end in the second updateStatistics
                conn = (ProxyConnection) commonPoolDataSourceHikari.getConnection();

                if (isStatisticsEnabled()) {
                    updateStatistics(conn, Duration.between(t1, Instant.now()).toMillis(), false);
                }
            
                oraConn = conn.unwrap(OracleConnection.class);
                currentSchema = oraConn.getCurrentSchema();
        
                logger.debug("current schema before = {}; oracle connection = {}", currentSchema, oraConn);

                logger.debug("oraConn.isProxySession(): {}; currentSchema.equals(schema): {}; getIdleConnections(): {}",
                             oraConn.isProxySession(),
                             currentSchema.equals(schema),
                             getIdleConnections());

                if (!oraConn.isProxySession() ||
                    currentSchema.equals(schema) ||
                    getIdleConnections() == 0 ||
                    !Instant.now().isBefore(doNotConnectAfter)) {
                    logger.debug("found a candidate after {} time(s)", nr);
                    break;
                }

                connectionsToSkip.add(conn);                    

                t1 = Instant.now(); // for the next round
            }

            assert(conn != null && oraConn != null);
                
            if (oraConn.isProxySession()) {
                if (currentSchema.equals(schema)) {
                    logger.debug("no need to close/open a proxy session since the current schema is the requested schema");
                
                    oraConn = null; // we are done
                } else {
                    logger.debug("closing proxy session since the current schema is not the requested schema");
                
                    oraConn.close(OracleConnection.PROXY_SESSION);
                    closeProxySessionCount++;
                }
            }

            if (oraConn != null) { // set up proxy session
                Properties proxyProperties = new Properties();
            
                proxyProperties.setProperty(OracleConnection.PROXY_USER_NAME, schema);

                logger.debug("opening proxy session");

                oraConn.openProxySession(OracleConnection.PROXYTYPE_USER_NAME, proxyProperties);
                conn.setSchema(schema);
                openProxySessionCount++;

                logger.debug("current schema after = {}", oraConn.getCurrentSchema());
            }

        } finally {
            // (soft) close all connections that do not meet the criteria
            connectionsToSkip.stream().forEach(c -> {
                    try {
                        c.close();
                    } catch (SQLException ex) {
                        ; // ignore
                    } finally {
                        closeConnectionCount.sum(closeConnectionCount.intValue(), 1);
                    }
                });
        }
        if (isStatisticsEnabled()) {
            updateStatistics(closeConnectionCount.intValue(),
                             openProxySessionCount,
                             closeProxySessionCount,
                             Duration.between(t1, Instant.now()).toMillis());
        }

        return conn;
    }
    */
    
    protected void setCommonPoolDataSource(final DataSource commonPoolDataSource) {
        commonPoolDataSourceHikari = (HikariDataSource) commonPoolDataSource;
    }

    protected String getPoolNamePrefix() {
        return "HikariPool";
    }

    // HikariCP does NOT know of an initial pool size
    protected int getInitialPoolSize() {
        return -1;
    }

    protected int getInitialPoolSize(DataSource pds) {
        return -1;
    }

    protected void setInitialPoolSize(int initialPoolSize) {
        ;
    }        

    // HikariCP does NOT know of a minimum pool size
    protected int getMinimumPoolSize() {
        return -1;
    }

    protected int getMinimumPoolSize(DataSource pds) {
        return -1;
    }

    protected void setMinimumPoolSize(int minimumPoolSize) {
        ;
    }

    // HikariCP does know of a maximum pool size

    protected int getMaximumPoolSize(DataSource pds) {
        return ((HikariDataSource)pds).getMaximumPoolSize();
    }


    // https://stackoverflow.com/questions/40784965/how-to-get-the-number-of-active-connections-for-hikaricp
    private HikariPool getHikariPool() {
        return (HikariPool) new DirectFieldAccessor(commonPoolDataSourceHikari).getPropertyValue("pool");
        /*
        try {
            return (HikariPool) commonPoolDataSourceHikari.getClass().getDeclaredField("pool").get(commonPoolDataSourceHikari);
        } catch (Exception ex) {
            logger.error("getHikariPool() exception: {}", ex.getMessage());
            return null;
        }
        */
    }

    protected int getActiveConnections() {
        final HikariPool hikariPool = getHikariPool();
        
        return hikariPool != null ? hikariPool.getActiveConnections() : -1;
    }

    protected int getIdleConnections() {
        final HikariPool hikariPool = getHikariPool();
        
        return hikariPool != null ? hikariPool.getIdleConnections() : -1;
    }

    protected int getTotalConnections() {
        final HikariPool hikariPool = getHikariPool();
        
        return hikariPool != null ? hikariPool.getTotalConnections() : -1;
    }
}
