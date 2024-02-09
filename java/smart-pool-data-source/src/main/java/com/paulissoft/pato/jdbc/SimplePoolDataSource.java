package com.paulissoft.pato.jdbc;

import java.io.Closeable;
import javax.sql.DataSource;
import java.sql.SQLException;


public interface SimplePoolDataSource extends DataSource, Closeable {

    public String getPoolName();

    public void setPoolName(String poolName) throws SQLException;

    public void setUsername(String username) throws SQLException;

    public void setPassword(String password) throws SQLException;
        
    public int getInitialPoolSize();

    public void setInitialPoolSize(int initialPoolSize) throws SQLException;

    public int getMinimumPoolSize();

    public void setMinimumPoolSize(int minimumPoolSize) throws SQLException;

    public int getMaximumPoolSize();

    public void setMaximumPoolSize(int maximumPoolSize) throws SQLException;

    public long getConnectionTimeout(); // milliseconds

    // connection statistics
    
    public int getActiveConnections();

    public int getIdleConnections();

    public int getTotalConnections();        
}
