package com.paulissoft.pato.jdbc;


public interface ConnectInfo {

    // see https://docs.oracle.com/en/database/oracle/oracle-database/19/jajdb/oracle/jdbc/OracleConnection.html
    // true - do not use openProxySession() but use proxyUsername[schema]
    // false - use openProxySession() (two sessions will appear in v$session)
    public boolean isSingleSessionProxyModel();

    public boolean isFixedUsernamePassword();
}    
