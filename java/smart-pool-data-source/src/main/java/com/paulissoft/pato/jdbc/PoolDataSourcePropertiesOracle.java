package com.paulissoft.pato.jdbc;

import java.sql.SQLException;


public interface PoolDataSourcePropertiesOracle extends PoolDataSourceProperties {

    void setURL(String paramString) throws SQLException;
  
    String getURL();
  
    void setUser(String paramString) throws SQLException;
  
    String getUser();
  
    void setConnectionPoolName(String paramString) throws SQLException;
  
    String getConnectionPoolName();
  
    int getInitialPoolSize();
  
    void setInitialPoolSize(int paramInt) throws SQLException;
  
    int getMinPoolSize();
  
    void setMinPoolSize(int paramInt) throws SQLException;
  
    int getMaxPoolSize();
  
    void setMaxPoolSize(int paramInt) throws SQLException;
  
    String getConnectionFactoryClassName();
  
    void setConnectionFactoryClassName(String paramString) throws SQLException;
  
    void setValidateConnectionOnBorrow(boolean paramBoolean) throws SQLException;
  
    boolean getValidateConnectionOnBorrow();
  
    int getAbandonedConnectionTimeout();
  
    void setAbandonedConnectionTimeout(int paramInt) throws SQLException;
  
    int getTimeToLiveConnectionTimeout();
  
    void setTimeToLiveConnectionTimeout(int paramInt) throws SQLException;
  
    int getInactiveConnectionTimeout();
  
    void setInactiveConnectionTimeout(int paramInt) throws SQLException;
  
    void setTimeoutCheckInterval(int paramInt) throws SQLException;
  
    int getTimeoutCheckInterval();
  
    void setMaxStatements(int paramInt) throws SQLException;
  
    int getMaxStatements();
  
    @Deprecated
    int getConnectionWaitTimeout();

    @Deprecated
    void setConnectionWaitTimeout(int paramInt) throws SQLException;
  
    long getMaxConnectionReuseTime();
  
    void setMaxConnectionReuseTime(long paramLong) throws SQLException;
  
    int getSecondsToTrustIdleConnection();
  
    void setSecondsToTrustIdleConnection(int paramInt) throws SQLException;

    void setConnectionValidationTimeout(int paramInt) throws SQLException;
  
    int getConnectionValidationTimeout();

    /*
     * Properties as derived from the getters/setters below are not implemented yet.
     */
    
    /*    
          void setFastConnectionFailoverEnabled(boolean paramBoolean) throws SQLException;
  
          boolean getFastConnectionFailoverEnabled();
  
          void setMaxIdleTime(int paramInt) throws SQLException;
  
          int getMaxIdleTime();
  
          void setPropertyCycle(int paramInt) throws SQLException;
  
          int getPropertyCycle();
  
          void setServerName(String paramString) throws SQLException;
  
          String getServerName();
  
          void setPortNumber(int paramInt) throws SQLException;
  
          int getPortNumber();
  
          void setDatabaseName(String paramString) throws SQLException;
  
          String getDatabaseName();
  
          void setDataSourceName(String paramString) throws SQLException;
  
          String getDataSourceName();
  
          void setDescription(String paramString) throws SQLException;
  
          String getDescription();
  
          void setNetworkProtocol(String paramString) throws SQLException;
  
          String getNetworkProtocol();
  
          void setRoleName(String paramString) throws SQLException;
  
          String getRoleName();
  
          void setSQLForValidateConnection(String paramString) throws SQLException;
  
          String getSQLForValidateConnection();
  
          int getConnectionHarvestTriggerCount();
  
          void setConnectionHarvestTriggerCount(int paramInt) throws SQLException;
  
          int getConnectionHarvestMaxCount();
  
          void setConnectionHarvestMaxCount(int paramInt) throws SQLException;
  
          int getAvailableConnectionsCount() throws SQLException;
  
          int getBorrowedConnectionsCount() throws SQLException;
  
          String getONSConfiguration() throws SQLException;
  
          void setONSConfiguration(String paramString) throws SQLException;
  
          Connection getConnection(Properties paramProperties) throws SQLException;
  
          Connection getConnection(String paramString1, String paramString2, Properties paramProperties) throws SQLException;
  
          void registerConnectionLabelingCallback(ConnectionLabelingCallback paramConnectionLabelingCallback) throws SQLException;
  
          void removeConnectionLabelingCallback() throws SQLException;
  
          void registerConnectionAffinityCallback(ConnectionAffinityCallback paramConnectionAffinityCallback) throws SQLException;
  
          void removeConnectionAffinityCallback() throws SQLException;
  
          Properties getConnectionProperties();
  
          String getConnectionProperty(String paramString);
  
          void setConnectionProperty(String paramString1, String paramString2) throws SQLException;
  
          void setConnectionProperties(Properties paramProperties) throws SQLException;
  
          Properties getConnectionFactoryProperties();
  
          String getConnectionFactoryProperty(String paramString);
  
          void setConnectionFactoryProperty(String paramString1, String paramString2) throws SQLException;
  
          void setConnectionFactoryProperties(Properties paramProperties) throws SQLException;
  
          int getMaxConnectionReuseCount();
  
          void setMaxConnectionReuseCount(int paramInt) throws SQLException;
  
          JDBCConnectionPoolStatistics getStatistics();
  
          void registerConnectionInitializationCallback(ConnectionInitializationCallback paramConnectionInitializationCallback) throws SQLException;
  
          void unregisterConnectionInitializationCallback() throws SQLException;
  
          ConnectionInitializationCallback getConnectionInitializationCallback();
  
          int getConnectionLabelingHighCost();
  
          void setConnectionLabelingHighCost(int paramInt) throws SQLException;
  
          int getHighCostConnectionReuseThreshold();
  
          void setHighCostConnectionReuseThreshold(int paramInt) throws SQLException;
  
          UCPConnectionBuilder createConnectionBuilder();

          int getConnectionRepurposeThreshold();
  
          void setConnectionRepurposeThreshold(int paramInt) throws SQLException;
  
          Properties getPdbRoles();
  
          String getServiceName();
  
          int getSecondsToTrustIdleConnection();
  
          void setSecondsToTrustIdleConnection(int paramInt) throws SQLException;
  
          void reconfigureDataSource(Properties paramProperties) throws SQLException;
  
          int getMaxConnectionsPerService();
  
          int getQueryTimeout();
  
          void setQueryTimeout(int paramInt) throws SQLException;
  
          int getMaxConnectionsPerShard();
  
          void setMaxConnectionsPerShard(int paramInt) throws SQLException;
  
          void setShardingMode(boolean paramBoolean) throws SQLException;
  
          boolean getShardingMode();
  
          void setConnectionValidationTimeout(int paramInt) throws SQLException;
  
          int getConnectionValidationTimeout();
  
          void setSSLContext(SSLContext paramSSLContext);
  
          boolean isReadOnlyInstanceAllowed();
  
          void setReadOnlyInstanceAllowed(boolean paramBoolean) throws SQLException;
    */
}
