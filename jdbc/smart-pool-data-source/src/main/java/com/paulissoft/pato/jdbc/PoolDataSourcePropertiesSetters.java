package com.paulissoft.pato.jdbc;

import java.sql.SQLException;


public interface PoolDataSourcePropertiesSetters {

    void setUrl(String jdbcUrl) throws SQLException;
  
    void setUsername(String username) throws SQLException;
    
    void setPassword(String paramString) throws SQLException;

    void setType(String paramString);
}
