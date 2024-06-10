package com.paulissoft.pato.jdbc;

import java.io.Closeable;
import java.sql.SQLException;
import javax.sql.DataSource;


public interface SimplePoolDataSource extends DataSource, Closeable {

    public static String exceptionToString(final Exception ex) {
        return String.format("%s: %s", ex.getClass().getName(), ex.getMessage());
    }

    public static void setId(final StringBuffer dstId, final String id, final String srcId) {
        dstId.delete(0, dstId.length());
        dstId.append(id);
        dstId.append(" (");
        dstId.append(srcId != null && srcId.length() > 0 ? srcId : "UNKNOWN");
        dstId.append(")");
    }

    public void setId(final String srcId);

    public String getId();

    public void set(final PoolDataSourceConfiguration pdsConfig);

    public PoolDataSourceConfiguration get();

    public void show(final PoolDataSourceConfiguration pdsConfig);
    
    // signatures used by com.zaxxer.hikari.HikariDataSource
    public void setPoolName(String poolName) throws SQLException;

    public String getPoolName();

    public String getPoolDescription();

    public String getUrl();
    
    // signatures used by com.zaxxer.hikari.HikariDataSource
    public void setUsername(String username) throws SQLException;

    public String getUsername();

    // signatures used by com.zaxxer.hikari.HikariDataSource / oracle.ucp.jdbc.PoolDataSource
    public void setPassword(String password) throws SQLException;

    public String getPassword();

    // signatures used by oracle.ucp.jdbc.PoolDataSource
    public int getInitialPoolSize();

    public void setInitialPoolSize(int initialPoolSize) throws SQLException;

    public int getMinPoolSize();

    public void setMinPoolSize(int minPoolSize) throws SQLException;

    public int getMaxPoolSize();

    public void setMaxPoolSize(int maxPoolSize) throws SQLException;

    public long getConnectionTimeout(); // milliseconds
    
    public void setConnectionTimeout(long connectionTimeout) throws SQLException; // milliseconds

    // connection statistics    
    public int getActiveConnections();

    public int getIdleConnections();

    public int getTotalConnections();        
}
