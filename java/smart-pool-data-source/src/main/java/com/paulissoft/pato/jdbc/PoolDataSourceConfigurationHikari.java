package com.paulissoft.pato.jdbc;

import lombok.experimental.SuperBuilder;


@SuperBuilder(toBuilder = true)
public class PoolDataSourceConfigurationHikari extends PoolDataSourceConfiguration {

    private boolean autoCommit;
    
    private long connectionTimeout;
    
    private long idleTimeout;
    
    private long maxLifetime;
    
    private String connectionTestQuery;
    
    private int maximumPoolSize;

    private String poolName;
        
    private int minimumIdle;
    
    private long initializationFailTimeout;
    
    private boolean isolateInternalQueries;
    
    private boolean allowPoolSuspension;
    
    private boolean readOnly;
    
    private boolean registerMbeans;
    
    private long validationTimeout;
    
    private long leakDetectionThreshold;
}
