package com.paulissoft.pato.jdbc;

import java.io.Closeable;
import javax.sql.DataSource;
import java.sql.SQLException;

public interface SimplePoolDataSource extends DataSource, Closeable {

    public PoolDataSourceConfiguration getPoolDataSourceConfiguration();

    //*TBD*/public void updatePoolSizes(final SimplePoolDataSource pds) throws SQLException;

    public String getPoolName();

    public void join(final PoolDataSourceConfiguration pdsConfiguration);
    
    //*TBD*/public void setPoolName(String poolName) throws SQLException;

    //*TBD*/public String getUrl();

    //*TBD*/public void setUrl(String url) throws SQLException;

    public String getUsername();

    public void setUsername(String username) throws SQLException;

    public String getPassword();
    
    public void setPassword(String password) throws SQLException;
        
    public int getInitialPoolSize();

    public int getMinPoolSize();

    public int getMaxPoolSize();

    public long getConnectionTimeout(); // milliseconds

    // connection statistics
    
    public int getActiveConnections();

    public int getIdleConnections();

    public int getTotalConnections();        

    public PoolDataSourceStatistics getPoolDataSourceStatistics();
}
