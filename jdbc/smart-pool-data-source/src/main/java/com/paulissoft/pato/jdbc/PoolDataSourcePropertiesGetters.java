package com.paulissoft.pato.jdbc;


public interface PoolDataSourcePropertiesGetters {

    String getUrl();
  
    String getUsername();

    // @Deprecated
    // SimplePoolDataSourceOracle now has a normal getPassword() since that is needed for OverflowPoolDataSourceOracle
    String getPassword();
}
