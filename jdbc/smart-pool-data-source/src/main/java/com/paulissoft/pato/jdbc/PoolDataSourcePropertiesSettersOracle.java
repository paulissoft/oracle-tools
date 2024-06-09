package com.paulissoft.pato.jdbc;

import java.sql.SQLException;


public interface PoolDataSourcePropertiesSettersOracle extends PoolDataSourcePropertiesSetters {

    void setURL(String paramString) throws SQLException;
  
    void setUser(String paramString) throws SQLException;
  
    void setConnectionPoolName(String paramString) throws SQLException;
  
    void setInitialPoolSize(int paramInt) throws SQLException;
  
    void setMinPoolSize(int paramInt) throws SQLException;
  
    void setMaxPoolSize(int paramInt) throws SQLException;
  
    void setConnectionFactoryClassName(String paramString) throws SQLException;
  
    void setValidateConnectionOnBorrow(boolean paramBoolean) throws SQLException;
  
    void setAbandonedConnectionTimeout(int paramInt) throws SQLException;
  
    void setTimeToLiveConnectionTimeout(int paramInt) throws SQLException;
  
    void setInactiveConnectionTimeout(int paramInt) throws SQLException;
  
    void setTimeoutCheckInterval(int paramInt) throws SQLException;
  
    void setMaxStatements(int paramInt) throws SQLException;
  
    void setConnectionWaitDurationInMillis(long paramInt) throws SQLException;
  
    void setMaxConnectionReuseTime(long paramLong) throws SQLException;
  
    void setSecondsToTrustIdleConnection(int paramInt) throws SQLException;

    void setConnectionValidationTimeout(int paramInt) throws SQLException;
  
    /*
     * Properties as derived from the getters/setters below are not implemented yet.
     */
    
    /*    
          void setFastConnectionFailoverEnabled(boolean paramBoolean) throws SQLException;
  
          void setMaxIdleTime(int paramInt) throws SQLException;
  
          void setPropertyCycle(int paramInt) throws SQLException;
  
          void setServerName(String paramString) throws SQLException;
  
          void setPortNumber(int paramInt) throws SQLException;
  
          void setDatabaseName(String paramString) throws SQLException;
  
          void setDataSourceName(String paramString) throws SQLException;
  
          void setDescription(String paramString) throws SQLException;
  
          void setNetworkProtocol(String paramString) throws SQLException;
  
          void setRoleName(String paramString) throws SQLException;
  
          void setSQLForValidateConnection(String paramString) throws SQLException;
  
          void setConnectionHarvestTriggerCount(int paramInt) throws SQLException;
  
          void setConnectionHarvestMaxCount(int paramInt) throws SQLException;
  
          void setONSConfiguration(String paramString) throws SQLException;
  
          void setConnectionProperty(String paramString1, String paramString2) throws SQLException;
  
          void setConnectionProperties(Properties paramProperties) throws SQLException;
  
          void setConnectionFactoryProperty(String paramString1, String paramString2) throws SQLException;
  
          void setConnectionFactoryProperties(Properties paramProperties) throws SQLException;
  
          void setMaxConnectionReuseCount(int paramInt) throws SQLException;
  
          void setConnectionLabelingHighCost(int paramInt) throws SQLException;
  
          void setHighCostConnectionReuseThreshold(int paramInt) throws SQLException;
  
          void setConnectionRepurposeThreshold(int paramInt) throws SQLException;
  
          void setSecondsToTrustIdleConnection(int paramInt) throws SQLException;
  
          void setQueryTimeout(int paramInt) throws SQLException;
  
          void setMaxConnectionsPerShard(int paramInt) throws SQLException;
  
          void setShardingMode(boolean paramBoolean) throws SQLException;
  
          void setConnectionValidationTimeout(int paramInt) throws SQLException;
  
          void setSSLContext(SSLContext paramSSLContext);
  
          void setReadOnlyInstanceAllowed(boolean paramBoolean) throws SQLException;
    */
}
