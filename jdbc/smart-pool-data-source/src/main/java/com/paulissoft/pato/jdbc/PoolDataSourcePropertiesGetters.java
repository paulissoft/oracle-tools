package com.paulissoft.pato.jdbc;


public interface PoolDataSourcePropertiesGetters {

    String getUrl();
  
    String getUsername();

    @Deprecated
    String getPassword();
}
