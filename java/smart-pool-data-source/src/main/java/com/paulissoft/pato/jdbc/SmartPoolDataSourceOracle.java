package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
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
        if (!logger.isDebugEnabled()) {
            return;
        }
        
        final PoolDataSource poolDataSourceOracle = ((PoolDataSource)poolDataSource);
        final String prefix = INDENT_PREFIX;
        
        logger.debug("configuration pool data source {}:", poolDataSourceOracle.getConnectionPoolName());
        logger.debug("{}connectionFactoryClassName: {}", prefix, poolDataSourceOracle.getConnectionFactoryClassName());
        logger.debug("{}URL: {}", prefix, poolDataSourceOracle.getURL());
        logger.debug("{}user: {}", prefix, poolDataSourceOracle.getUser());
        logger.debug("{}initialPoolSize={}", prefix, poolDataSourceOracle.getInitialPoolSize());
        logger.debug("{}minPoolSize={}", prefix, poolDataSourceOracle.getMinPoolSize());
        logger.debug("{}maxPoolSize={}", prefix, poolDataSourceOracle.getMaxPoolSize());        
        logger.debug("{}validateConnectionOnBorrow={}", prefix, poolDataSourceOracle.getValidateConnectionOnBorrow());
        logger.debug("{}connectionPoolName={}", prefix, poolDataSourceOracle.getConnectionPoolName());
        logger.debug("{}abandonedConnectionTimeout={}", prefix, poolDataSourceOracle.getAbandonedConnectionTimeout());
        logger.debug("{}timeToLiveConnectionTimeout={}", prefix, poolDataSourceOracle.getTimeToLiveConnectionTimeout());
        logger.debug("{}inactiveConnectionTimeout={}", prefix, poolDataSourceOracle.getInactiveConnectionTimeout());
        logger.debug("{}timeoutCheckInterval={}", prefix, poolDataSourceOracle.getTimeoutCheckInterval());
        logger.debug("{}maxStatements={}", prefix, poolDataSourceOracle.getMaxStatements());
        logger.debug("{}connectionWaitTimeout={}", prefix, poolDataSourceOracle.getConnectionWaitTimeout());
        logger.debug("{}maxConnectionReuseTime={}", prefix, poolDataSourceOracle.getMaxConnectionReuseTime());
        logger.debug("{}secondsToTrustIdleConnection={}", prefix, poolDataSourceOracle.getSecondsToTrustIdleConnection());
        logger.debug("{}connectionValidationTimeout={}", prefix, poolDataSourceOracle.getConnectionValidationTimeout());

        logger.debug("connections pool data source {}:", poolDataSourceOracle.getConnectionPoolName());
        logger.debug("{}total={}", prefix, getTotalConnections(poolDataSourceOracle));
        logger.debug("{}active={}", prefix, getActiveConnections(poolDataSourceOracle));
        logger.debug("{}idle={}", prefix, getIdleConnections(poolDataSourceOracle));
    }

    protected Connection getConnectionSmart(final String username,
                                            final String password,
                                            final String schema,
                                            final String proxyUsername,
                                            final boolean updateStatistics,
                                            final boolean showStatistics) throws SQLException {
        throw new SQLFeatureNotSupportedException("getConnectionSmart()");
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

    protected String getPoolName(DataSource pds) {
        return ((PoolDataSource)pds).getConnectionPoolName();
    }
    
    protected void setPoolName(String poolName) throws SQLException {
        setConnectionPoolName(poolName);
    }
    
    protected void setPoolName(DataSource pds, String poolName) throws SQLException {
        ((PoolDataSource)pds).setConnectionPoolName(poolName);
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
