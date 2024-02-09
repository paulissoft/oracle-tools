package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.pool.HikariPool;
import java.io.Closeable;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import java.util.Properties;
import javax.sql.DataSource;
import lombok.experimental.Delegate;
import org.springframework.beans.DirectFieldAccessor;    

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
         *
         * See also https://github.com/brettwooldridge/HikariCP/issues/231
         */

        this(pds, username, password, false, true);
    }
    
    private SmartPoolDataSourceHikari(final HikariDataSource pds,
                                      final String username,
                                      final String password,
                                      final boolean singleSessionProxyModel,
                                      final boolean useFixedUsernamePassword) throws SQLException {
        
        /*
         * NOTE 2.
         *
         * The combination of singleSessionProxyModel true and useFixedUsernamePassword false does not work.
         * So when singleSessionProxyModel is true, useFixedUsernamePassword must be true as well.
         */
        super(pds,
              determineCommonDataSourceProperties(pds),
              username,
              password,
              singleSessionProxyModel,
              singleSessionProxyModel || useFixedUsernamePassword);

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

    @Override
    protected Connection getConnectionSimple(final String username,
                                             final String password,
                                             final String schema,
                                             final String proxyUsername,
                                             final boolean updateStatistics,
                                             final boolean showStatistics) throws SQLException {
        logger.debug(">getConnectionSimple(username={}, schema={}, proxyUsername={}, updateStatistics={}, showStatistics={})",
                     username,
                     schema,
                     proxyUsername,
                     updateStatistics,
                     showStatistics);

        try {    
            final Instant t1 = Instant.now();
            Connection conn;
            
            conn = commonPoolDataSourceHikari.getConnection();

            showConnection(conn);

            logger.debug("current schema: {}; schema: {}", conn.getSchema(), schema);
            
            assert(conn.getSchema().equalsIgnoreCase(schema));

            if (updateStatistics) {
                updateStatistics(conn, Duration.between(t1, Instant.now()).toMillis(), showStatistics);
            }

            logger.debug("<getConnectionSimple() = {}", conn);
        
            return conn;
        } catch (SQLException ex) {
            signalSQLException(ex);
            logger.debug("<getConnectionSimple()");
            throw ex;
        }        
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
