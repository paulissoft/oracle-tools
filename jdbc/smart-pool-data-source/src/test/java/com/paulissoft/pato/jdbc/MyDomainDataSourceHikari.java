package com.paulissoft.pato.jdbc;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.ConstructorBinding;


@Slf4j
@ConfigurationProperties(prefix = "app.domain.datasource.hikari")
public class MyDomainDataSourceHikari extends SmartPoolDataSourceHikari {

    @ConstructorBinding
    public MyDomainDataSourceHikari(String driverClassName,
                                    String url,
                                    String username,
                                    String password,
                                    String type,
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
              type,
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
        log.debug("constructor MyDomainDataSourceHikari(username={})", username);
    }
}
