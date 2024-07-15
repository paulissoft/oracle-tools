package com.paulissoft.pato.jdbc;

import java.io.Closeable;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.concurrent.atomic.AtomicBoolean;
import javax.sql.DataSource;


public interface SimplePoolDataSource extends DataSource, Closeable {

    // for all pool data sources the same
    AtomicBoolean statisticsEnabled = new AtomicBoolean(true);

    static boolean isStatisticsEnabled() {
        return statisticsEnabled.get();
    }

    static void setStatisticsEnabled(final boolean isStatisticsEnabled) {
        statisticsEnabled.set(isStatisticsEnabled);
    }

    static String exceptionToString(final Exception ex) {
        return String.format("%s: %s", ex.getClass().getName(), ex.getMessage());
    }

    String getPoolNamePrefix();
    
    static void setId(final StringBuffer dstId, final String id, final String srcId) {
        dstId.delete(0, dstId.length());
        dstId.append(id);
        dstId.append(" (");
        dstId.append(srcId != null && !srcId.isEmpty() ? srcId : "UNKNOWN");
        dstId.append(")");
    }

    void setId(final String srcId);

    String getId();

    void set(final PoolDataSourceConfiguration pdsConfig);

    PoolDataSourceConfiguration getWithPoolName();

    PoolDataSourceConfiguration get();

    boolean isClosed();

    void show(final PoolDataSourceConfiguration pdsConfig);
    
    // signatures used by com.zaxxer.hikari.HikariDataSource
    void setPoolName(String poolName) throws SQLException;

    String getPoolName();

    String getUrl();
    
    // signatures used by com.zaxxer.hikari.HikariDataSource
    void setUsername(String username) throws SQLException;

    String getUsername();

    // signatures used by com.zaxxer.hikari.HikariDataSource / oracle.ucp.jdbc.PoolDataSource
    void setPassword(String password) throws SQLException;

    String getPassword();

    // signatures used by oracle.ucp.jdbc.PoolDataSource
    int getInitialPoolSize();

    void setInitialPoolSize(int initialPoolSize) /*throws SQLException*/;

    int getMinPoolSize();

    void setMinPoolSize(int minPoolSize) /*throws SQLException*/;

    int getMaxPoolSize();

    void setMaxPoolSize(int maxPoolSize) /*throws SQLException*/;

    long getConnectionTimeout(); // milliseconds
    
    void setConnectionTimeout(long connectionTimeout) throws SQLException; // milliseconds

    // connection statistics    
    int getActiveConnections();

    int getIdleConnections();

    int getTotalConnections();

    long getMinConnectionTimeout();

    boolean isInitializing();

    Connection getConnection(final String usernameToConnectTo,
                             final String password,
                             final String schema,
                             final int refCount) throws SQLException;
}
