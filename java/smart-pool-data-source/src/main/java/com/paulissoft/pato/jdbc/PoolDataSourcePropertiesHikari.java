package com.paulissoft.pato.jdbc;


public interface PoolDataSourcePropertiesHikari extends PoolDataSourceProperties, PoolDataSourcePropertiesSettersHikari {

    String getDriverClassName();
    
    String getJdbcUrl();
  
    String getPoolName();

    int getMaximumPoolSize();

    int getMinimumIdle();

    String getDataSourceClassName();

    boolean isAutoCommit();

    long getConnectionTimeout();

    long getIdleTimeout();

    long getMaxLifetime();

    String getConnectionTestQuery();

    long getInitializationFailTimeout();

    boolean isIsolateInternalQueries();

    boolean isAllowPoolSuspension();

    boolean isReadOnly();

    boolean isRegisterMbeans();
    
    long getValidationTimeout();

    long getLeakDetectionThreshold();
}
