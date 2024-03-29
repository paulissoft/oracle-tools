package com.paulissoft.pato.jdbc;

import javax.sql.DataSource;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.ConstructorBinding;
import oracle.ucp.jdbc.PoolDataSourceImpl;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;


@Slf4j
@ConstructorBinding
@ConfigurationProperties(prefix = "app.operator.datasource.oracleucp")
public record MyDataSourceOracle(String connectionPoolName,
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
                                 int connectionValidationTimeout) implements DataSource {
    
    static DataSource ds = new PoolDataSourceImpl();
    
    public MyDataSourceOracle {
        log.info("id: {}", toString());
    }

    @Delegate
    DataSource getDataSource() {
        return ds;
    }
}
