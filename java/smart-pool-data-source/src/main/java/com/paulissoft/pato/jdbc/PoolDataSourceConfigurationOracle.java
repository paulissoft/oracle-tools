package com.paulissoft.pato.jdbc;

import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.ToString;
import lombok.experimental.SuperBuilder;
import org.springframework.boot.context.properties.ConfigurationProperties;


@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@NoArgsConstructor
@SuperBuilder(toBuilder = true)
@ConfigurationProperties
public class PoolDataSourceConfigurationOracle extends PoolDataSourceConfiguration {

    // properties that may differ, i.e. are ignored
    
    private String connectionPoolName;

    private int initialPoolSize;

    private int minPoolSize;

    private int maxPoolSize;

    // properties that may NOT differ, i.e. must be common
        
    private String connectionFactoryClassName;

    private boolean validateConnectionOnBorrow;

    private int abandonedConnectionTimeout;

    private int timeToLiveConnectionTimeout;

    private int inactiveConnectionTimeout;

    private int timeoutCheckInterval;

    private int maxStatements;

    private int connectionWaitTimeout;

    private long maxConnectionReuseTime;

    private int secondsToTrustIdleConnection;

    private int connectionValidationTimeout;

    public void clearCommonDataSourceConfiguration() {
        super.clearCommonDataSourceConfiguration();
        this.connectionPoolName = null;
        this.initialPoolSize = 0;
        this.minPoolSize = 0;
        this.maxPoolSize = 0;
    }
}
