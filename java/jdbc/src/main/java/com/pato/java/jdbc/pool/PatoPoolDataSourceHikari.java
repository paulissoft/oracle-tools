package com.pato.java.jdbc.pool;

import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.pool.HikariPool;
import java.io.Closeable;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;
import lombok.experimental.Delegate;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PatoPoolDataSourceHikari extends PatoPoolDataSource implements HikariConfigMXBean, Closeable {

    private static final Logger logger = LoggerFactory.getLogger(PatoPoolDataSourceHikari.class);

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
        logger.info("Initializing {}", PatoPoolDataSourceHikari.class.toString());
    }

    private interface Overrides {
        public void close();

        public Connection getConnection() throws SQLException;

        /*
        // To solve this error:
        //
        // getDataSourceProperties() in nl.bluecurrent.backoffice.configuration.PatoPoolDataSourceHikari cannot override
        // getDataSourceProperties() in nl.bluecurrent.backoffice.configuration.PatoPoolDataSource
        // return type java.util.Properties is not compatible with org.springframework.boot.autoconfigure.jdbc.DataSourceProperties
        */
        public Properties getDataSourceProperties();
    }
    
    @Delegate(excludes=Overrides.class)
    private HikariDataSource commonPoolDataSourceHikari = null;

    public PatoPoolDataSourceHikari(final HikariDataSource pds,
                                    final String username,
                                    final String password) {
        super(pds, determineCommonDataSourceProperties(pds), username, password);
        
        commonPoolDataSourceHikari = (HikariDataSource) commonPoolDataSource;

        // Since it is a static pool one must use the proxy user name to connect in case
        // of proxy sessions.
        setSingleSessionProxyModel(false); 

        // update pool sizes and default username / password when the pool data source is added to an existing
        synchronized (commonPoolDataSourceHikari) {
            if (commonPoolDataSourceHikari == pds) {
                setPoolName("HikariPool"); // set the prefix the first time
            } else {
                // set username/password BEFORE changing pool attributes
                setUsername(this.username);
                setPassword(this.password);
                
                logger.info("maximum pool size before: {}", getMaximumPoolSize());
                logger.info("minimum idl before: {}", getMinimumIdle());

                setMaximumPoolSize(pds.getMaximumPoolSize() + getMaximumPoolSize());
                // no min nor initial just minimumIdle
                setMinimumIdle(pds.getMinimumIdle() + getMinimumIdle());

                logger.info("maximum pool size after: {}", getMaximumPoolSize());
                logger.info("minimum idl after: {}", getMinimumIdle());
            }
            setPoolName(getPoolName() + "-" + schema);
            logger.info("Common pool name: {}", getPoolName());
        }
    }

    private static Properties determineCommonDataSourceProperties(final HikariDataSource pds) {
        final Properties commonDataSourceProperties = new Properties();

        PatoPoolDataSource.setProperty(commonDataSourceProperties, PatoPoolDataSource.CLASS, pds.getClass().getName());
        PatoPoolDataSource.setProperty(commonDataSourceProperties, PatoPoolDataSource.URL, pds.getJdbcUrl());
        // by first setting getDriverClassName(), getDataSourceClassName() will overwrite that one
        PatoPoolDataSource.setProperty(commonDataSourceProperties, PatoPoolDataSource.CONNECTION_FACTORY_CLASS_NAME, pds.getDriverClassName());
        PatoPoolDataSource.setProperty(commonDataSourceProperties, PatoPoolDataSource.CONNECTION_FACTORY_CLASS_NAME, pds.getDataSourceClassName());
        PatoPoolDataSource.setProperty(commonDataSourceProperties, AUTO_COMMIT, pds.isAutoCommit());
        PatoPoolDataSource.setProperty(commonDataSourceProperties, CONNECTION_TIMEOUT, pds.getConnectionTimeout());
        PatoPoolDataSource.setProperty(commonDataSourceProperties, IDLE_TIMEOUT, pds.getIdleTimeout());
        PatoPoolDataSource.setProperty(commonDataSourceProperties, MAX_LIFETIME, pds.getMaxLifetime());
        PatoPoolDataSource.setProperty(commonDataSourceProperties, CONNECTION_TEST_QUERY, pds.getConnectionTestQuery());
        PatoPoolDataSource.setProperty(commonDataSourceProperties, INITIALIZATION_FAIL_TIMEOUT, pds.getInitializationFailTimeout());
        PatoPoolDataSource.setProperty(commonDataSourceProperties, ISOLATE_INTERNAL_QUERIES, pds.isIsolateInternalQueries());
        PatoPoolDataSource.setProperty(commonDataSourceProperties, ALLOW_POOL_SUSPENSION, pds.isAllowPoolSuspension());
        PatoPoolDataSource.setProperty(commonDataSourceProperties, READ_ONLY, pds.isReadOnly());
        PatoPoolDataSource.setProperty(commonDataSourceProperties, REGISTER_MBEANS, pds.isRegisterMbeans());
        PatoPoolDataSource.setProperty(commonDataSourceProperties, VALIDATION_TIMEOUT, pds.getValidationTimeout());
        PatoPoolDataSource.setProperty(commonDataSourceProperties, LEAK_DETECTION_THRESHOLD, pds.getLeakDetectionThreshold());

        return commonDataSourceProperties;
    }

    /*
     * NOTE 1.
     *
     * HikariCP does not support getConnection(String username, String password).
     * See https://github.com/brettwooldridge/HikariCP/issues/231
     *
     * But you can set the default username/password using setUsername()/setPassword().
     */

    @Override
    protected Connection getConnectionSimple(String username, String password) throws SQLException {
        commonPoolDataSourceHikari.setUsername(username);
        commonPoolDataSourceHikari.setPassword(password);

        return commonPoolDataSourceHikari.getConnection();
    }
    

    @Override
    protected void printDataSourceStatistics(final MyDataSourceStatistics myDataSourceStatistics, final Logger logger) {
        super.printDataSourceStatistics(myDataSourceStatistics, logger);
        // Only show the first time a pool has gotten a connection.
        // Not earlier because these (fixed) values may change before and after the first connection.
        if (myDataSourceStatistics.getCount() == 1) {
            logger.info("autoCommit: {}", isAutoCommit());
            logger.info("connectionTimeout: {}", getConnectionTimeout());
            logger.info("idleTimeout: {}", getIdleTimeout());
            logger.info("maxLifetime: {}", getMaxLifetime());
            logger.info("connectionTestQuery: {}", getConnectionTestQuery());
            logger.info("minimumIdle: {}", getMinimumIdle());
            logger.info("maximumPoolSize: {}", getMaximumPoolSize());
            logger.info("metricRegistry: {}", getMetricRegistry());
            logger.info("healthCheckRegistry: {}", getHealthCheckRegistry());
            logger.info("initializationFailTimeout: {}", getInitializationFailTimeout());
            logger.info("isolateInternalQueries: {}", isIsolateInternalQueries());
            logger.info("allowPoolSuspension: {}", isAllowPoolSuspension());
            logger.info("readOnly: {}", isReadOnly());
            logger.info("registerMbeans: {}", isRegisterMbeans());
            logger.info("catalog: {}", getCatalog());
            logger.info("connectionInitSql: {}", getConnectionInitSql());
            logger.info("driverClassName: {}", getDriverClassName());
            logger.info("dataSourceClassName: {}", getDataSourceClassName());
            logger.info("transactionIsolation: {}", getTransactionIsolation());
            logger.info("validationTimeout: {}", getValidationTimeout());
            logger.info("leakDetectionThreshold: {}", getLeakDetectionThreshold());
            logger.info("dataSource: {}", getDataSource());
            logger.info("schema: {}", getSchema());
            logger.info("threadFactory: {}", getThreadFactory());
            logger.info("scheduledExecutor: {}", getScheduledExecutor());
        }
    }

    public void close() {
        if (done()) {
            commonPoolDataSourceHikari.close();
            commonPoolDataSourceHikari = null;
        }
    }

    // https://stackoverflow.com/questions/40784965/how-to-get-the-number-of-active-connections-for-hikaricp
    private HikariPool getHikariPool() {
        try {
            return (HikariPool) commonPoolDataSourceHikari.getClass().getDeclaredField("pool").get(commonPoolDataSourceHikari);
        } catch (Exception ex) {
            logger.error("getHikariPool() exception: {}", ex.getMessage());
            return null;
        }
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

    protected int getThreadsAwaitingConnection() {
        final HikariPool hikariPool = getHikariPool();
        
        return hikariPool != null ? hikariPool.getThreadsAwaitingConnection() : -1;
    }

    protected int getInitialPoolSize() {
        return getMaximumPoolSize(); // HikariCP does not know of an initial pool size
    }

    protected int getMinimumPoolSize() {
        return getMaximumPoolSize(); // HikariCP does not know of a minimum pool size
    }
}
