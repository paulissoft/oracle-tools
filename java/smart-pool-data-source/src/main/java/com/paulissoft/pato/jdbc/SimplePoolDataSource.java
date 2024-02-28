package com.paulissoft.pato.jdbc;

import java.io.Closeable;
import javax.sql.DataSource;
import java.sql.SQLException;

public interface SimplePoolDataSource extends DataSource, Closeable {

    public PoolDataSourceConfiguration getPoolDataSourceConfiguration();

    // to be invoked in SmartPoolDateSource constructor    
    public void join(final PoolDataSourceConfiguration pds);

    // to be invoked by previous one
    default public void join(final PoolDataSourceConfiguration pds, final boolean firstPds) {
        try {
            if (firstPds) {
                setPoolName(getPoolNamePrefix());
            } else {
                updatePoolSizes(pds);
            }
            setPoolName(getPoolName() + "-" + pds.getSchema());
        } catch (SQLException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    public static String exceptionToString(final Exception ex) {
        return String.format("%s: %s", ex.getClass().getName(), ex.getMessage());
    }

    // signature used by HikariDataSource
    public void setPoolName(String poolName) throws SQLException;

    public String getPoolNamePrefix();
    
    public void updatePoolSizes(final PoolDataSourceConfiguration pds) throws SQLException;

    public String getPoolName();

    //*TBD*/public String getUrl();

    //*TBD*/public void setUrl(String url) throws SQLException;

    public String getUsername();

    // signature used by HikariDataSource
    public void setUsername(String username) throws SQLException;

    public String getPassword();

    // signature used by HikariDataSource / PoolDataSource
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

    public void open(final PoolDataSourceConfiguration pds);

    public void close(final PoolDataSourceConfiguration pds);

    public boolean isClosed();

    public void show();
}
