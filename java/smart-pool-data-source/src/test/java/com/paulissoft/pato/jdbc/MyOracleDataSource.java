package com.paulissoft.pato.jdbc;

import java.sql.SQLException;
import lombok.extern.slf4j.Slf4j;
import lombok.NonNull;


@Slf4j
public class MyOracleDataSource extends CommonPoolDataSourceOracle {

    // Since getPassword is deprecated in PoolDataSourceImpl
    // we need to store it here via setPassword()
    // and return it via getPassword().
    private String password;

    // just add a dummy constructor and override methods to see the logging
    public MyOracleDataSource() {
    }

    public MyOracleDataSource(@NonNull String url,
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

        log.info("MyOracleDataSource()");
        log.info("getURL(): {}", getURL());
        log.info("getMaxPoolSize(): {}", getMaxPoolSize());
        log.info("getMinPoolSize(): {}", getMinPoolSize());
        log.info("getConnectionPoolName(): {}", getConnectionPoolName());
        log.info("getUser(): {}", getUser());
    }
    
    @Override
    public void setURL(java.lang.String jdbcUrl) throws SQLException {
        log.info("setURL({})", jdbcUrl);
        super.setURL(jdbcUrl);
    }

    @Override
    public void setMaxPoolSize(int maxPoolSize) throws SQLException {
        log.info("setMaxPoolSize({})", maxPoolSize);
        super.setMaxPoolSize(maxPoolSize);
    }

    @Override
    public void setMinPoolSize(int minPoolSize) throws SQLException {
        log.info("setMinPoolSize({})", minPoolSize);
        super.setMinPoolSize(minPoolSize);
    }

    @Override
    public void setConnectionPoolName(java.lang.String poolName) throws SQLException {
        log.info("setConnectionPoolName({})", poolName);
        super.setConnectionPoolName(poolName);
    }

    @Override
    public void setUser(java.lang.String username) throws SQLException {
        log.info("setUser({})", username);
        super.setUser(username);
    }
    
    @Override
    public void setPassword(String password) {
        log.info("setPassword({})", password);
        super.setPassword(password);
        this.password = password;
    }

    @Override
    public String getPassword() {
        log.info("getPassword()");
        return password;
    }
}
