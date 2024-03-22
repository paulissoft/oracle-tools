package com.paulissoft.pato.jdbc;

import oracle.ucp.jdbc.PoolDataSourceImpl;
import java.sql.Connection;
import javax.sql.DataSource;
import java.sql.SQLException;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;
import lombok.NonNull;


@Slf4j
public class PoolDataSourceOracle extends BasePoolDataSourceOracle {

    private interface ToOverride {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;

        // don't know why?
        public void setPassword(String password) throws SQLException;

        // is final in PoolDataSourceImpl
        public void setTokenSupplier​(java.util.function.Supplier<? extends oracle.jdbc.AccessToken> tokenSupplier) throws java.sql.SQLException;
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

    public void join(final PoolDataSourceImpl ds) {
        join((CommonPoolDataSourceOracle)ds);
    }
    
    public void leave(final PoolDataSourceImpl ds) {
        leave((CommonPoolDataSourceOracle)ds);
    }

    public void close() {
        leave(commonPoolDataSourceOracle);
    }

    @Override
    public void setPassword(String password) {
        commonPoolDataSourceOracle.setPassword(password);
    }

    private void join(final CommonPoolDataSourceOracle pds) {
        try {
            pds.join(this);
        } finally {
            commonPoolDataSourceOracle = pds;
        }
    }

    private void leave(final CommonPoolDataSourceOracle pds) {
        try {
            pds.leave(this);
        } finally {
            commonPoolDataSourceOracle = null;
        }
    }
}
