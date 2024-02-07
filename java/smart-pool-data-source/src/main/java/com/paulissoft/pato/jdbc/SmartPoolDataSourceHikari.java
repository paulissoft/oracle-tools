package com.paulissoft.pato.jdbc;

import org.springframework.beans.DirectFieldAccessor;    
import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.pool.HikariPool;
//import com.zaxxer.hikari.pool.ProxyConnection;
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

        logger.debug("connections pool data source {}:", poolDataSourceHikari.getPoolName());
        logger.debug("- total={}", getTotalConnections(poolDataSourceHikari));
        logger.debug("- active={}", getActiveConnections(poolDataSourceHikari));
        logger.debug("- idle={}", getIdleConnections(poolDataSourceHikari));
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
        final Instant t1 = Instant.now();
        assert(schema != null);

        final Instant doNotConnectAfter = Instant.now().plusMillis(getConnectionTimeout());
        int closeConnectionCount = 0, openProxySessionCount = 0, closeProxySessionCount = 0;
        
        Connection conn = getConnectionSimple(username,
                                              password,
                                              schema,
                                              proxyUsername,
                                              updateStatistics,
                                              false); // show at the end if showStatistics is true
        OracleConnection oraConn = conn.unwrap(OracleConnection.class);
        Connection found = null;

        int cost = determineCost(conn, oraConn, schema);

        if (cost == 0) {
            // we are done
            found = conn;
        } else {
            int nrGetConnectionsLeft = getCurrentPoolCount();
            
            assert(nrGetConnectionsLeft > 0); // at least this instance
            
            final ArrayList</*Proxy*/Connection> nonMatchingConnections = new ArrayList<>(nrGetConnectionsLeft);

            try {
                while (true) {
                    assert(cost != 0);

                    nonMatchingConnections.add(conn);
                
                    if (cost == 1 || found == null) {
                        found = conn;
                    }

                    if (!(nrGetConnectionsLeft-- > 0 && getIdleConnections() > 0 && Instant.now().isBefore(doNotConnectAfter))) {
                        break;
                    }

                    conn = getConnectionSimple(username,
                                               password,
                                               schema,
                                               proxyUsername,
                                               false,
                                               false);
                    oraConn = conn.unwrap(OracleConnection.class);
                    cost = determineCost(conn, oraConn, schema);

                    if (cost == 0) {
                        found = conn;
                        break;
                    }
                }

                assert(found != null);                

                if (cost != 0) {
                    assert(nonMatchingConnections.remove(found));
                }

                closeConnectionCount = nonMatchingConnections.size();

                logger.debug("tried {} connections before finding one that meets the criteria", closeConnectionCount);
            } finally {
                // (soft) close all connections that do not meet the criteria
                nonMatchingConnections.stream().forEach(c -> {
                        try {
                            c.close();
                        } catch (SQLException ex) {
                            ; // ignore
                        }
                    });
            }
        }

        if (cost == 0) {
            logger.debug("no need to close/open a proxy session since the current schema is the requested schema");
        } else {
            if (cost == 2) {
                logger.debug("closing proxy session since the current schema is not the requested schema");
                
                logger.debug("current schema before = {}", oraConn.getCurrentSchema());

                oraConn.close(OracleConnection.PROXY_SESSION);
                closeProxySessionCount++;
            }        

            // set up proxy session
            Properties proxyProperties = new Properties();
            
            proxyProperties.setProperty(OracleConnection.PROXY_USER_NAME, schema);

            logger.debug("opening proxy session");

            oraConn.openProxySession(OracleConnection.PROXYTYPE_USER_NAME, proxyProperties);
            conn.setSchema(schema);
            openProxySessionCount++;

            logger.debug("current schema after = {}", oraConn.getCurrentSchema());
        }

        if (isStatisticsEnabled()) {
            updateStatistics(closeConnectionCount,
                             openProxySessionCount,
                             closeProxySessionCount,
                             Duration.between(t1, Instant.now()).toMillis());
        }

        return conn;
    }

    private int determineCost(final Connection conn, final OracleConnection oraConn, final String schema) throws SQLException {
        final String currentSchema = conn.getSchema();
        int cost;
            
        if (schema != null && currentSchema != null && schema.equals(currentSchema)) {
            cost = 0;
        } else {
            // if not a proxy session only oraConn.openProxySession() must be invoked
            // otherwise oraConn.close(OracleConnection.PROXY_SESSION) must be invoked as well
            // hence more expensive.
            cost = (!oraConn.isProxySession() ? 1 : 2);
        }
        return cost;
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
