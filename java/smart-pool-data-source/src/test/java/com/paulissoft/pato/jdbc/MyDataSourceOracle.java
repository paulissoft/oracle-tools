package com.paulissoft.pato.jdbc;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.ConstructorBinding;


@ConfigurationProperties(prefix = "app.operator.datasource.oracleucp")
public class MyDataSourceOracle extends CombiPoolDataSourceOracle {

    @ConstructorBinding
    public MyDataSourceOracle(String url,
                              String username,
                              String password,
                              String connectionPoolName,
                              int initialPoolSize,
                              int minPoolSize,
                              int maxPoolSize,
                              String connectionFactoryClassName,
                              boolean validateConnectionOnBorrow,
                              int abandonedConnectionTimeout,
                              int timeToLiveConnectionTimeout,
                              int inactiveConnectionTimeout,
                              int timeoutCheckInterval,
                              int maxStatements,
                              int connectionWaitTimeout,
                              long maxConnectionReuseTime,
                              int secondsToTrustIdleConnection,
                              int connectionValidationTimeout)
    {
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
}

