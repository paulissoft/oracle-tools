package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.SQLException;
import javax.sql.DataSource;
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
                                     final String password) throws SQLException {
        super(pds, determineCommonDataSourceProperties(pds), username, password, true, false);        
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

    protected void printDataSourceStatistics(final DataSource poolDataSource, final Logger logger) {
        final PoolDataSource poolDataSourceOracle = ((PoolDataSource)poolDataSource);
        
        logger.info("configuration pool data source {}:", poolDataSourceOracle.getConnectionPoolName());
        logger.info("- connectionFactoryClassName: {}", poolDataSourceOracle.getConnectionFactoryClassName());
        logger.info("- URL: {}", poolDataSourceOracle.getURL());
        logger.info("- user: {}", poolDataSourceOracle.getUser());
        logger.info("- initialPoolSize={}", poolDataSourceOracle.getInitialPoolSize());
        logger.info("- minPoolSize={}", poolDataSourceOracle.getMinPoolSize());
        logger.info("- maxPoolSize={}", poolDataSourceOracle.getMaxPoolSize());        
        logger.info("- validateConnectionOnBorrow={}", poolDataSourceOracle.getValidateConnectionOnBorrow());
        logger.info("- connectionPoolName={}", poolDataSourceOracle.getConnectionPoolName());
        logger.info("- abandonedConnectionTimeout={}", poolDataSourceOracle.getAbandonedConnectionTimeout());
        logger.info("- timeToLiveConnectionTimeout={}", poolDataSourceOracle.getTimeToLiveConnectionTimeout());
        logger.info("- inactiveConnectionTimeout={}", poolDataSourceOracle.getInactiveConnectionTimeout());
        logger.info("- timeoutCheckInterval={}", poolDataSourceOracle.getTimeoutCheckInterval());
        logger.info("- maxStatements={}", poolDataSourceOracle.getMaxStatements());
        logger.info("- connectionWaitTimeout={}", poolDataSourceOracle.getConnectionWaitTimeout());
        logger.info("- maxConnectionReuseTime={}", poolDataSourceOracle.getMaxConnectionReuseTime());
        logger.info("- secondsToTrustIdleConnection={}", poolDataSourceOracle.getSecondsToTrustIdleConnection());
        logger.info("- connectionValidationTimeout={}", poolDataSourceOracle.getConnectionValidationTimeout());

        logger.info("connections pool data source {}:", poolDataSourceOracle.getConnectionPoolName());
        logger.info("- total={}", getTotalConnections(poolDataSourceOracle));
        logger.info("- active={}", getActiveConnections(poolDataSourceOracle));
        logger.info("- idle={}", getIdleConnections(poolDataSourceOracle));
    }

    protected void setCommonPoolDataSource(final DataSource commonPoolDataSource) {
        commonPoolDataSourceOracle = (PoolDataSource) commonPoolDataSource;
    }

    protected String getPoolNamePrefix() {
        return "OraclePool";
    }
    
    protected String getPoolName() {
        return getConnectionPoolName();
    }
    
    protected void setPoolName(String poolName) throws SQLException {
        setConnectionPoolName(poolName);
    }

    protected void setUsername(String username) throws SQLException {
        setUser(username);
    }

    protected int getInitialPoolSize(DataSource pds) {
        return ((PoolDataSource)pds).getInitialPoolSize();
    }

    protected int getMinimumPoolSize() {
        return getMinPoolSize();
    }

    protected int getMinimumPoolSize(DataSource pds) {
        return ((PoolDataSource)pds).getMinPoolSize();
    }

    protected void setMinimumPoolSize(int minimumPoolSize) throws SQLException {
        setMinPoolSize(minimumPoolSize);
    }

    protected int getMaximumPoolSize() {
        return getMaxPoolSize();
    }

    protected int getMaximumPoolSize(DataSource pds) {
        return ((PoolDataSource)pds).getMaxPoolSize();
    }

    protected void setMaximumPoolSize(int maximumPoolSize) throws SQLException {
        setMaxPoolSize(maximumPoolSize);
    }

    protected long getConnectionTimeout() {
        return 1000 * getConnectionWaitTimeout();
    }

    protected int getActiveConnections() {
        return getActiveConnections(commonPoolDataSourceOracle);
    }

    private static int getActiveConnections(final PoolDataSource poolDataSource) {
        try {
            return poolDataSource.getBorrowedConnectionsCount();
        } catch (SQLException ex) {
            throw new RuntimeException(ex.getMessage());
        }
    }

    protected int getIdleConnections() {
        return getIdleConnections(commonPoolDataSourceOracle);
    }

    private static int getIdleConnections(final PoolDataSource poolDataSource) {
        try {
            return poolDataSource.getAvailableConnectionsCount();
        } catch (SQLException ex) {
            throw new RuntimeException(ex.getMessage());
        }
    }

    protected int getTotalConnections() {
        return getTotalConnections(commonPoolDataSourceOracle);
    }

    private static int getTotalConnections(final PoolDataSource poolDataSource) {
        return getActiveConnections(poolDataSource) + getIdleConnections(poolDataSource);
    }
}
