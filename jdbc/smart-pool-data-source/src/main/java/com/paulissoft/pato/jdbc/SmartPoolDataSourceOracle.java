package com.paulissoft.pato.jdbc;

import java.io.Closeable;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.util.logging.Logger;
import java.util.Properties;
import oracle.ucp.jdbc.PoolDataSourceImpl;


public class SmartPoolDataSourceOracle extends PoolDataSourceImpl implements ConnectInfo, Closeable {

    private static final long serialVersionUID = 1L;
        
    // this delegate will do the actual work
    private static final SharedPoolDataSourceOracle delegate = new SharedPoolDataSourceOracle();
    
    private volatile String currentSchema = null;

    /*
    // overridden methods from PoolDataSourceImpl
    */
    
    @Override
    public Connection getConnection() throws SQLException {
        return delegate.getConnection();
    }

    @Override
    public Connection getConnection(Properties labels) throws SQLException {
        try {
            throw new SQLFeatureNotSupportedException("getConnection");            
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public Connection getConnection(String username, String password) throws SQLException {
        return delegate.getConnection(username, password);
    }

    @Override
    public Connection getConnection(String username, String password, Properties labels) throws SQLException {
        try {
            throw new SQLFeatureNotSupportedException("getConnection");            
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
    
    @Override
    public PrintWriter getLogWriter() throws SQLException {
        return delegate.getLogWriter();
    }

    @Override
    public void setLogWriter(PrintWriter out) throws SQLException {
        delegate.setLogWriter(out);
    }

    @Override
    public Logger getParentLogger() {
        try {
            return delegate.getParentLogger();
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public <T> T unwrap(Class<T> iface) throws SQLException {
        return delegate.unwrap(iface);
    }

    @Override
    public boolean isWrapperFor(Class<?> iface) throws SQLException {
        return delegate.isWrapperFor(iface);
    }

    @Override
    public String getSQLForValidateConnection() {
        return getSQLAlterSessionSetCurrentSchema();
    }

    @Override
    public void setSQLForValidateConnection(String SQLstring) {
        try {
            // since getSQLForValidateConnection is overridden it does not make sense to set it
            throw new SQLFeatureNotSupportedException("setSQLForValidateConnection");            
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
    
    @Override
    public void setPassword(String password) throws SQLException {
        // Here we will set both the super and the delegate password so that the overridden getConnection() will always use
        // the same password no matter where it comes from.

        super.setPassword(password);
        delegate.setPassword(password);
    }

    @Override
    public void setValidateConnectionOnBorrow(boolean validateConnectionOnBorrow) throws SQLException {
        try {
            if (!validateConnectionOnBorrow) {
                throw new SQLFeatureNotSupportedException("setValidateConnectionOnBorrow(false)");            
            }
            super.setValidateConnectionOnBorrow(validateConnectionOnBorrow);
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
        
    @Override
    public void setUser(String username) throws SQLException {
        // Here we will set both the super and the delegate username so that the overridden getConnection() will always use
        // the same password no matter where it comes from.
        var connectInfo = determineProxyUsernameAndCurrentDSchema(username);
        
        synchronized(this) {
            currentSchema = connectInfo[1];
        }

        setValidateConnectionOnBorrow(true); // must be used in combination with setSQLForValidateConnection()
            
        super.setUser(connectInfo[0] != null ? connectInfo[0] : connectInfo[1]);
        delegate.setUsername(connectInfo[0] != null ? connectInfo[0] : connectInfo[1]);

        // Add this object here (setUsername() should always be called) and
        // not in the constructor to prevent a this escape warning in the constructor.
        delegate.add(this);
    }

    /*
    // Interface ConnectInfo
    */
    public String getCurrentSchema() {
        return currentSchema;
    }

    /*
    // Interface Closeable
    */
    public void close() {
        delegate.remove(this);
    }

    // extra
    
    public boolean isClosed() {
        return !delegate.contains(this);
    }

}

/*

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.sql.Connection;
import java.sql.ConnectionBuilder;
import java.sql.SQLException;
import java.sql.ShardingKeyBuilder;
import java.time.Duration;
import java.util.Properties;
import java.util.function.Consumer;
import java.util.function.Supplier;
import javax.net.ssl.SSLContext;
import javax.sql.DataSource;
import oracle.jdbc.AccessToken;
import oracle.jdbc.OracleShardingKeyBuilder;
import oracle.ucp.ConnectionAffinityCallback;
import oracle.ucp.ConnectionCreationInformation;
import oracle.ucp.ConnectionLabelingCallback;
import oracle.ucp.diagnostics.Diagnosable;

public interface PoolDataSource extends DataSource, Diagnosable {
  public static final String SYSTEM_PROPERTY_AFFINITY_STRICT = "oracle.ucp.jdbc.oracle.affinity.strict";
  
  public static final String SYSTEM_PROPERTY_MAX_INIT_THREADS = "oracle.ucp.MaxInitThreads";
  
  public static final String SYSTEM_PROPERTY_PRE_WLS1212_COMPATIBLE = "oracle.ucp.PreWLS1212Compatible";
  
  public static final String SYSTEM_PROPERTY_CONNECTION_CREATION_RETRY_DELAY = "oracle.ucp.ConnectionCreationRetryDelay";
  
  public static final String SYSTEM_PROPERTY_FAN_ENABLED = "oracle.jdbc.fanEnabled";
  
  public static final String SYSTEM_PROPERTY_BEGIN_REQUEST_AT_CONNECTION_CREATION = "oracle.jdbc.beginRequestAtConnectionCreation";
  
  public static final String SYSTEM_PROPERTY_XML_CONFIG_FILE = "oracle.ucp.jdbc.xmlConfigFile";
  
  public static final String SYSTEM_PROPERTY_DESTROY_ON_RELOAD = "oracle.ucp.destroyOnReload";
  
  public static final String SYSTEM_PROPERTY_IMITATE_ASYNC_BORROW = "oracle.ucp.imitateAsyncBorrow";
  
  public static final String SYSTEM_PROPERTY_SELFTUNING = "oracle.ucp.selftuning";
  
  public static final String SYSTEM_PROPERTY_WLS_JTA = "oracle.ucp.wls.jta";
  
  public static final String SYSTEM_PROPERTY_TIMERS_AFFECT_ALL_CONNECTIONS = "oracle.ucp.timersAffectAllConnections";
  
  public static final String SYSTEM_PROPERTY_DIAGNOSTIC_ENABLE_TRACE = "oracle.ucp.diagnostic.enableTrace";
  
  public static final String SYSTEM_PROPERTY_DIAGNOSTIC_ENABLE_LOGGING = "oracle.ucp.diagnostic.enableLogging";
  
  public static final String SYSTEM_PROPERTY_DIAGNOSTIC_BUFFER_SIZE = "oracle.ucp.diagnostic.bufferSize";
  
  public static final String SYSTEM_PROPERTY_DIAGNOSTIC_LOGGING_LEVEL = "oracle.ucp.diagnostic.loggingLevel";
  
  public static final String SYSTEM_PROPERTY_DIAGNOSTIC_ERROR_CODES_TO_WATCH_LIST = "oracle.ucp.diagnostic.errorCodesToWatchList";
  
  public static final String SYSTEM_PROPERTY_ENABLE_SHUTDOWN_HOOK = "oracle.ucp.enableShutdownHook";
  
  public static final String SYSTEM_PROPERTY_RLB_INOPERABILITY_TIMEOUT = "oracle.ucp.RLBInoperabilityTimeout";
  
  public static final String UCP_USER = "user";
  
  public static final String UCP_URL = "url";
  
  public static final String UCP_PASSWORD = "password";
  
  public static final String UCP_SERVER_NAME = "serverName";
  
  public static final String UCP_PORT_NUMBER = "portNumber";
  
  public static final String UCP_DATABASE_NAME = "databaseName";
  
  public static final String UCP_DATA_SOURCE_NAME = "dataSourceName";
  
  public static final String UCP_DESCRIPTION = "description";
  
  public static final String UCP_NETWORK_PROTOCOL = "networkProtocol";
  
  public static final String UCP_ROLE_NAME = "roleName";
  
  public static final String UCP_CONNECTION_FACTORY_CLASS_NAME = "connectionFactoryClassName";
  
  public static final String UCP_CONNECTION_PROPERTIES = "connectionProperties";
  
  public static final String UCP_CONNECTION_FACTORY_PROPERTIES = "connectionFactoryProperties";
  
  public static final String UCP_VALIDATE_CONNECTION_ON_BORROW = "validateConnectionOnBorrow";
  
  public static final String UCP_SQL_FOR_VALIDATE_CONNECTION = "sqlForValidateConnection";
  
  public static final String UCP_CONNECTION_POOL_NAME = "connectionPoolName";
  
  public static final String UCP_INITIAL_POOL_SIZE = "initialPoolSize";
  
  public static final String UCP_MIN_POOL_SIZE = "minPoolSize";
  
  public static final String UCP_MAX_POOL_SIZE = "maxPoolSize";
  
  public static final String UCP_NTH_RETURNED_CONNECTION_TO_VALIDATE = "nthReturnedConnectionToValidate";
  
  public static final String UCP_ABANDONED_CONNECTION_TIMEOUT = "abandonedConnectionTimeout";
  
  public static final String UCP_TIME_TO_LIVE_CONNECTION_TIMEOUT = "timeToLiveConnectionTimeout";
  
  public static final String UCP_INACTIVE_CONNECTION_TIMEOUT = "inactiveConnectionTimeout";
  
  public static final String UCP_MAX_IDLE_TIME = "maxIdleTime";
  
  public static final String UCP_TIMEOUT_CHECK_INTERVAL = "timeoutCheckInterval";
  
  public static final String UCP_PROPERTY_CYCLE = "propertyCycle";
  
  public static final String UCP_MAX_STATEMENTS = "maxStatements";
  
  public static final String UCP_CONNECTION_WAIT_TIMEOUT = "connectionWaitTimeout";
  
  public static final String UCP_CONNECTION_WAIT_DURATION = "connectionWaitDuration";
  
  public static final String UCP_MAX_CONNECTION_REUSE_TIME = "maxConnectionReuseTime";
  
  public static final String UCP_MAX_CONNECTION_REUSE_COUNT = "maxConnectionReuseCount";
  
  public static final String UCP_CONNECTION_HARVEST_TRIGGER_COUNT = "connectionHarvestTriggerCount";
  
  public static final String UCP_CONNECTION_HARVEST_MAX_COUNT = "connectionHarvestMaxCount";
  
  public static final String UCP_FAST_CONNECTION_FAILOVER_ENABLED = "fastConnectionFailoverEnabled";
  
  public static final String UCP_ONS_CONFIGURATION = "onsConfiguration";
  
  public static final String UCP_SECONDS_TO_TRUST_IDLE_CONNECTION = "secondsToTrustIdleConnection";
  
  public static final String UCP_MAX_CONNECTIONS_PER_SERVICE = "maxConnectionsPerService";
  
  public static final String UCP_LOGIN_TIMEOUT = "loginTimeout";
  
  public static final String UCP_SERVICE_NAME = "serviceName";
  
  public static final String UCP_PDB_ROLES = "pdbRoles";
  
  public static final String UCP_CONNECTION_AFFINITY_CALLBACK = "connectionAffinityCallback";
  
  public static final String UCP_CONNECTION_INITIALIZATION_CALLBACK = "connectionInitializationCallback";
  
  public static final String UCP_CONNECTION_CREATION_CONSUMER = "connectionCreationConsumer";
  
  public static final String UCP_CONNECTION_LABELING_CALLBACK = "connectionLabelingCallback";
  
  public static final String UCP_CONNECTION_LABELING_HIGH_COST = "connectionLabelingHighCost";
  
  public static final String UCP_CONNECTION_REPURPOSE_THRESHOLD = "connectionRepurposeThreshold";
  
  public static final String UCP_HIGH_COST_CONNECTION_REUSE_THRESHOLD = "highCostConnectionReuseThreshold";
  
  public static final String UCP_DATA_SOURCE_FROM_CONFIGURATION = "dataSourceFromConfiguration";
  
  public static final String UCP_MAX_CONNECTIONS_PER_SHARD = "maxConnectionsPerShard";
  
  public static final String UCP_SHARDING_MODE = "shardingMode";
  
  public static final String UCP_CONNECTION_VALIDATION_TIMEOUT = "connectionValidationTimeout";
  
  public static final String UCP_READONLY_INSTANCE_ALLOWED = "readOnlyInstanceAllowed";
  
  @Deprecated
  default String getPassword() {
    throw new NoSuchMethodError("this method is deprecated");
  }
  
  default void registerConnectionCreationConsumer(Consumer<ConnectionCreationInformation> consumer) {
    throw new NoSuchMethodError("Method not defined");
  }
  
  default void unregisterConnectionCreationConsumer() {
    throw new NoSuchMethodError("Method not defined");
  }
  
  default Consumer<ConnectionCreationInformation> getConnectionCreationConsumer() {
    throw new NoSuchMethodError("Method is not defined");
  }
  
  default OracleShardingKeyBuilder createShardingKeyBuilder() {
    return OracleShardingKeyBuilderFactory.create();
  }
  
  int getInitialPoolSize();
  
  void setInitialPoolSize(int paramInt) throws SQLException;
  
  int getMinPoolSize();
  
  void setMinPoolSize(int paramInt) throws SQLException;
  
  int getMaxPoolSize();
  
  void setMaxPoolSize(int paramInt) throws SQLException;
  
  int getInactiveConnectionTimeout();
  
  void setInactiveConnectionTimeout(int paramInt) throws SQLException;
  
  int getAbandonedConnectionTimeout();
  
  void setAbandonedConnectionTimeout(int paramInt) throws SQLException;
  
  @Deprecated
  int getConnectionWaitTimeout();
  
  Duration getConnectionWaitDuration();
  
  @Deprecated
  void setConnectionWaitTimeout(int paramInt) throws SQLException;
  
  void setConnectionWaitDuration(Duration paramDuration) throws SQLException;
  
  int getTimeToLiveConnectionTimeout();
  
  void setTimeToLiveConnectionTimeout(int paramInt) throws SQLException;
  
  void setTimeoutCheckInterval(int paramInt) throws SQLException;
  
  int getTimeoutCheckInterval();
  
  void setFastConnectionFailoverEnabled(boolean paramBoolean) throws SQLException;
  
  boolean getFastConnectionFailoverEnabled();
  
  String getConnectionFactoryClassName();
  
  void setConnectionFactoryClassName(String paramString) throws SQLException;
  
  void setMaxStatements(int paramInt) throws SQLException;
  
  int getMaxStatements();
  
  void setMaxIdleTime(int paramInt) throws SQLException;
  
  int getMaxIdleTime();
  
  void setPropertyCycle(int paramInt) throws SQLException;
  
  int getPropertyCycle();
  
  void setConnectionPoolName(String paramString) throws SQLException;
  
  String getConnectionPoolName();
  
  void setURL(String paramString) throws SQLException;
  
  String getURL();
  
  void setUser(String paramString) throws SQLException;
  
  String getUser();
  
  void setPassword(String paramString) throws SQLException;
  
  void setServerName(String paramString) throws SQLException;
  
  String getServerName();
  
  void setPortNumber(int paramInt) throws SQLException;
  
  int getPortNumber();
  
  void setDatabaseName(String paramString) throws SQLException;
  
  String getDatabaseName();
  
  void setDataSourceName(String paramString) throws SQLException;
  
  String getDataSourceName();
  
  void setDescription(String paramString) throws SQLException;
  
  String getDescription();
  
  void setNetworkProtocol(String paramString) throws SQLException;
  
  String getNetworkProtocol();
  
  void setRoleName(String paramString) throws SQLException;
  
  String getRoleName();
  
  void setValidateConnectionOnBorrow(boolean paramBoolean) throws SQLException;
  
  boolean getValidateConnectionOnBorrow();
  
  void setSQLForValidateConnection(String paramString) throws SQLException;
  
  String getSQLForValidateConnection();
  
  int getConnectionHarvestTriggerCount();
  
  void setConnectionHarvestTriggerCount(int paramInt) throws SQLException;
  
  int getConnectionHarvestMaxCount();
  
  void setConnectionHarvestMaxCount(int paramInt) throws SQLException;
  
  int getAvailableConnectionsCount() throws SQLException;
  
  int getBorrowedConnectionsCount() throws SQLException;
  
  String getONSConfiguration() throws SQLException;
  
  void setONSConfiguration(String paramString) throws SQLException;
  
  Connection getConnection(Properties paramProperties) throws SQLException;
  
  Connection getConnection(String paramString1, String paramString2, Properties paramProperties) throws SQLException;
  
  void registerConnectionLabelingCallback(ConnectionLabelingCallback paramConnectionLabelingCallback) throws SQLException;
  
  void removeConnectionLabelingCallback() throws SQLException;
  
  void registerConnectionAffinityCallback(ConnectionAffinityCallback paramConnectionAffinityCallback) throws SQLException;
  
  void removeConnectionAffinityCallback() throws SQLException;
  
  Properties getConnectionProperties();
  
  String getConnectionProperty(String paramString);
  
  void setConnectionProperty(String paramString1, String paramString2) throws SQLException;
  
  void setConnectionProperties(Properties paramProperties) throws SQLException;
  
  Properties getConnectionFactoryProperties();
  
  String getConnectionFactoryProperty(String paramString);
  
  void setConnectionFactoryProperty(String paramString1, String paramString2) throws SQLException;
  
  void setConnectionFactoryProperties(Properties paramProperties) throws SQLException;
  
  long getMaxConnectionReuseTime();
  
  void setMaxConnectionReuseTime(long paramLong) throws SQLException;
  
  int getMaxConnectionReuseCount();
  
  void setMaxConnectionReuseCount(int paramInt) throws SQLException;
  
  JDBCConnectionPoolStatistics getStatistics();
  
  void registerConnectionInitializationCallback(ConnectionInitializationCallback paramConnectionInitializationCallback) throws SQLException;
  
  void unregisterConnectionInitializationCallback() throws SQLException;
  
  ConnectionInitializationCallback getConnectionInitializationCallback();
  
  int getConnectionLabelingHighCost();
  
  void setConnectionLabelingHighCost(int paramInt) throws SQLException;
  
  int getHighCostConnectionReuseThreshold();
  
  void setHighCostConnectionReuseThreshold(int paramInt) throws SQLException;
  
  UCPConnectionBuilder createConnectionBuilder();
  
  int getConnectionRepurposeThreshold();
  
  void setConnectionRepurposeThreshold(int paramInt) throws SQLException;
  
  Properties getPdbRoles();
  
  String getServiceName();
  
  int getSecondsToTrustIdleConnection();
  
  void setSecondsToTrustIdleConnection(int paramInt) throws SQLException;
  
  void reconfigureDataSource(Properties paramProperties) throws SQLException;
  
  int getMaxConnectionsPerService();
  
  int getQueryTimeout();
  
  void setQueryTimeout(int paramInt) throws SQLException;
  
  int getMaxConnectionsPerShard();
  
  void setMaxConnectionsPerShard(int paramInt) throws SQLException;
  
  void setShardingMode(boolean paramBoolean) throws SQLException;
  
  boolean getShardingMode();
  
  void setConnectionValidationTimeout(int paramInt) throws SQLException;
  
  int getConnectionValidationTimeout();
  
  void setSSLContext(SSLContext paramSSLContext);
  
  void setHostnameResolver(HostnameResolver paramHostnameResolver);
  
  boolean isReadOnlyInstanceAllowed();
  
  void setReadOnlyInstanceAllowed(boolean paramBoolean) throws SQLException;
  
  void setTokenSupplier(Supplier<? extends AccessToken> paramSupplier) throws SQLException;
  
  @FunctionalInterface
  public static interface HostnameResolver {
    InetAddress[] getAllByName(String param1String) throws UnknownHostException;
  }
}
*/
