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

    @Value("${spring.datasource.ucp.validate-connection-on-borrow}")
    private String validateConnectionOnBorrow;

    @Value("${spring.datasource.ucp.connection-pool-name}")
    private String connectionPoolName;

    @Value("${spring.datasource.ucp.abandoned-connection-timeout}")
    private String abandonedConnectionTimeout;

    @Value("${spring.datasource.ucp.time-to-live-connection-timeout}")
    private String timeToLiveConnectionTimeout;

    @Value("${spring.datasource.ucp.inactive-connection-timeout}")
    private String inactiveConnectionTimeout;

    @Value("${spring.datasource.ucp.timeout-check-interval}")
    private String timeoutCheckInterval;

    @Value("${spring.datasource.ucp.max-statements}")
    private String maxStatements;

    @Value("${spring.datasource.ucp.connection-wait-timeout}")
    private String connectionWaitTimeout;

    @Value("${spring.datasource.ucp.maxconnection-reuse-time}")
    private String maxConnectionReuseTime;

    @Value("${spring.datasource.ucp.seconds-to-trust-idle-connection}")
    private String secondsToTrustIdleConnection;

    @Value("${spring.datasource.ucp.connection-validation-timeout}")
    private String connectionValidationTimeout;
}
