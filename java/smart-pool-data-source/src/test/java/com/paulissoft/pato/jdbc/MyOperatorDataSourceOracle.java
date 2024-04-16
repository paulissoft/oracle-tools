package com.paulissoft.pato.jdbc;

import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.ConstructorBinding;


@Slf4j
@ConfigurationProperties(prefix = "app.operator.datasource.oracleucp")
public class MyOperatorDataSourceOracle extends CombiPoolDataSourceOracle {

    public MyOperatorDataSourceOracle(@NonNull final CombiPoolDataSourceOracle activeParent) {
        super(activeParent);
    }

    @ConstructorBinding
    public MyOperatorDataSourceOracle(String url,
                                      String username,
                                      String password,
                                      String type,
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
              type,
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
        log.debug("constructor MyOperatorDataSourceOracle(username={})", username);
    }
}

