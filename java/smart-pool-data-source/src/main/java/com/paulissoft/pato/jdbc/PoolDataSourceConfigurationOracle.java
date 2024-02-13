package com.paulissoft.pato.jdbc;

import lombok.experimental.SuperBuilder;


@SuperBuilder(toBuilder = true)
public class PoolDataSourceConfigurationOracle extends PoolDataSourceConfiguration {

    private boolean validateConnectionOnBorrow;

    private String connectionPoolName;

    private int abandonedConnectionTimeout;

    private int timeToLiveConnectionTimeout;

    private int inactiveConnectionTimeout;

    private int timeoutCheckInterval;

    private int maxStatements;

    private int connectionWaitTimeout;

    private int maxConnectionReuseTime;

    private int secondsToTrustIdleConnection;

    private int connectionValidationTimeout;
}
