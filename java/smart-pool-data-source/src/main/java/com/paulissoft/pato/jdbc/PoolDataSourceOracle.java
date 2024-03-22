package com.paulissoft.pato.jdbc;

import oracle.ucp.jdbc.PoolDataSourceImpl;
import java.sql.Connection;
import java.sql.SQLException;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;
import lombok.NonNull;


@Slf4j
public class PoolDataSourceOracle extends BasePoolDataSourceOracle {

    private interface ToOverride {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;

        // is final in PoolDataSourceImpl       
        public void setTokenSupplier​(java.util.function.Supplier<? extends oracle.jdbc.AccessToken> tokenSupplier) throws java.sql.SQLException;

        public void setURL(String url) throws SQLException;

        public void setUser(String username) throws SQLException;

        // overridden method does not throw java.sql.SQLException
        public void setPassword(String password) throws SQLException;

        public void setConnectionPoolName(String connectionPoolName) throws SQLException;
        
        public void setInitialPoolSize(int initialPoolSize) throws SQLException;
        
        public void setMinPoolSize(int minPoolSize) throws SQLException;
        
        public void setMaxPoolSize(int maxPoolSize) throws SQLException;
        
        public void setConnectionFactoryClassName(String connectionFactoryClassName) throws SQLException;
        
        public void setValidateConnectionOnBorrow(boolean validateConnectionOnBorrow) throws SQLException;
        
        public void setAbandonedConnectionTimeout(int abandonedConnectionTimeout) throws SQLException;
        
        public void setTimeToLiveConnectionTimeout(int timeToLiveConnectionTimeout) throws SQLException;
        
        public void setInactiveConnectionTimeout(int inactiveConnectionTimeout) throws SQLException;
        
        public void setTimeoutCheckInterval(int timeoutCheckInterval) throws SQLException;
        
        public void setMaxStatements(int maxStatements) throws SQLException;
        
        public void setConnectionWaitTimeout(int connectionWaitTimeout) throws SQLException;
        
        public void setMaxConnectionReuseTime(long maxConnectionReuseTime) throws SQLException;
        
        public void setSecondsToTrustIdleConnection(int secondsToTrustIdleConnection) throws SQLException;
        
        public void setConnectionValidationTimeout(int connectionValidationTimeout) throws SQLException;        
    }

    @Delegate(types=PoolDataSourceImpl.class, excludes=ToOverride.class)
    private CommonPoolDataSourceOracle commonPoolDataSourceOracle = null;

    public PoolDataSourceOracle(@NonNull String url,
                                @NonNull String username,
                                @NonNull String password,
                                String connectionPoolName,
                                int initialPoolSize,
                                int minPoolSize,
                                int maxPoolSize,
                                @NonNull String connectionFactoryClassName,
                                boolean validateConnectionOnBorrow,
                                int abandonedConnectionTimeout,
                                int timeToLiveConnectionTimeout,
                                int inactiveConnectionTimeout,
                                int timeoutCheckInterval,
                                int maxStatements,
                                int connectionWaitTimeout,
                                long maxConnectionReuseTime,
                                int secondsToTrustIdleConnection,
                                int connectionValidationTimeout) {
        super(url,
              username,
              password,
              connectionPoolName,
              initialPoolSize,
              minPoolSize,
              maxPoolSize,
              connectionFactoryClassName,
              validateConnectionOnBorrow,
              abandonedConnectionTimeout,
              timeToLiveConnectionTimeout,
              inactiveConnectionTimeout,
              timeoutCheckInterval,
              maxStatements,
              connectionWaitTimeout,
              maxConnectionReuseTime,
              secondsToTrustIdleConnection,
              connectionValidationTimeout);
    }

    public Connection getConnection() throws SQLException {
        return commonPoolDataSourceOracle.getConnection(getUsernameSession1(),
                                                        getPasswordSession1(),
                                                        getUsernameSession2());
    }

    public Connection getConnection(String username, String password) throws SQLException {
        final PoolDataSourceConfiguration poolDataSourceConfiguration =
            new PoolDataSourceConfiguration("", "", username, password);

        final String usernameSession2 = poolDataSourceConfiguration.getSchema();
        // there may be no proxy session at all
        final String usernameSession1 =
            poolDataSourceConfiguration.getProxyUsername() != null
            ? poolDataSourceConfiguration.getProxyUsername()
            : usernameSession2;
        final String passwordSession1 = password;

        return commonPoolDataSourceOracle.getConnection(usernameSession1,
                                                        passwordSession1,
                                                        usernameSession2);
    }

    @Override
    public void setURL(String url) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setURL(url);
        } else {
            commonPoolDataSourceOracle.setURL(url);
        }
    }

    @Override
    public void setUser(String username) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setUser(username);
        } else {
            commonPoolDataSourceOracle.setUser(username);
        }
    }

    @Override
    public void setPassword(String password) {
        if (commonPoolDataSourceOracle == null) {
            super.setPassword(password);
        } else {
            commonPoolDataSourceOracle.setPassword(password);
        }
    }

    @Override
    public void setConnectionPoolName(String connectionPoolName) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setConnectionPoolName(connectionPoolName);
        } else {
            commonPoolDataSourceOracle.setConnectionPoolName(connectionPoolName);
        }
    }
        
    @Override
    public void setInitialPoolSize(int initialPoolSize) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setInitialPoolSize(initialPoolSize);
        } else {
            commonPoolDataSourceOracle.setInitialPoolSize(initialPoolSize);
        }
    }
        
    @Override
    public void setMinPoolSize(int minPoolSize) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setMinPoolSize(minPoolSize);
        } else {
            commonPoolDataSourceOracle.setMinPoolSize(minPoolSize);
        }
    }
        
    @Override
    public void setMaxPoolSize(int maxPoolSize) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setMaxPoolSize(maxPoolSize);
        } else {
            commonPoolDataSourceOracle.setMaxPoolSize(maxPoolSize);
        }
    }
        
    @Override
    public void setConnectionFactoryClassName(String connectionFactoryClassName) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setConnectionFactoryClassName(connectionFactoryClassName);
        } else {
            commonPoolDataSourceOracle.setConnectionFactoryClassName(connectionFactoryClassName);
        }
    }
        
    @Override
    public void setValidateConnectionOnBorrow(boolean validateConnectionOnBorrow) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setValidateConnectionOnBorrow(validateConnectionOnBorrow);
        } else {
            commonPoolDataSourceOracle.setValidateConnectionOnBorrow(validateConnectionOnBorrow);
        }
    }
        
    @Override
    public void setAbandonedConnectionTimeout(int abandonedConnectionTimeout) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setAbandonedConnectionTimeout(abandonedConnectionTimeout);
        } else {
            commonPoolDataSourceOracle.setAbandonedConnectionTimeout(abandonedConnectionTimeout);
        }
    }
        
    @Override
    public void setTimeToLiveConnectionTimeout(int timeToLiveConnectionTimeout) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setTimeToLiveConnectionTimeout(timeToLiveConnectionTimeout);
        } else {
            commonPoolDataSourceOracle.setTimeToLiveConnectionTimeout(timeToLiveConnectionTimeout);
        }
    }
        
    @Override
    public void setInactiveConnectionTimeout(int inactiveConnectionTimeout) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setInactiveConnectionTimeout(inactiveConnectionTimeout);
        } else {
            commonPoolDataSourceOracle.setInactiveConnectionTimeout(inactiveConnectionTimeout);
        }
    }
        
    @Override
    public void setTimeoutCheckInterval(int timeoutCheckInterval) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setTimeoutCheckInterval(timeoutCheckInterval);
        } else {
            commonPoolDataSourceOracle.setTimeoutCheckInterval(timeoutCheckInterval);
        }
    }
        
    @Override
    public void setMaxStatements(int maxStatements) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setMaxStatements(maxStatements);
        } else {
            commonPoolDataSourceOracle.setMaxStatements( maxStatements);
        }
    }
        
    @Override
    public void setConnectionWaitTimeout(int connectionWaitTimeout) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setConnectionWaitTimeout(connectionWaitTimeout);
        } else {
            commonPoolDataSourceOracle.setConnectionWaitTimeout(connectionWaitTimeout);
        }
    }
        
    @Override
    public void setMaxConnectionReuseTime(long maxConnectionReuseTime) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setMaxConnectionReuseTime(maxConnectionReuseTime);
        } else {
            commonPoolDataSourceOracle.setMaxConnectionReuseTime(maxConnectionReuseTime);
        }
    }
        
    @Override
    public void setSecondsToTrustIdleConnection(int secondsToTrustIdleConnection) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setSecondsToTrustIdleConnection(secondsToTrustIdleConnection);
        } else {
            commonPoolDataSourceOracle.setSecondsToTrustIdleConnection(secondsToTrustIdleConnection);
        }
    }
        
    @Override
    public void setConnectionValidationTimeout(int connectionValidationTimeout) throws SQLException {
        if (commonPoolDataSourceOracle == null) {
            super.setConnectionValidationTimeout(connectionValidationTimeout);
        } else {
            commonPoolDataSourceOracle.setConnectionValidationTimeout(connectionValidationTimeout);
        }
    }

    /* from the interface */
    
    public void join(final PoolDataSourceImpl ds) {
        join((CommonPoolDataSourceOracle)ds);
    }
    
    private void join(final CommonPoolDataSourceOracle pds) {
        if (commonPoolDataSourceOracle != null) {
            return;
        }
        
        try {
            pds.join(this);
        } finally {
            commonPoolDataSourceOracle = pds;
        }
    }

    public void leave(final PoolDataSourceImpl ds) {
        leave((CommonPoolDataSourceOracle)ds);
    }

    private void leave(final CommonPoolDataSourceOracle pds) {
        commonPoolDataSourceOracle = null; // this will force getXXX functions to use super.getXXX (see above)
        pds.leave(this);
    }

    public void close() {
        if (commonPoolDataSourceOracle != null) {
            leave(commonPoolDataSourceOracle);
        }
    }
}
