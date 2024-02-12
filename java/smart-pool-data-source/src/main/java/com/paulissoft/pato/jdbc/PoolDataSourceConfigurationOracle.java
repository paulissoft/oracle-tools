package com.paulissoft.pato.jdbc;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.stereotype.Component;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;


@Getter
@Setter
@ToString
@Configuration
@Component
public class PoolDataSourceConfigurationOracle extends PoolDataSourceConfiguration {

    // Spring properties
    @Value("${spring.datasource.ucp.initial-pool-size}")
    private int initialPoolSize;

    @Value("${spring.datasource.ucp.min-pool-size}")
    private int minPoolSize;

    @Value("${spring.datasource.ucp.max-pool-size}")
    private int maxPoolSize;
    
    @Value("${spring.datasource.ucp.connection-factory-class-name}")
    private String connectionFactoryClassName;

    @Value("${spring.datasource.ucp.validate-connection-on-borrow}")
    private boolean validateConnectionOnBorrow;

    @Value("${spring.datasource.ucp.connection-pool-name}")
    private String connectionPoolName;

    @Value("${spring.datasource.ucp.abandoned-connection-timeout}")
    private int abandonedConnectionTimeout;

    @Value("${spring.datasource.ucp.time-to-live-connection-timeout}")
    private int timeToLiveConnectionTimeout;

    @Value("${spring.datasource.ucp.inactive-connection-timeout}")
    private int inactiveConnectionTimeout;

    @Value("${spring.datasource.ucp.timeout-check-interval}")
    private int timeoutCheckInterval;

    @Value("${spring.datasource.ucp.max-statements}")
    private int maxStatements;

    @Value("${spring.datasource.ucp.connection-wait-timeout}")
    private int connectionWaitTimeout;

    @Value("${spring.datasource.ucp.maxconnection-reuse-time}")
    private int maxConnectionReuseTime;

    @Value("${spring.datasource.ucp.seconds-to-trust-idle-connection}")
    private int secondsToTrustIdleConnection;

    @Value("${spring.datasource.ucp.connection-validation-timeout}")
    private int connectionValidationTimeout;
}
