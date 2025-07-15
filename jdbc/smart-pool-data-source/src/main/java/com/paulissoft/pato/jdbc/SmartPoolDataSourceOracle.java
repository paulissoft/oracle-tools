package com.paulissoft.pato.jdbc;

import java.io.Closeable;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.util.logging.Logger;
import java.util.Properties;
import oracle.ucp.jdbc.PoolDataSourceImpl;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;
import java.util.function.Consumer;
import javax.net.ssl.SSLContext;
import oracle.jdbc.OracleShardingKeyBuilder;
import oracle.ucp.ConnectionAffinityCallback;
import oracle.ucp.ConnectionCreationInformation;
import oracle.ucp.ConnectionLabelingCallback;

import oracle.ucp.jdbc.JDBCConnectionPoolStatistics;
import oracle.ucp.jdbc.ConnectionInitializationCallback;
import oracle.ucp.jdbc.UCPConnectionBuilder;

public class SmartPoolDataSourceOracle
    extends PoolDataSourceImpl
    implements ConnectInfo, Closeable, StatePoolDataSource, StatisticsPoolDataSource {

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
        return isInitializing() ? super.getLogWriter() : delegate.ds.getLogWriter();
    }

    @Override
    public void setLogWriter(PrintWriter out) throws SQLException {
        checkInitializing("setLogWriter");
        super.setLogWriter(out);
    }

    @Override
    public Logger getParentLogger() {
        try {
            return isInitializing() ? super.getParentLogger() : delegate.ds.getParentLogger();
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public <T> T unwrap(Class<T> iface) throws SQLException {
        return isInitializing() ? super.unwrap(iface) : delegate.ds.unwrap(iface);
    }

    @Override
    public boolean isWrapperFor(Class<?> iface) throws SQLException {
        return isInitializing() ? super.isWrapperFor(iface) : delegate.ds.isWrapperFor(iface);
    }

    @Override
    public String getSQLForValidateConnection() {
        return getSQLAlterSessionSetCurrentSchema();
    }

    @Override
    public void setSQLForValidateConnection(String SQLstring) {
        checkInitializing("setSQLForValidateConnection");
        
        try {
            // since getSQLForValidateConnection is overridden it does not make sense to set it
            throw new SQLFeatureNotSupportedException("setSQLForValidateConnection");            
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
    
    @Override
    public void setValidateConnectionOnBorrow(boolean validateConnectionOnBorrow) throws SQLException {
        checkInitializing("setValidateConnectionOnBorrow");
        
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
    public void setPassword(String password) throws SQLException {
        checkInitializing("setPassword");

        // Here we will set both the super and the delegate password so that the overridden getConnection() will always use
        // the same password no matter where it comes from.

        super.setPassword(password);
        delegate.ds.setPassword(password);
    }

    @Override
    public void setUser(String username) throws SQLException {
        checkInitializing("setUser");

        // Here we will set both the super and the delegate username so that the overridden getConnection() will always use
        // the same password no matter where it comes from.
        var connectInfo = determineProxyUsernameAndCurrentDSchema(username);
        
        synchronized(this) {
            currentSchema = connectInfo[1];
        }

        setValidateConnectionOnBorrow(true); // must be used in combination with setSQLForValidateConnection()
            
        super.setUser(connectInfo[0] != null ? connectInfo[0] : connectInfo[1]);
        delegate.ds.setUser(connectInfo[0] != null ? connectInfo[0] : connectInfo[1]);

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

    /*
    // Start of interface StatePoolDataSource
    */
    
    public boolean isInitializing() {
        return delegate.isInitializing();
    }

    public boolean hasInitializationError() {
        return delegate.hasInitializationError();
    }    
    
    public boolean isOpen() {
        return delegate.members.contains(this) && ( delegate.isOpen() || delegate.isClosing() );
    }

    public boolean isClosed() {
        return !delegate.members.contains(this) && ( delegate.isClosing() || delegate.isClosed() );
    }

    /*
    // End of interface StatePoolDataSource
    */

    /*
    // Interface StatisticsPoolDataSource
    */

    @Override
    public int getBorrowedConnectionsCount() /*throws SQLException*/ {
        return delegate.ds.getBorrowedConnectionsCount();
    }

    public int getActiveConnections() {
        return getBorrowedConnectionsCount();
    }
    
    @Override
    public int getAvailableConnectionsCount() /*throws SQLException*/ {
        return delegate.ds.getAvailableConnectionsCount();
    }

    public int getIdleConnections() {
        return getAvailableConnectionsCount();
    }
    
    /*
    // Unsupported operations
    */
    
    @Override
    public void registerConnectionCreationConsumer(Consumer<ConnectionCreationInformation> consumer) {
        try {
            throw new SQLFeatureNotSupportedException("registerConnectionCreationConsumer");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void unregisterConnectionCreationConsumer() {
        try {
            throw new SQLFeatureNotSupportedException("unregisterConnectionCreationConsumer");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public Consumer<ConnectionCreationInformation> getConnectionCreationConsumer() {
        try {
            throw new SQLFeatureNotSupportedException("ConnectionCreationInformation> getConnectionCreationConsumer");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public OracleShardingKeyBuilder createShardingKeyBuilder() {
        try {
            throw new SQLFeatureNotSupportedException("createShardingKeyBuilder");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setPropertyCycle(int paramInt) throws SQLException {
        throw new SQLFeatureNotSupportedException("setPropertyCycle");
    }

    @Override
    public int getPropertyCycle() {
        try {
            throw new SQLFeatureNotSupportedException("getPropertyCycle");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setServerName(String paramString) throws SQLException {
        throw new SQLFeatureNotSupportedException("setServerName");
    }

    @Override
    public String getServerName() {
        try {
            throw new SQLFeatureNotSupportedException("getServerName");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setPortNumber(int paramInt) throws SQLException {
        throw new SQLFeatureNotSupportedException("setPortNumber");
    }

    @Override
    public int getPortNumber() {
        try {
            throw new SQLFeatureNotSupportedException("getPortNumber");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setDatabaseName(String paramString) throws SQLException {
        throw new SQLFeatureNotSupportedException("setDatabaseName");
    }

    @Override
    public String getDatabaseName() {
        try {
            throw new SQLFeatureNotSupportedException("getDatabaseName");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setDescription(String paramString) throws SQLException {
        throw new SQLFeatureNotSupportedException("setDescription");
    }

    @Override
    public String getDescription() {
        try {
            throw new SQLFeatureNotSupportedException("getDescription");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setNetworkProtocol(String paramString) throws SQLException {
        throw new SQLFeatureNotSupportedException("setNetworkProtocol");
    }

    @Override
    public String getNetworkProtocol() {
        try {
            throw new SQLFeatureNotSupportedException("getNetworkProtocol");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setRoleName(String paramString) throws SQLException {
        throw new SQLFeatureNotSupportedException("setRoleName");
    }

    @Override
    public String getRoleName() {
        try {
            throw new SQLFeatureNotSupportedException("getRoleName");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public int getConnectionHarvestTriggerCount() {
        try {
            throw new SQLFeatureNotSupportedException("getConnectionHarvestTriggerCount");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setConnectionHarvestTriggerCount(int paramInt) throws SQLException {
        try {
            throw new SQLFeatureNotSupportedException("setConnectionHarvestTriggerCount");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public int getConnectionHarvestMaxCount() {
        try {
            throw new SQLFeatureNotSupportedException("getConnectionHarvestMaxCount");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setConnectionHarvestMaxCount(int paramInt) throws SQLException {
        throw new SQLFeatureNotSupportedException("setConnectionHarvestMaxCount");
    }

    @Override
    public void registerConnectionLabelingCallback(ConnectionLabelingCallback paramConnectionLabelingCallback) throws SQLException {
        throw new SQLFeatureNotSupportedException("registerConnectionLabelingCallback");
    }

    @Override
    public void removeConnectionLabelingCallback() throws SQLException {
        throw new SQLFeatureNotSupportedException("removeConnectionLabelingCallback");
    }

    @Override
    public void registerConnectionAffinityCallback(ConnectionAffinityCallback paramConnectionAffinityCallback) throws SQLException {
        throw new SQLFeatureNotSupportedException("registerConnectionAffinityCallback");
    }

    @Override
    public void removeConnectionAffinityCallback() throws SQLException {
        throw new SQLFeatureNotSupportedException("removeConnectionAffinityCallback");
    }

    @Override
    public Properties getConnectionProperties() {
        try {
            throw new SQLFeatureNotSupportedException("getConnectionProperties");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public String getConnectionProperty(String paramString) {
        try {
            throw new SQLFeatureNotSupportedException("getConnectionProperty");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setConnectionProperty(String paramString1, String paramString2) throws SQLException {
        throw new SQLFeatureNotSupportedException("setConnectionProperty");
    }

    @Override
    public void setConnectionProperties(Properties paramProperties) throws SQLException {
        throw new SQLFeatureNotSupportedException("setConnectionProperties");
    }

    @Override
    public Properties getConnectionFactoryProperties() {
        try {
            throw new SQLFeatureNotSupportedException("getConnectionFactoryProperties");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public String getConnectionFactoryProperty(String paramString) {
        try {
            throw new SQLFeatureNotSupportedException("getConnectionFactoryProperty");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setConnectionFactoryProperty(String paramString1, String paramString2) throws SQLException {
        throw new SQLFeatureNotSupportedException("setConnectionFactoryProperty");
    }

    @Override
    public void setConnectionFactoryProperties(Properties paramProperties) throws SQLException {
        throw new SQLFeatureNotSupportedException("setConnectionFactoryProperties");
    }

    @Override
    public JDBCConnectionPoolStatistics getStatistics() {
        try {
            throw new SQLFeatureNotSupportedException("getStatistics");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void registerConnectionInitializationCallback(ConnectionInitializationCallback paramConnectionInitializationCallback) throws SQLException {
        throw new SQLFeatureNotSupportedException("registerConnectionInitializationCallback");
    }

    @Override
    public void unregisterConnectionInitializationCallback() throws SQLException {
        throw new SQLFeatureNotSupportedException("unregisterConnectionInitializationCallback");
    }

    @Override
    public ConnectionInitializationCallback getConnectionInitializationCallback() {
        try {
            throw new SQLFeatureNotSupportedException("getConnectionInitializationCallback");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public int getConnectionLabelingHighCost() {
        try {
            throw new SQLFeatureNotSupportedException("getConnectionLabelingHighCost");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setConnectionLabelingHighCost(int paramInt) throws SQLException {
        throw new SQLFeatureNotSupportedException("setConnectionLabelingHighCost");
    }

    @Override
    public int getHighCostConnectionReuseThreshold() {
        try {
            throw new SQLFeatureNotSupportedException("getHighCostConnectionReuseThreshold");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setHighCostConnectionReuseThreshold(int paramInt) throws SQLException {
        throw new SQLFeatureNotSupportedException("setHighCostConnectionReuseThreshold");
    }

    @Override
    public UCPConnectionBuilder createConnectionBuilder() {
        try {
            throw new SQLFeatureNotSupportedException("createConnectionBuilder");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public int getConnectionRepurposeThreshold() {
        try {
            throw new SQLFeatureNotSupportedException("getConnectionRepurposeThreshold");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setConnectionRepurposeThreshold(int paramInt) throws SQLException {
        throw new SQLFeatureNotSupportedException("setConnectionRepurposeThreshold");
    }

    @Override
    public Properties getPdbRoles() {
        try {
            throw new SQLFeatureNotSupportedException("getPdbRoles");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public String getServiceName() {
        try {
            throw new SQLFeatureNotSupportedException("getServiceName");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void reconfigureDataSource(Properties paramProperties) throws SQLException {
        throw new SQLFeatureNotSupportedException("reconfigureDataSource");
    }

    @Override
    public int getMaxConnectionsPerService() {
        try {
            throw new SQLFeatureNotSupportedException("getMaxConnectionsPerService");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public int getMaxConnectionsPerShard() {
        try {
            throw new SQLFeatureNotSupportedException("getMaxConnectionsPerShard");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setMaxConnectionsPerShard(int paramInt) throws SQLException {
        throw new SQLFeatureNotSupportedException("setMaxConnectionsPerShard");
    }

    @Override
    public void setShardingMode(boolean paramBoolean) throws SQLException {
        throw new SQLFeatureNotSupportedException("setShardingMode");
    }

    @Override
    public boolean getShardingMode() {
        try {
            throw new SQLFeatureNotSupportedException("getShardingMode");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setSSLContext(SSLContext paramSSLContext) {
        try {
            throw new SQLFeatureNotSupportedException("setSSLContext");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void setHostnameResolver(HostnameResolver paramHostnameResolver) {
        try {
            throw new SQLFeatureNotSupportedException("setHostnameResolver");
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
}
