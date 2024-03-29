package com.paulissoft.pato.jdbc;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.ConstructorBinding;


@ConfigurationProperties(prefix = "app.operator.datasource.hikari")
public class MyDataSourceHikari extends CombiPoolDataSourceHikari {

    @ConstructorBinding
    public MyDataSourceHikari(String driverClassName,
                              String url,
                              String username,
                              String password,
                              String poolName,
                              int maximumPoolSize,
                              int minimumIdle,
                              String dataSourceClassName,
                              boolean autoCommit,
                              long connectionTimeout,
                              long idleTimeout,
                              long maxLifetime,
                              String connectionTestQuery,
                              long initializationFailTimeout,
                              boolean isolateInternalQueries,
                              boolean allowPoolSuspension,
                              boolean readOnly,
                              boolean registerMbeans,    
                              long validationTimeout,
                              long leakDetectionThreshold)
    {
        super(driverClassName,
              url,
              username,
              password,
              poolName,
              maximumPoolSize,
              minimumIdle,
              dataSourceClassName,
              autoCommit,
              connectionTimeout,
              idleTimeout,
              maxLifetime,
              connectionTestQuery,
              initializationFailTimeout,
              isolateInternalQueries,
              allowPoolSuspension,
              readOnly,
              registerMbeans,    
              validationTimeout,
              leakDetectionThreshold);
    }
}
