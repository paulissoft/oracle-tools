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

        logger.info("commonPoolDataSourceHikari: {}", commonPoolDataSourceHikari);

        // pool name, sizes and username / password already done in super constructor
        synchronized (commonPoolDataSourceHikari) {
            if (commonPoolDataSourceHikari != pds) {
                logger.info("minimum idle before: {}", getMinimumIdle());

                setMinimumIdle(pds.getMinimumIdle() + getMinimumIdle());

                logger.info("minimum idle after: {}", getMinimumIdle());
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
        final HikariDataSource poolDataSourceHikari = ((HikariDataSource)poolDataSource);
        
        logger.info("configuration pool data source {}:", poolDataSourceHikari.getPoolName());
        logger.info("- driverClassName: {}", poolDataSourceHikari.getDriverClassName());
        logger.info("- dataSourceClassName: {}", poolDataSourceHikari.getDataSourceClassName());
        logger.info("- jdbcUrl: {}", poolDataSourceHikari.getJdbcUrl());
        logger.info("- username: {}", poolDataSourceHikari.getUsername());
        logger.info("- autoCommit: {}", poolDataSourceHikari.isAutoCommit());
        logger.info("- connectionTimeout: {}", poolDataSourceHikari.getConnectionTimeout());
        logger.info("- idleTimeout: {}", poolDataSourceHikari.getIdleTimeout());
        logger.info("- maxLifetime: {}", poolDataSourceHikari.getMaxLifetime());
        logger.info("- connectionTestQuery: {}", poolDataSourceHikari.getConnectionTestQuery());
        logger.info("- minimumIdle: {}", poolDataSourceHikari.getMinimumIdle());
        logger.info("- maximumPoolSize: {}", poolDataSourceHikari.getMaximumPoolSize());
        logger.info("- metricRegistry: {}", poolDataSourceHikari.getMetricRegistry());
        logger.info("- healthCheckRegistry: {}", poolDataSourceHikari.getHealthCheckRegistry());
        logger.info("- initializationFailTimeout: {}", poolDataSourceHikari.getInitializationFailTimeout());
        logger.info("- isolateInternalQueries: {}", poolDataSourceHikari.isIsolateInternalQueries());
        logger.info("- allowPoolSuspension: {}", poolDataSourceHikari.isAllowPoolSuspension());
        logger.info("- readOnly: {}", poolDataSourceHikari.isReadOnly());
        logger.info("- registerMbeans: {}", poolDataSourceHikari.isRegisterMbeans());
        logger.info("- catalog: {}", poolDataSourceHikari.getCatalog());
        logger.info("- connectionInitSql: {}", poolDataSourceHikari.getConnectionInitSql());
        logger.info("- driverClassName: {}", poolDataSourceHikari.getDriverClassName());
        logger.info("- dataSourceClassName: {}", poolDataSourceHikari.getDataSourceClassName());
        logger.info("- transactionIsolation: {}", poolDataSourceHikari.getTransactionIsolation());
        logger.info("- validationTimeout: {}", poolDataSourceHikari.getValidationTimeout());
        logger.info("- leakDetectionThreshold: {}", poolDataSourceHikari.getLeakDetectionThreshold());
        logger.info("- dataSource: {}", poolDataSourceHikari.getDataSource());
        logger.info("- schema: {}", poolDataSourceHikari.getSchema());
        logger.info("- threadFactory: {}", poolDataSourceHikari.getThreadFactory());
        logger.info("- scheduledExecutor: {}", poolDataSourceHikari.getScheduledExecutor());

        if (poolDataSourceHikari == commonPoolDataSourceHikari) {
            logger.info("connections pool data source {}:", getPoolName());
            logger.info("- total={}", getTotalConnections());
            logger.info("- active={}", getActiveConnections());
            logger.info("- idle={}", getIdleConnections());
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
    
    protected void setCommonPoolDataSource(final DataSource commonPoolDataSource) {
        logger.info("setCommonPoolDataSource({})", commonPoolDataSource);

        assert(commonPoolDataSource != null);
        
        commonPoolDataSourceHikari = (HikariDataSource) commonPoolDataSource;

        assert(commonPoolDataSourceHikari != null);
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
