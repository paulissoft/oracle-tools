package com.pato.java.jdbc.pool;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;
import lombok.experimental.Delegate;
import oracle.ucp.jdbc.PoolDataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class PatoPoolDataSourceOracle extends PatoPoolDataSource implements PoolDataSource {
    // static stuff

    private static final Logger logger = LoggerFactory.getLogger(PatoPoolDataSourceOracle.class);
    
    static {
        logger.info("Initializing {}", PatoPoolDataSourceOracle.class.toString());
    }

    private interface Overrides {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;
    }

    @Delegate(excludes=Overrides.class)
    private PoolDataSource commonPoolDataSourceOracle;
    
    public PatoPoolDataSourceOracle(final PoolDataSource pds,
                                  final Properties key,
                                  final String username,
                                  final String password) {
        super(pds, key, username, password);
        
        commonPoolDataSourceOracle = (PoolDataSource) commonPoolDataSource;

        setSingleSessionProxyModel(false);
        
        synchronized (PatoPoolDataSource.class) {
            try {
                // update pool sizes and default username / password when the pool data source is added to an existing
                if (commonPoolDataSourceOracle.equals(pds)) {
                    setConnectionPoolName("OraclePool"); // the prefix
                } else {
                    logger.info("initial pool size before: {}", getInitialPoolSize());
                    logger.info("max pool size before: {}", getMaxPoolSize());
                    logger.info("min pool size before: {}", getMinPoolSize());
                    
                    setMaxPoolSize(pds.getMaxPoolSize() + getMaxPoolSize());
                    setMinPoolSize(pds.getMinPoolSize() + getMinPoolSize());
                    setInitialPoolSize(pds.getInitialPoolSize() + getInitialPoolSize());
                    
                    logger.info("initial pool size after: {}", getInitialPoolSize());
                    logger.info("max pool size after: {}", getMaxPoolSize());
                    logger.info("min pool size after: {}", getMinPoolSize());
                    
                    setUser(username);
                    setPassword(password);
                }
                setConnectionPoolName(getConnectionPoolName() + "-" + schema.toString());
                logger.info("Common pool name: {}", getConnectionPoolName());
            } catch (SQLException ex) {
                throw new RuntimeException(ex.getMessage());
            }
        }
    }
    
    @Override
    protected void printDataSourceStatistics(final MyDataSourceStatistics myDataSourceStatistics, final Logger logger) {
        super.printDataSourceStatistics(myDataSourceStatistics, logger);
        // Only show the first time a pool has gotten a connection.
        // Not earlier because these (fixed) values may change before and after the first connection.
        if (myDataSourceStatistics.getCount() == 1) {
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

    public void setUsername(String username) throws SQLException {
        setUser(username);
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
