package com.paulissoft.pato.jdbc;


public interface PoolDataSourcePropertiesHikari extends PoolDataSourceProperties {

    String getJdbcUrl();
  
    void setJdbcUrl(String jdbcUrl);
  
    String getPoolName();

    void setPoolName(String poolName);    

    int getMaximumPoolSize();

    void setMaximumPoolSize(int maxPoolSize);

    int getMinimumIdle();

    void setMinimumIdle(int minIdle);

    String getDataSourceClassName();

    void setDataSourceClassName(String dataSourceClassName);

    boolean isAutoCommit();

    void setAutoCommit(boolean isAutoCommit);

    long getConnectionTimeout();

    void setConnectionTimeout(long connectionTimeoutMs);

    long getIdleTimeout();

    void setIdleTimeout(long idleTimeoutMs);

    long getMaxLifetime();

    void setMaxLifetime(long maxLifetimeMs);

    String getConnectionTestQuery();

    void setConnectionTestQuery(String connectionTestQuery);

    long getInitializationFailTimeout();

    void setInitializationFailTimeout(long initializationFailTimeout);

    boolean isIsolateInternalQueries();

    void setIsolateInternalQueries(boolean isolate);

    boolean isAllowPoolSuspension();

    void setAllowPoolSuspension(boolean isAllowPoolSuspension);

    boolean isReadOnly();

    void setReadOnly(boolean readOnly);

    boolean isRegisterMbeans();
    
    void setRegisterMbeans(boolean register);
    
    long getValidationTimeout();

    void setValidationTimeout(long validationTimeoutMs);

    long getLeakDetectionThreshold();

    void setLeakDetectionThreshold(long leakDetectionThreshold);


}
