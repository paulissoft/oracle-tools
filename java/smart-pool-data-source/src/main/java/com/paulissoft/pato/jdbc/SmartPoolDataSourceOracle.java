package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;
import lombok.experimental.Delegate;
import oracle.ucp.jdbc.PoolDataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class SmartPoolDataSourceOracle extends SmartPoolDataSource implements PoolDataSource {
    // static stuff

    public static final String VALIDATE_CONNECTION_ON_BORROW = "validateConnectionOnBorrow";
    
    public static final String ABANDONED_CONNECTION_TIMEOUT = "abandonedConnectionTimeout";
    
    public static final String TIME_TO_LIVE_CONNECTION_TIMEOUT = "timeToLiveConnectionTimeout";
    
    public static final String INACTIVE_CONNECTION_TIMEOUT = "inactiveConnectionTimeout";
    
    public static final String TIMEOUT_CHECK_INTERVAL = "timeoutCheckInterval";
    
    public static final String MAX_STATEMENTS = "maxStatements";
    
    public static final String CONNECTION_WAIT_TIMEOUT = "connectionWaitTimeout";
    
    public static final String MAX_CONNECTION_REUSE_TIME = "maxConnectionReuseTime";
    
    public static final String SECONDS_TO_TRUST_IDLE_CONNECTION = "secondsToTrustIdleConnection";
    
    public static final String CONNECTION_VALIDATION_TIMEOUT = "connectionValidationTimeout";

    private static final Logger logger = LoggerFactory.getLogger(SmartPoolDataSourceOracle.class);

    static {
        logger.info("Initializing {}", SmartPoolDataSourceOracle.class.toString());
    }

    private interface Overrides {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;
    }

    @Delegate(excludes=Overrides.class)
    private PoolDataSource commonPoolDataSourceOracle;
    
    public SmartPoolDataSourceOracle(final PoolDataSource pds,
                                    final String username,
                                    final String password) {
        super(pds, determineCommonDataSourceProperties(pds), username, password);
        
        commonPoolDataSourceOracle = (PoolDataSource) getCommonPoolDataSource();

        setSingleSessionProxyModel(false);
        
        synchronized (SmartPoolDataSource.class) {
            try {
                // update pool sizes and default username / password when the pool data source is added to an existing
                if (commonPoolDataSourceOracle.equals(pds)) {
                    setConnectionPoolName("OraclePool"); // the prefix
                } else {
                    // Set new username/password combination of common data source before
                    // you augment pool size(s) since that will trigger getConnection() calls.
                    setUser(username);
                    setPassword(password);
                    
                    logger.info("initial pool size before: {}", getInitialPoolSize());
                    logger.info("max pool size before: {}", getMaxPoolSize());
                    logger.info("min pool size before: {}", getMinPoolSize());
                    
                    setMaxPoolSize(pds.getMaxPoolSize() + getMaxPoolSize());
                    setMinPoolSize(pds.getMinPoolSize() + getMinPoolSize());
                    setInitialPoolSize(pds.getInitialPoolSize() + getInitialPoolSize());
                    
                    logger.info("initial pool size after: {}", getInitialPoolSize());
                    logger.info("max pool size after: {}", getMaxPoolSize());
                    logger.info("min pool size after: {}", getMinPoolSize());
                }
                setConnectionPoolName(getConnectionPoolName() + "-" + getSchema());
                logger.info("Common pool name: {}", getConnectionPoolName());
            } catch (SQLException ex) {
                throw new RuntimeException(ex.getMessage());
            }
        }
    }

    private static Properties determineCommonDataSourceProperties(final PoolDataSource pds) {
        final Properties commonDataSourceProperties = new Properties();
        
        SmartPoolDataSource.setProperty(commonDataSourceProperties, SmartPoolDataSource.CLASS, pds.getClass().getName());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, SmartPoolDataSource.URL, pds.getURL());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, SmartPoolDataSource.CONNECTION_FACTORY_CLASS_NAME, pds.getConnectionFactoryClassName());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, VALIDATE_CONNECTION_ON_BORROW, pds.getValidateConnectionOnBorrow());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, ABANDONED_CONNECTION_TIMEOUT, pds.getAbandonedConnectionTimeout());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, TIME_TO_LIVE_CONNECTION_TIMEOUT, pds.getTimeToLiveConnectionTimeout());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, INACTIVE_CONNECTION_TIMEOUT, pds.getInactiveConnectionTimeout());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, TIMEOUT_CHECK_INTERVAL, pds.getTimeoutCheckInterval());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, MAX_STATEMENTS, pds.getMaxStatements());
        // getConnectionWaitTimeout() in oracle.ucp.jdbc.PoolDataSource has been deprecated
        // SmartPoolDataSource.setProperty(commonDataSourceProperties, CONNECTION_WAIT_TIMEOUT, pds.getConnectionWaitTimeout());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, MAX_CONNECTION_REUSE_TIME, pds.getMaxConnectionReuseTime());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, SECONDS_TO_TRUST_IDLE_CONNECTION, pds.getSecondsToTrustIdleConnection());
        SmartPoolDataSource.setProperty(commonDataSourceProperties, CONNECTION_VALIDATION_TIMEOUT, pds.getConnectionValidationTimeout());

        return commonDataSourceProperties;
    }

    @Override
    protected void printDataSourceStatistics(final MyDataSourceStatistics myDataSourceStatistics, final Logger logger) {
        super.printDataSourceStatistics(myDataSourceStatistics, logger);
        // Only show the first time a pool has gotten a connection.
        // Not earlier because these (fixed) values may change before and after the first connection.
        if (myDataSourceStatistics.getCountOpenSession() == 1) {
            logger.info("initialPoolSize={}", getInitialPoolSize());
            logger.info("minPoolSize={}", getMinPoolSize());
            logger.info("maxPoolSize={}", getMaxPoolSize());
            logger.info("validateConnectionOnBorrow={}", getValidateConnectionOnBorrow());
            logger.info("connectionPoolName={}", getConnectionPoolName());
            logger.info("abandonedConnectionTimeout={}", getAbandonedConnectionTimeout());
            logger.info("timeToLiveConnectionTimeout={}", getTimeToLiveConnectionTimeout());
            logger.info("inactiveConnectionTimeout={}", getInactiveConnectionTimeout());
            logger.info("timeoutCheckInterval={}", getTimeoutCheckInterval());
            logger.info("maxStatements={}", getMaxStatements());
            logger.info("connectionWaitTimeout={}", getConnectionWaitTimeout());
            logger.info("maxConnectionReuseTime={}", getMaxConnectionReuseTime());
            logger.info("secondsToTrustIdleConnection={}", getSecondsToTrustIdleConnection());
            logger.info("connectionValidationTimeout={}", getConnectionValidationTimeout());
        }
    }

    protected String getPoolName() {
        return getConnectionPoolName();
    }
    
    protected int getActiveConnections() {
        try {
            return commonPoolDataSourceOracle.getBorrowedConnectionsCount();
        } catch (SQLException ex) {
            throw new RuntimeException(ex.getMessage());
        }
    }

    protected int getIdleConnections() {
        try {
            return commonPoolDataSourceOracle.getAvailableConnectionsCount();
        } catch (SQLException ex) {
            throw new RuntimeException(ex.getMessage());
        }
    }

    protected int getTotalConnections() {
        return getActiveConnections() + getIdleConnections();
    }

    protected int getMinimumPoolSize() {
        return getMinPoolSize();
    }

    protected int getMaximumPoolSize() {
        return getMaxPoolSize();
    }
}
