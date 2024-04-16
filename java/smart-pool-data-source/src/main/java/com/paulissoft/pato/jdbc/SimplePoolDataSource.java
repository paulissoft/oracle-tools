package com.paulissoft.pato.jdbc;

import javax.sql.DataSource;
import java.sql.SQLException;


public interface SimplePoolDataSource extends DataSource {

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
    
    // signature used by HikariDataSource
    public void setPoolName(String poolName) throws SQLException;

    public String getPoolName();

    // signatures used by HikariDataSource
    public void setUsername(String username) throws SQLException;

    public String getUsername();

    // signatures used by HikariDataSource / PoolDataSource
    public void setPassword(String password) throws SQLException;

    public String getPassword();

    // signatures used by PoolDataSource    
    public int getInitialPoolSize();

    public int getMinPoolSize();

    public int getMaxPoolSize();

    public long getConnectionTimeout(); // milliseconds

    // connection statistics    
    public int getActiveConnections();

    public int getIdleConnections();

    public int getTotalConnections();        
}
