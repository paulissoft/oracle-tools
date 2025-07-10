package com.paulissoft.pato.jdbc;

import oracle.ucp.jdbc.PoolDataSourceImpl;


// a package accessible class
class SharedPoolDataSourceOracle extends SharedPoolDataSource<PoolDataSourceImpl> {
    private static final String USERNAMES_ERROR = "Not all usernames are the same and not null: %s.";

    private static final String DATA_SOURCE_CLASS_NAMES_ERROR = "Not all data source class names are the same: %s.";

    // constructor
    SharedPoolDataSourceOracle() {
        super(new PoolDataSourceImpl());
    }

    void setPassword(String password) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setPassword() while initializing.");
        }
        try {
            ds.setPassword(password);
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
    
    void setUsername(String username) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setUser() while initializing.");
        }
        try {
            ds.setUser(username);
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    void configure() {
        /*
        //  String getURL();
        //
        //  String getUser();
        //
        //  String getConnectionPoolName();
        //
        //  String getConnectionFactoryClassName();
        //
        //  boolean getValidateConnectionOnBorrow();
        //
        //  int getAbandonedConnectionTimeout();
        //
        //  int getTimeToLiveConnectionTimeout();
        //
        //  int getInactiveConnectionTimeout();
        //
        //  int getTimeoutCheckInterval();
        //
        //  int getMaxStatements();
        //
        //  long getConnectionWaitDurationInMillis();
        //
        //  long getMaxConnectionReuseTime();
        //
        //  int getSecondsToTrustIdleConnection();
        //
        //  int getConnectionValidationTimeout();
        //

        int     getAbandonedConnectionTimeout()
Gets the abandoned connection timeout value.
int     getAvailableConnectionsCount()
Gets the number of available connections in the pool.
int     getBorrowedConnectionsCount()
Gets the number of borrowed connections from the pool.
java.sql.Connection     getConnection()
Attempts to obtain a database connection.
java.sql.Connection     getConnection(java.util.Properties labels)
Attempts to obtain a database connection with the requested connection labels.
java.sql.Connection     getConnection(java.lang.String username, java.lang.String password)
Attempts to obtain a database connection.
java.sql.Connection     getConnection(java.lang.String username, java.lang.String password, java.util.Properties labels)
Attempts to obtain a database connection with the requested connection labels.
java.lang.String        getConnectionFactoryClassName()
Gets the Connection Factory class name.
java.util.Properties    getConnectionFactoryProperties()
Gets the connection factory properties that are set on this data source.
java.lang.String        getConnectionFactoryProperty(java.lang.String propertyName)
Gets the specified connection factory property that are set on this data source.
int     getConnectionHarvestMaxCount()
Gets the maximum number of connections that may be harvested when the connection harvesting occurs.
int     getConnectionHarvestTriggerCount()
Gets the number of available connections at which the connection pool's connection harvesting will occur.
ConnectionInitializationCallback        getConnectionInitializationCallback()
Obtains the registered connection initialization callback, if any.
int     getConnectionLabelingHighCost()
Obtains the cost value which identifies a connection as "high-cost" for connection labeling.
java.lang.String        getConnectionPoolName()
Gets the connection pool name.
java.util.Properties    getConnectionProperties()
Gets the connection properties that are set on this data source.
java.lang.String        getConnectionProperty(java.lang.String propertyName)
Gets the specified connection property that are set on this data source.
int     getConnectionRepurposeThreshold()
Gets the connection repurpose threshold for the pool.
int     getConnectionWaitTimeout()
Gets the amount of time to wait (in seconds) for a used connection to be released by a client.
java.lang.String        getDatabaseName()
Gets the database name.
java.lang.String        getDataSourceName()
Gets the data source name.
java.lang.String        getDescription()
Gets the data source description.
boolean getFastConnectionFailoverEnabled()
Checks if Fast Connection Failover is enabled.
int     getHighCostConnectionReuseThreshold()
Obtains the high-cost connection reuse threshold property value for connection labeling.
int     getInactiveConnectionTimeout()
Gets the inactive connection timeout.
int     getInitialPoolSize()
Gets the initial pool size.
int     getLoginTimeout()
Gets the default maximum time in seconds that a driver will wait while attempting to connect to a database once the driver has been identified.
java.io.PrintWriter     getLogWriter() 
int     getMaxConnectionReuseCount()
Gets the connection reuse count property.
long    getMaxConnectionReuseTime()
Gets the connection reuse time property.
int     getMaxConnectionsPerService()
Gets the maximum number of connections that can be obtained to a particular service, in a shared pool.
int     getMaxConnectionsPerShard()
Gets the currently configured max connections that can be created per shard in a sharded database configuration.
int     getMaxIdleTime()
Gets Idle timeout value.
int     getMaxPoolSize()
Gets the maximum number of connections that the connection pool will maintain.
int     getMaxStatements()
Gets the maximum number of statements that may be pooled or cached on a Connection.
int     getMinPoolSize()
Gets the minimum number of connections that the connection pool will maintain.
java.lang.String        getNetworkProtocol()
Gets the datasource networkProtocol.
java.lang.Object        getObjectInstance(java.lang.Object refObj, javax.naming.Name name, javax.naming.Context nameCtx, java.util.Hashtable env) 
java.lang.String        getONSConfiguration()
Returns the ONS configuration string that is used for remote ONS subscription, in the form specified in setONSConfiguration(String).
java.util.logging.Logger        getParentLogger() 
java.lang.String        getPassword()
Gets the Password for this data source.
java.util.Properties    getPdbRoles()
Gets the PDB roles specified for this datasource
int     getPortNumber()
Gets the database port number.
int     getPropertyCycle()
Gets Property cycle in seconds.
int     getQueryTimeout()
Gets the number of seconds the driver will wait for a Statement object to execute to the given number of seconds.
javax.naming.Reference  getReference() 
java.lang.String        getRoleName()
Gets the datasource role name.
int     getSecondsToTrustIdleConnection()
Gets the seconds To Trust Idle Connection value.
java.lang.String        getServerName()
Gets the database server name.
java.lang.String        getServiceName()
Gets the service name set on this data source
java.lang.String        getSQLForValidateConnection()
Gets the Value for SQLForValidateConnection property.
JDBCConnectionPoolStatistics    getStatistics()
Gets the statistics of the connection pool.
int     getTimeoutCheckInterval()
Gets the timeout check interval (in seconds).
int     getTimeToLiveConnectionTimeout()
Gets the maximum time (in seconds) a connection may remain in-use.
java.lang.String        getURL()
Gets the URL for this data source.
java.lang.String        getUser()
Gets the user name for this data source.
boolean getValidateConnectionOnBorrow()
Returns whether or not a connection being borrowed should first be validated.

        */  
        super.configure();

        try {
            ds.setInitialPoolSize(members.stream().mapToInt(PoolDataSourceImpl::getInitialPoolSize).sum());
            ds.setMinPoolSize(members.stream().mapToInt(PoolDataSourceImpl::getMinPoolSize).sum());
            ds.setMaxPoolSize(members.stream().mapToInt(PoolDataSourceImpl::getMaxPoolSize).sum());

            // properties that may NOT differ, i.e. must be common

        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    void close() {
        synchronized(this) {
            state = State.CLOSED;
        }
    }
}    
