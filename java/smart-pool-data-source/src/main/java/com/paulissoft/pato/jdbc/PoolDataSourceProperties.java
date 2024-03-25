package com.paulissoft.pato.jdbc;

import java.sql.SQLException;


public interface PoolDataSourceProperties {

    String getUrl();
  
    void setUrl(String jdbcUrl) throws SQLException;
  
    String getUsername();

    void setUsername(java.lang.String username) throws SQLException;
    
    @Deprecated
    String getPassword();

    void setPassword(String paramString) throws SQLException;
}
