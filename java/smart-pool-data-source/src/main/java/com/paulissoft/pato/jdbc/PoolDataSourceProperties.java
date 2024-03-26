package com.paulissoft.pato.jdbc;


public interface PoolDataSourceProperties extends PoolDataSourcePropertiesSetters {

    String getUrl();
  
    String getUsername();

    @Deprecated
    String getPassword();
}
