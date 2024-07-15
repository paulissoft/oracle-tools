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

}
