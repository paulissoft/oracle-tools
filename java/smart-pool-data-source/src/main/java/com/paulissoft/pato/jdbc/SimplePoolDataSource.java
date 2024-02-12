package com.paulissoft.pato.jdbc;

import java.io.Closeable;
import javax.sql.DataSource;
import java.sql.SQLException;
import java.util.Hashtable;

public interface SimplePoolDataSource extends DataSource, Closeable {

    public static final String CLASS = "class";

    public static final String CONNECTION_FACTORY_CLASS_NAME = "connection-factory-class-name";
        
    public static final String URL = "url";

    public static final String USERNAME = "username";
    
    public static final String PASSWORD = "password";
    
    public static final String POOL_NAME = "pool-name";

    public static final String INITIAL_POOL_SIZE = "initial-pool-size";

    public static final String MIN_POOL_SIZE = "min-pool-size";

    public static final String MAX_POOL_SIZE = "max-pool-size";

    // get common pool data source proerties like the ones define above
    public Hashtable<String, Object> getProperties();

    // set common pool data source proerties like the ones define above
    public void setProperties(final Hashtable<String, Object> properties) throws SQLException;

    // public void printDataSourceStatistics();
        
    public String getPoolName();

    public void setPoolName(String poolName) throws SQLException;

    public void setUsername(String username) throws SQLException;

    public void setPassword(String password) throws SQLException;
        
    public int getInitialPoolSize();

    public void setInitialPoolSize(int initialPoolSize) throws SQLException;

    public int getMinPoolSize();

    public void setMinPoolSize(int minPoolSize) throws SQLException;

    public int getMaxPoolSize();

    public void setMaxPoolSize(int maxPoolSize) throws SQLException;

    public long getConnectionTimeout(); // milliseconds

    // connection statistics
    
    public int getActiveConnections();

    public int getIdleConnections();

    public int getTotalConnections();        
}
