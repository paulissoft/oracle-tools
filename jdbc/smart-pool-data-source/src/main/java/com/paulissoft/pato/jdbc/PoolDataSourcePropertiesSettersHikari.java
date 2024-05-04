package com.paulissoft.pato.jdbc;


public interface PoolDataSourcePropertiesSettersHikari extends PoolDataSourcePropertiesSetters {

    void setDriverClassName(String driverClassName);
    
    void setJdbcUrl(String jdbcUrl);
  
    void setPoolName(String poolName);    

    void setMaximumPoolSize(int maxPoolSize);

    void setMinimumIdle(int minIdle);

    void setDataSourceClassName(String dataSourceClassName);

    void setAutoCommit(boolean isAutoCommit);

    void setConnectionTimeout(long connectionTimeoutMs);

    void setIdleTimeout(long idleTimeoutMs);

    void setMaxLifetime(long maxLifetimeMs);

    void setConnectionTestQuery(String connectionTestQuery);

    void setInitializationFailTimeout(long initializationFailTimeout);

    void setIsolateInternalQueries(boolean isolate);

    void setAllowPoolSuspension(boolean isAllowPoolSuspension);

    void setReadOnly(boolean readOnly);

    void setRegisterMbeans(boolean register);
    
    void setValidationTimeout(long validationTimeoutMs);

    void setLeakDetectionThreshold(long leakDetectionThreshold);
}
