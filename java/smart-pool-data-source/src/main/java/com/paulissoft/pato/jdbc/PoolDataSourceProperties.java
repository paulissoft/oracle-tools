package com.paulissoft.pato.jdbc;

import java.sql.SQLException;


public interface PoolDataSourceProperties {

    void setPassword(String paramString) throws SQLException;
    
    @Deprecated
    String getPassword();
}
