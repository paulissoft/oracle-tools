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
  
    @Deprecated
    int getConnectionWaitTimeout();

    long getMaxConnectionReuseTime();
  
    int getSecondsToTrustIdleConnection();
  
    int getConnectionValidationTimeout();

    /*
     * Properties as derived from the getters/setters below are not implemented yet.
     */
    
    /*    
          boolean getFastConnectionFailoverEnabled();
  
          int getMaxIdleTime();
  
          int getPropertyCycle();
  
          String getServerName();
  
          int getPortNumber();
  
          String getDatabaseName();
  
          String getDataSourceName();
  
          String getDescription();
  
          String getNetworkProtocol();
  
          String getRoleName();
  
          String getSQLForValidateConnection();
  
          int getConnectionHarvestTriggerCount();
  
          int getConnectionHarvestMaxCount();
  
          int getAvailableConnectionsCount() throws SQLException;
  
          int getBorrowedConnectionsCount() throws SQLException;
  
          String getONSConfiguration() throws SQLException;
  
          Connection getConnection(Properties paramProperties) throws SQLException;
  
          Connection getConnection(String paramString1, String paramString2, Properties paramProperties) throws SQLException;
  
          void registerConnectionLabelingCallback(ConnectionLabelingCallback paramConnectionLabelingCallback) throws SQLException;
  
          void removeConnectionLabelingCallback() throws SQLException;
  
          void registerConnectionAffinityCallback(ConnectionAffinityCallback paramConnectionAffinityCallback) throws SQLException;
  
          void removeConnectionAffinityCallback() throws SQLException;
  
          Properties getConnectionProperties();
  
          String getConnectionProperty(String paramString);
  
          Properties getConnectionFactoryProperties();
  
          String getConnectionFactoryProperty(String paramString);
  
          int getMaxConnectionReuseCount();
  
          JDBCConnectionPoolStatistics getStatistics();
  
          void registerConnectionInitializationCallback(ConnectionInitializationCallback paramConnectionInitializationCallback) throws SQLException;
  
          void unregisterConnectionInitializationCallback() throws SQLException;
  
          ConnectionInitializationCallback getConnectionInitializationCallback();
  
          int getConnectionLabelingHighCost();
  
          int getHighCostConnectionReuseThreshold();
  
          UCPConnectionBuilder createConnectionBuilder();

          int getConnectionRepurposeThreshold();
  
          Properties getPdbRoles();
  
          String getServiceName();
  
          void reconfigureDataSource(Properties paramProperties) throws SQLException;
  
          int getMaxConnectionsPerService();
  
          int getQueryTimeout();
  
          int getMaxConnectionsPerShard();
  
          boolean getShardingMode();
  
          int getConnectionValidationTimeout();
  
          boolean isReadOnlyInstanceAllowed();
  
    */
}
