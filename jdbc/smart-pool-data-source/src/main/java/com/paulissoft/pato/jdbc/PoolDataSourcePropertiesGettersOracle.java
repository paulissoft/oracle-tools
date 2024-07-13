package com.paulissoft.pato.jdbc;


public interface PoolDataSourcePropertiesGettersOracle extends PoolDataSourcePropertiesGetters {

    String getURL();
  
    String getUser();
  
    String getConnectionPoolName();
  
    int getInitialPoolSize();
  
    int getMinPoolSize();
  
    int getMaxPoolSize();
  
    String getConnectionFactoryClassName();
  
    boolean getValidateConnectionOnBorrow();
  
    int getAbandonedConnectionTimeout();
  
    int getTimeToLiveConnectionTimeout();
  
    int getInactiveConnectionTimeout();
  
    int getTimeoutCheckInterval();
  
    int getMaxStatements();
  
    long getConnectionWaitDurationInMillis();

    long getMaxConnectionReuseTime();
  
    int getSecondsToTrustIdleConnection();
  
    int getConnectionValidationTimeout();

    /*
     * Properties as derived from the getters/setters below are not implemented yet.
     */

}
