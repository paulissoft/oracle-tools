package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.util.Properties;
import java.util.Hashtable;
import java.io.PrintWriter;
import javax.naming.Name;
import javax.naming.Reference;
import javax.naming.Context;
// import java.util.logging.Logger;
    
import java.sql.SQLException;
import lombok.extern.slf4j.Slf4j;
import oracle.ucp.ConnectionAffinityCallback;
import oracle.ucp.ConnectionLabelingCallback;
import oracle.ucp.UniversalConnectionPool;
import oracle.ucp.UniversalConnectionPoolException;
import oracle.ucp.admin.UniversalConnectionPoolManager;
import oracle.ucp.admin.UniversalConnectionPoolManagerImpl;
import oracle.ucp.jdbc.ConnectionInitializationCallback;
import oracle.ucp.jdbc.JDBCConnectionPoolStatistics;
import oracle.ucp.jdbc.PoolDataSourceImpl;
import oracle.ucp.jdbc.UCPConnectionBuilder;
    
@Slf4j
public class SimplePoolDataSourceOracle
    extends PoolDataSourceImpl
    implements SimplePoolDataSource, PoolDataSourcePropertiesSettersOracle, PoolDataSourcePropertiesGettersOracle {

    private static final long serialVersionUID = 3886083682048526889L;
    
    private final StringBuffer id = new StringBuffer();

    protected static final UniversalConnectionPoolManager mgr;

    static {
        try {
            mgr = UniversalConnectionPoolManagerImpl.getUniversalConnectionPoolManager();
        } catch (UniversalConnectionPoolException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }
    
    public void setId(final String srcId) {
        SimplePoolDataSource.setId(id, String.format("0x%08x", hashCode()), srcId);
    }

    public String getId() {
        return id.toString();
    }

    public void set(final PoolDataSourceConfiguration pdsConfig) {
        set((PoolDataSourceConfigurationOracle)pdsConfig);
    }
    
    private void set(final PoolDataSourceConfigurationOracle pdsConfig) {
        log.debug(">set(pdsConfig={})", pdsConfig);

        int nr = 0;
        final int maxNr = 17;
        
        do {
            try {
                /* this.driverClassName is ignored */
                switch(nr) {
                case  0: setURL(pdsConfig.getUrl()); break;
                case  1: setUser(pdsConfig.getUsername()); break;
                case  2: setPassword(pdsConfig.getPassword()); break;
                case  3: setConnectionPoolName(pdsConfig.getConnectionPoolName()); break;
                case  4: setInitialPoolSize(pdsConfig.getInitialPoolSize()); break;
                case  5: setMinPoolSize(pdsConfig.getMinPoolSize()); break;
                case  6: setMaxPoolSize(pdsConfig.getMaxPoolSize()); break;
                case  7: setConnectionFactoryClassName(pdsConfig.getConnectionFactoryClassName()); break;
                case  8: setValidateConnectionOnBorrow(pdsConfig.getValidateConnectionOnBorrow()); break;
                case  9: setAbandonedConnectionTimeout(pdsConfig.getAbandonedConnectionTimeout()); break;
                case 10: setTimeToLiveConnectionTimeout(pdsConfig.getTimeToLiveConnectionTimeout()); break;
                case 11: setInactiveConnectionTimeout(pdsConfig.getInactiveConnectionTimeout()); break;
                case 12: setTimeoutCheckInterval(pdsConfig.getTimeoutCheckInterval()); break;
                case 13: setMaxStatements(pdsConfig.getMaxStatements()); break;
                case 14: setConnectionWaitTimeout(pdsConfig.getConnectionWaitTimeout()); break;
                case 15: setMaxConnectionReuseTime(pdsConfig.getMaxConnectionReuseTime()); break;
                case 16: setSecondsToTrustIdleConnection(pdsConfig.getSecondsToTrustIdleConnection()); break;
                case 17: setConnectionValidationTimeout(pdsConfig.getConnectionValidationTimeout()); break;
                default:
                    throw new IllegalArgumentException(String.format("Wrong value for nr (%d): must be between 0 and %d", nr, maxNr));
                }
            } catch (Exception ex) {
                log.warn("nr: {}; exception: {}", nr, SimplePoolDataSource.exceptionToString(ex));
            }
        } while (++nr <= maxNr);

        log.debug("<set()");
    }
   
    public PoolDataSourceConfiguration get() {
        return get(true);
    }
    
    public PoolDataSourceConfiguration get(final boolean excludeNonIdConfiguration) {
        return PoolDataSourceConfigurationOracle
            .builder()
            .driverClassName(null)
            .url(getURL())
            .username(getUsername())
            .password(excludeNonIdConfiguration ? null : getPassword())
            .type(SimplePoolDataSourceOracle.class.getName())
            .connectionPoolName(excludeNonIdConfiguration ? null : getConnectionPoolName())
            .initialPoolSize(getInitialPoolSize())
            .minPoolSize(getMinPoolSize())
            .maxPoolSize(getMaxPoolSize())
            .connectionFactoryClassName(getConnectionFactoryClassName())
            .validateConnectionOnBorrow(getValidateConnectionOnBorrow())
            .abandonedConnectionTimeout(getAbandonedConnectionTimeout())
            .timeToLiveConnectionTimeout(getTimeToLiveConnectionTimeout())
            .inactiveConnectionTimeout(getInactiveConnectionTimeout())
            .timeoutCheckInterval(getTimeoutCheckInterval())
            .maxStatements(getMaxStatements())
            .connectionWaitTimeout(getConnectionWaitTimeout())
            .maxConnectionReuseTime(getMaxConnectionReuseTime())
            .secondsToTrustIdleConnection(getSecondsToTrustIdleConnection())
            .connectionValidationTimeout(getConnectionValidationTimeout())
            .build();
    }
    
    public void show(final PoolDataSourceConfiguration pdsConfig) {
        show((PoolDataSourceConfigurationOracle)pdsConfig);
    }
    
    private void show(final PoolDataSourceConfigurationOracle pdsConfig) {
        final String indentPrefix = PoolDataSourceStatistics.INDENT_PREFIX;

        /* Smart Pool Data Source */

        log.info("Properties for smart pool connecting to schema {} via {}", pdsConfig.getSchema(), pdsConfig.getUsernameToConnectTo());

        /* info from PoolDataSourceConfiguration */
        log.info("{}url: {}", indentPrefix, pdsConfig.getUrl());
        log.info("{}username: {}", indentPrefix, pdsConfig.getUsername());
        // do not log passwords
        log.info("{}type: {}", indentPrefix, pdsConfig.getType());
        /* info from PoolDataSourceConfigurationOracle */
        log.info("{}initialPoolSize: {}", indentPrefix, pdsConfig.getInitialPoolSize());
        log.info("{}minPoolSize: {}", indentPrefix, pdsConfig.getMinPoolSize());
        log.info("{}maxPoolSize: {}", indentPrefix, pdsConfig.getMaxPoolSize());
        log.info("{}connectionFactoryClassName: {}", indentPrefix, pdsConfig.getConnectionFactoryClassName());
        log.info("{}validateConnectionOnBorrow: {}", indentPrefix, pdsConfig.getValidateConnectionOnBorrow());
        log.info("{}abandonedConnectionTimeout: {}", indentPrefix, pdsConfig.getAbandonedConnectionTimeout());
        log.info("{}timeToLiveConnectionTimeout: {}", indentPrefix, pdsConfig.getTimeToLiveConnectionTimeout()); 
        log.info("{}inactiveConnectionTimeout: {}", indentPrefix, pdsConfig.getInactiveConnectionTimeout());
        log.info("{}timeoutCheckInterval: {}", indentPrefix, pdsConfig.getTimeoutCheckInterval());
        log.info("{}maxStatements: {}", indentPrefix, pdsConfig.getMaxStatements());
        log.info("{}connectionWaitTimeout: {}", indentPrefix, pdsConfig.getConnectionWaitTimeout());
        log.info("{}maxConnectionReuseTime: {}", indentPrefix, pdsConfig.getMaxConnectionReuseTime());
        log.info("{}secondsToTrustIdleConnection: {}", indentPrefix, pdsConfig.getSecondsToTrustIdleConnection());
        log.info("{}connectionValidationTimeout: {}", indentPrefix, pdsConfig.getConnectionValidationTimeout());

        /* Common Simple Pool Data Source */

        log.info("Properties for common simple pool: {}", getConnectionPoolName());

        /* info from PoolDataSourceConfiguration */
        log.info("{}url: {}", indentPrefix, getURL());
        log.info("{}username: {}", indentPrefix, getUser());
        // do not log passwords
        /* info from PoolDataSourceConfigurationOracle */
        log.info("{}initialPoolSize: {}", indentPrefix, getInitialPoolSize());
        log.info("{}minPoolSize: {}", indentPrefix, getMinPoolSize());
        log.info("{}maxPoolSize: {}", indentPrefix, getMaxPoolSize());
        log.info("{}connectionFactoryClassName: {}", indentPrefix, getConnectionFactoryClassName());
        log.info("{}validateConnectionOnBorrow: {}", indentPrefix, getValidateConnectionOnBorrow());
        log.info("{}abandonedConnectionTimeout: {}", indentPrefix, getAbandonedConnectionTimeout());
        log.info("{}timeToLiveConnectionTimeout: {}", indentPrefix, getTimeToLiveConnectionTimeout()); 
        log.info("{}inactiveConnectionTimeout: {}", indentPrefix, getInactiveConnectionTimeout());
        log.info("{}timeoutCheckInterval: {}", indentPrefix, getTimeoutCheckInterval());
        log.info("{}maxStatements: {}", indentPrefix, getMaxStatements());
        log.info("{}connectionWaitTimeout: {}", indentPrefix, getConnectionWaitTimeout());
        log.info("{}maxConnectionReuseTime: {}", indentPrefix, getMaxConnectionReuseTime());
        log.info("{}secondsToTrustIdleConnection: {}", indentPrefix, getSecondsToTrustIdleConnection());
        log.info("{}connectionValidationTimeout: {}", indentPrefix, getConnectionValidationTimeout());
    }

    /* Interface PoolDataSourcePropertiesSettersOracle */

    public void setUrl(String url) throws SQLException {
        setURL(url);
    }

    public void setType(String paramString) {
    }

    /* Interface PoolDataSourcePropertiesGettersOracle */
    
    public String getUrl() {
        return getURL();
    }

    public void setPoolName(String poolName) throws SQLException {
        setConnectionPoolName(poolName);
    }

    public String getPoolName() {
        return getConnectionPoolName();
    }

    public void setUsername(String username) throws SQLException {
        setUser(username);
    }

    public String getUsername() {
        return getUser();
    }

    // public void setPassword(String password) throws SQLException;
    
    @SuppressWarnings("deprecation")
    @Override
    public String getPassword() {
        return super.getPassword();
    }

    // public int getInitialPoolSize();

    // public int getMinPoolSize();

    // public int getMaxPoolSize();

    @SuppressWarnings("deprecation")
    public long getConnectionTimeout() { // milliseconds
        return getConnectionWaitTimeout() * 1000;
    }

    public int getActiveConnections() {
        return getBorrowedConnectionsCount();
    }

    public int getIdleConnections() {
        return getAvailableConnectionsCount();
    }

    public int getTotalConnections() {
        return getActiveConnections() + getIdleConnections();
    }

    public void close() {
        try {
            log.info("About to close connection pool {}", getConnectionPoolName());
            
            // this pool may or may NOT be in the connection pools (implicitly) managed by mgr
            UniversalConnectionPool ucp;

            try {
                ucp = mgr.getConnectionPool(getConnectionPoolName());
            } catch (Exception ex) {
                ucp = null;
            }

            if (ucp != null) {
                ucp.stop();
                // mgr.destroyConnectionPool(getConnectionPoolName()); // will generate a UCP-45 later on
            }
        } catch (UniversalConnectionPoolException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }
    
    /*
    @Override
    public boolean equals(Object obj) {
        if (obj == null || !(obj instanceof SimplePoolDataSourceOracle)) {
            return false;
        }

        final SimplePoolDataSourceOracle other = (SimplePoolDataSourceOracle) obj;
        
        return other.getPoolDataSourceConfiguration().equals(this.getPoolDataSourceConfiguration());
    }

    @Override
    public int hashCode() {
        return this.getPoolDataSourceConfiguration().hashCode();
    }

    @Override
    public String toString() {
        return this.getPoolDataSourceConfiguration().toString();
    }
    */

    /**/
    /* Class PoolDataSourceImpl */

    @Override
    public UCPConnectionBuilder createConnectionBuilder() {
        final UCPConnectionBuilder result = super.createConnectionBuilder();
        log.trace("createConnectionBuilder() = {}", result);
        return result;
    }

    @Override
    protected void createPoolWithDefaultProperties() throws SQLException {
        log.trace("createPoolWithDefaultProperties()");
        super.createPoolWithDefaultProperties();
    }

    @Override
    public int getAbandonedConnectionTimeout() {
        final int result = super.getAbandonedConnectionTimeout();
        log.trace("getAbandonedConnectionTimeout() = {}", result);
        return result;
    }

    @Override
    public int getAvailableConnectionsCount() {
        final int result = super.getAvailableConnectionsCount();
        log.trace("getAvailableConnectionsCount() = {}", result);
        return result;
    }

    @Override
    public int getBorrowedConnectionsCount() {
        final int result = super.getBorrowedConnectionsCount();
        log.trace("getBorrowedConnectionsCount() = {}", result);
        return result;
    }

    @Override
    public Connection getConnection() throws SQLException {
        final Connection result = super.getConnection();
        log.trace("getConnection() = {}", result);
        return result;
    }

    @Override
    public Connection getConnection(Properties labels) throws SQLException {
        final Connection result = super.getConnection(labels);
        log.trace("getConnection(labels) = {}", result);
        return result;
    }

    @Override
    public Connection getConnection(String username, String password) throws SQLException {
        final Connection result = super.getConnection(username, password);
        log.trace("getConnection(username, password) = {}", result);
        return result;
    }

    @Override
    public Connection getConnection(String username, String password, Properties labels) throws SQLException {
        final Connection result = super.getConnection(username, password, labels);
        log.trace("getConnection(username, password, labels) = {}", result);
        return result;
    }

    @Override
    public String getConnectionFactoryClassName() {
        final String result = super.getConnectionFactoryClassName();
        log.trace("getConnectionFactoryClassName() = {}", result);
        return result;
    }

    @Override
    public Properties getConnectionFactoryProperties() {
        final Properties result = super.getConnectionFactoryProperties();
        log.trace("getConnectionFactoryProperties() = {}", result);
        return result;
    }

    @Override
    public String getConnectionFactoryProperty(String propertyName) {
        final String result = super.getConnectionFactoryProperty(propertyName);
        log.trace("getConnectionFactoryProperty(propertyName) = {}", result);
        return result;
    }

    @Override
    public int getConnectionHarvestMaxCount() {
        final int result = super.getConnectionHarvestMaxCount();
        log.trace("getConnectionHarvestMaxCount() = {}", result);
        return result;
    }

    @Override
    public int getConnectionHarvestTriggerCount() {
        final int result = super.getConnectionHarvestTriggerCount();
        log.trace("getConnectionHarvestTriggerCount() = {}", result);
        return result;
    }

    @Override
    public ConnectionInitializationCallback getConnectionInitializationCallback() {
        final ConnectionInitializationCallback result = super.getConnectionInitializationCallback();
        log.trace("getConnectionInitializationCallback() = {}", result);
        return result;
    }

    @Override
    public int getConnectionLabelingHighCost() {
        final int result = super.getConnectionLabelingHighCost();
        log.trace("getConnectionLabelingHighCost() = {}", result);
        return result;
    }

    @Override
    public String getConnectionPoolName() {
        final String result = super.getConnectionPoolName();
        log.debug("getConnectionPoolName() = {}", result);
        return result;
    }

    @Override
    public Properties getConnectionProperties() {
        final Properties result = super.getConnectionProperties();
        log.trace("getConnectionProperties() = {}", result);
        return result;
    }

    @Override
    public String getConnectionProperty(String propertyName) {
        final String result = super.getConnectionProperty(propertyName);
        log.trace("getConnectionProperty(propertyName) = {}", result);
        return result;
    }

    @Override
    public int getConnectionRepurposeThreshold() {
        final int result = super.getConnectionRepurposeThreshold();
        log.trace("getConnectionRepurposeThreshold() = {}", result);
        return result;
    }

    @Override
    public int getConnectionValidationTimeout() {
        final int result = super.getConnectionValidationTimeout();
        log.trace("getConnectionValidationTimeout() = {}", result);
        return result;
    }

    @Override
    public int getConnectionWaitTimeout() {
        final int result = super.getConnectionWaitTimeout();
        log.trace("getConnectionWaitTimeout() = {}", result);
        return result;
    }

    @Override
    public String getDatabaseName() {
        final String result = super.getDatabaseName();
        log.trace("getDatabaseName() = {}", result);
        return result;
    }

    @Override
    public String getDataSourceName() {
        final String result = super.getDataSourceName();
        log.trace("getDataSourceName() = {}", result);
        return result;
    }

    @Override
    public String getDescription() {
        final String result = super.getDescription();
        log.trace("getDescription() = {}", result);
        return result;
    }

    @Override
    public boolean getFastConnectionFailoverEnabled() {
        final boolean result = super.getFastConnectionFailoverEnabled();
        log.trace("getFastConnectionFailoverEnabled() = {}", result);
        return result;
    }

    @Override
    public int getHighCostConnectionReuseThreshold() {
        final int result = super.getHighCostConnectionReuseThreshold();
        log.trace("getHighCostConnectionReuseThreshold() = {}", result);
        return result;
    }

    @Override
    public int getInactiveConnectionTimeout() {
        final int result = super.getInactiveConnectionTimeout();
        log.trace("getInactiveConnectionTimeout() = {}", result);
        return result;
    }

    @Override
    public int getInitialPoolSize() {
        final int result = super.getInitialPoolSize();
        log.trace("getInitialPoolSize() = {}", result);
        return result;
    }

    @Override
    public int getLoginTimeout() {
        final int result = super.getLoginTimeout();
        log.trace("getLoginTimeout() = {}", result);
        return result;
    }

    @Override
    public PrintWriter getLogWriter() throws SQLException {
        final PrintWriter result = super.getLogWriter();
        log.trace("getLogWriter() = {}", result);
        return result;
    }

    @Override
    public int getMaxConnectionReuseCount() {
        final int result = super.getMaxConnectionReuseCount();
        log.trace("getMaxConnectionReuseCount() = {}", result);
        return result;
    }

    @Override
    public long getMaxConnectionReuseTime() {
        final long result = super.getMaxConnectionReuseTime();
        log.trace("getMaxConnectionReuseTime() = {}", result);
        return result;
    }

    @Override
    public int getMaxConnectionsPerService() {
        final int result = super.getMaxConnectionsPerService();
        log.trace("getMaxConnectionsPerService() = {}", result);
        return result;
    }

    @Override
    public int getMaxConnectionsPerShard() {
        final int result = super.getMaxConnectionsPerShard();
        log.trace("getMaxConnectionsPerShard() = {}", result);
        return result;
    }

    @Override
    public int getMaxIdleTime() {
        final int result = super.getMaxIdleTime();
        log.trace("getMaxIdleTime() = {}", result);
        return result;
    }

    @Override
    public int getMaxPoolSize() {
        final int result = super.getMaxPoolSize();
        log.trace("getMaxPoolSize() = {}", result);
        return result;
    }

    @Override
    public int getMaxStatements() {
        final int result = super.getMaxStatements();
        log.trace("getMaxStatements() = {}", result);
        return result;
    }

    @Override
    public int getMinPoolSize() {
        final int result = super.getMinPoolSize();
        log.trace("getMinPoolSize() = {}", result);
        return result;
    }

    @Override
    public String getNetworkProtocol() {
        final String result = super.getNetworkProtocol();
        log.trace("getNetworkProtocol() = {}", result);
        return result;
    }

    @Override
    public Object getObjectInstance(Object refObj,
                                    Name name,
                                    Context nameCtx,
                                    Hashtable<?,?> env) throws Exception {
        final Object result = super.getObjectInstance(refObj, name, nameCtx, env);
        log.trace("getObjectInstance(refObj, name, nameCtx, env) = {}", result);
        return result;
    }

    @Override
    public java.util.logging.Logger getParentLogger() {
        final java.util.logging.Logger result = super.getParentLogger();
        log.trace("getParentLogger() = {}", result);
        return result;
    }

    @Override
    public Properties getPdbRoles() {
        final Properties result = super.getPdbRoles();
        log.trace("getPdbRoles() = {}", result);
        return result;
    }

    @Override
    public int getPortNumber() {
        final int result = super.getPortNumber();
        log.trace("getPortNumber() = {}", result);
        return result;
    }

    @Override
    public int getPropertyCycle() {
        final int result = super.getPropertyCycle();
        log.trace("getPropertyCycle() = {}", result);
        return result;
    }

    @Override
    public int getQueryTimeout() {
        final int result = super.getQueryTimeout();
        log.trace("getQueryTimeout() = {}", result);
        return result;
    }

    @Override
    public Reference getReference() {
        final Reference result = super.getReference();
        log.trace("getReference() = {}", result);
        return result;
    }

    @Override
    public String getRoleName() {
        final String result = super.getRoleName();
        log.trace("getRoleName() = {}", result);
        return result;
    }

    @Override
    public int getSecondsToTrustIdleConnection() {
        final int result = super.getSecondsToTrustIdleConnection();
        log.trace("getSecondsToTrustIdleConnection() = {}", result);
        return result;
    }

    @Override
    public String getServerName() {
        final String result = super.getServerName();
        log.trace("getServerName() = {}", result);
        return result;
    }

    @Override
    public String getServiceName() {
        final String result = super.getServiceName();
        log.trace("getServiceName() = {}", result);
        return result;
    }

    @Override
    public boolean getShardingMode() {
        final boolean result = super.getShardingMode();
        log.trace("getShardingMode() = {}", result);
        return result;
    }

    @Override
    public String getSQLForValidateConnection() {
        final String result = super.getSQLForValidateConnection();
        log.trace("getSQLForValidateConnection() = {}", result);
        return result;
    }

    @Override
    protected javax.net.ssl.SSLContext getSSLContext() {
        final javax.net.ssl.SSLContext result = super.getSSLContext();
        log.trace("getSSLContext()");
        return result;
    }

    @Override
    public JDBCConnectionPoolStatistics getStatistics() {
        log.trace("getStatistics()");
        return super.getStatistics();
    }

    @Override
    public int getTimeoutCheckInterval() {
        log.trace("getTimeoutCheckInterval()");
        return super.getTimeoutCheckInterval();
    }

    @Override
    public int getTimeToLiveConnectionTimeout() {
        log.trace("getTimeToLiveConnectionTimeout()");
        return super.getTimeToLiveConnectionTimeout();
    }

    @Override
    public String getURL() {
        log.trace("getURL()");
        return super.getURL();
    }

    @Override
    public String getUser() {
        log.trace("getUser()");
        return super.getUser();
    }

    @Override
    public boolean getValidateConnectionOnBorrow() {
        log.trace("getValidateConnectionOnBorrow()");
        return super.getValidateConnectionOnBorrow();
    }

    @Override
    public boolean isReadOnlyInstanceAllowed() {
        final boolean result = super.isReadOnlyInstanceAllowed();
        log.trace("isReadOnlyInstanceAllowed() = {}", result);
        return result;
    }

    public static boolean isSetOnceProperty(String key) {
        return PoolDataSourceImpl.isSetOnceProperty(key);
    }

    @Override
    public boolean isWrapperFor(Class<?> iface) throws SQLException {
        final boolean result = super.isWrapperFor(iface);
        log.trace("isWrapperFor(iface) = {}", result);
        return result;
    }

    @Override
    public void reconfigureDataSource(Properties configuration) throws SQLException {
        log.trace("reconfigureDataSource(configuration)");
        super.reconfigureDataSource(configuration);
    }

    @Override
    public void registerConnectionAffinityCallback(ConnectionAffinityCallback cbk) throws SQLException {
        log.trace("registerConnectionAffinityCallback(cbk)");
        super.registerConnectionAffinityCallback(cbk);
    }

    @Override
    public void registerConnectionInitializationCallback(ConnectionInitializationCallback cbk) throws SQLException {
        log.trace("registerConnectionInitializationCallback(cbk)");
        super.registerConnectionInitializationCallback(cbk);
    }

    @Override
    public void registerConnectionLabelingCallback(ConnectionLabelingCallback cbk) throws SQLException {
        log.trace("registerConnectionLabelingCallback(cbk)");
        super.registerConnectionLabelingCallback(cbk);
    }

    @Override
    public void removeConnectionAffinityCallback() throws SQLException {
        log.trace("removeConnectionAffinityCallback()");
        super.removeConnectionAffinityCallback();
    }

    @Override
    public void removeConnectionLabelingCallback() throws SQLException {
        log.trace("removeConnectionLabelingCallback()");
        super.removeConnectionLabelingCallback();
    }

    @Override
    public void setAbandonedConnectionTimeout(int abandonedConnectionTimeout) throws SQLException {
        log.trace("setAbandonedConnectionTimeout({})", abandonedConnectionTimeout);
        super.setAbandonedConnectionTimeout(abandonedConnectionTimeout);
    }

    @Override
    public void setConnectionFactoryClassName(String factoryClassName) throws SQLException {
        log.trace("setConnectionFactoryClassName({})", factoryClassName);
        super.setConnectionFactoryClassName(factoryClassName);
    }

    @Override
    public void setConnectionFactoryProperties(Properties factoryProperties) throws SQLException {
        log.trace("setConnectionFactoryProperties({})", factoryProperties);
        super.setConnectionFactoryProperties(factoryProperties);
    }

    @Override
    public void setConnectionFactoryProperty(String name, String value) throws SQLException {
        log.trace("setConnectionFactoryProperty({}, {})", name, value);
        super.setConnectionFactoryProperty(name, value);
    }

    @Override
    public void setConnectionHarvestMaxCount(int connectionHarvestMaxCount) throws SQLException {
        log.trace("setConnectionHarvestMaxCount({})", connectionHarvestMaxCount);
        super.setConnectionHarvestMaxCount(connectionHarvestMaxCount);
    }

    @Override
    public void setConnectionHarvestTriggerCount(int connectionHarvestTriggerCount) throws SQLException {
        log.trace("setConnectionHarvestTriggerCount({})", connectionHarvestTriggerCount);
        super.setConnectionHarvestTriggerCount(connectionHarvestTriggerCount);
    }

    @Override
    public void setConnectionLabelingHighCost(int highCost) throws SQLException {
        log.trace("setConnectionLabelingHighCost()", highCost);
        super.setConnectionLabelingHighCost(highCost);
    }

    @Override
    public void setConnectionPoolName(String connectionPoolName) throws SQLException {
        log.debug("setConnectionPoolName({})", connectionPoolName);
        super.setConnectionPoolName(connectionPoolName);
    }

    @Override
    public void setConnectionProperties(Properties connectionProperties) throws SQLException {
        log.trace("setConnectionProperties({})", connectionProperties);
        super.setConnectionProperties(connectionProperties);
    }

    @Override
    public void setConnectionProperty(String name, String value) throws SQLException {
        log.trace("setConnectionProperty({}, {})", name, value);
        super.setConnectionProperty(name, value);
    }

    @Override
    public void setConnectionRepurposeThreshold(int threshold) throws SQLException {
        log.trace("setConnectionRepurposeThreshold({})", threshold);
        super.setConnectionRepurposeThreshold(threshold);
    }

    @Override
    public void setConnectionValidationTimeout(int connectionValidationTimeout) throws SQLException {
        log.trace("setConnectionValidationTimeout({})", connectionValidationTimeout);
        super.setConnectionValidationTimeout(connectionValidationTimeout);
    }

    @Override
    public void setConnectionWaitTimeout(int waitTimeout) throws SQLException {
        log.trace("setConnectionWaitTimeout({})", waitTimeout);
        super.setConnectionWaitTimeout(waitTimeout);
    }

    @Override
    public void setDatabaseName(String databaseName) throws SQLException {
        log.trace("setDatabaseName({})", databaseName);
        super.setDatabaseName(databaseName);
    }

    @Override
    public void setDataSourceName(String dataSourceName) throws SQLException {
        log.trace("setDataSourceName({})", dataSourceName);
        super.setDataSourceName(dataSourceName);
    }

    @Override
    public void setDescription(String dataSourceDescription) throws SQLException {
        log.trace("setDescription({})", dataSourceDescription);
        super.setDescription(dataSourceDescription);
    }

    @Override
    public void setFastConnectionFailoverEnabled(boolean failoverEnabled) throws SQLException {
        log.trace("setFastConnectionFailoverEnabled({})", failoverEnabled);
        super.setFastConnectionFailoverEnabled(failoverEnabled);
    }

    @Override
    public void setHighCostConnectionReuseThreshold(int threshold) throws SQLException {
        log.trace("setHighCostConnectionReuseThreshold({})", threshold);
        super.setHighCostConnectionReuseThreshold(threshold);
    }

    @Override
    public void setInactiveConnectionTimeout(int inactivityTimeout) throws SQLException {
        log.trace("setInactiveConnectionTimeout({})", inactivityTimeout);
        super.setInactiveConnectionTimeout(inactivityTimeout);
    }

    @Override
    public void setInitialPoolSize(int initialPoolSize) throws SQLException {
        log.trace("setInitialPoolSize({})", initialPoolSize);
        super.setInitialPoolSize(initialPoolSize);
    }

    @Override
    public void setLoginTimeout(int seconds) throws SQLException {
        log.trace("setLoginTimeout({})", seconds);
        super.setLoginTimeout(seconds);
    }

    @Override
    public void setLogWriter(PrintWriter logWriter) throws SQLException {
        log.trace("setLogWriter({})", logWriter);
        super.setLogWriter(logWriter);
    }

    @Override
    public void setMaxConnectionReuseCount(int maxConnectionReuseCount) throws SQLException {
        log.trace("setMaxConnectionReuseCount({})", maxConnectionReuseCount);
        super.setMaxConnectionReuseCount(maxConnectionReuseCount);
    }

    @Override
    public void setMaxConnectionReuseTime(long maxConnectionReuseTime) throws SQLException {
        log.trace("setMaxConnectionReuseTime({})", maxConnectionReuseTime);
        super.setMaxConnectionReuseTime(maxConnectionReuseTime);
    }

    @Override
    public void setMaxConnectionsPerShard(int maxConnectionsPerShard) throws SQLException {
        log.trace("setMaxConnectionsPerShard({})", maxConnectionsPerShard);
        super.setMaxConnectionsPerShard(maxConnectionsPerShard);
    }

    @Override
    public void setMaxIdleTime(int idleTime) throws SQLException {
        log.trace("setMaxIdleTime({})", idleTime);
        super.setMaxIdleTime(idleTime);
    }

    @Override
    public void setMaxPoolSize(int maxPoolSize) throws SQLException {
        log.trace("setMaxPoolSize({})", maxPoolSize);
        super.setMaxPoolSize(maxPoolSize);
    }

    @Override
    public void setMaxStatements(int maxStatements) throws SQLException {
        log.trace("setMaxStatements({})", maxStatements);
        super.setMaxStatements(maxStatements);
    }

    @Override
    public void setMinPoolSize(int minPoolSize) throws SQLException {
        log.trace("setMinPoolSize({})", minPoolSize);
        super.setMinPoolSize(minPoolSize);
    }

    @Override
    public void setNetworkProtocol(String networkProtocol) throws SQLException {
        log.trace("setNetworkProtocol({})", networkProtocol);
        super.setNetworkProtocol(networkProtocol);
    }

    @Override
    public void setONSConfiguration(String onsConfigStr) {
        log.trace("setONSConfiguration({})", onsConfigStr);
        super.setONSConfiguration(onsConfigStr);
    }

    @Override
    public void setPassword(String password) throws SQLException {
        super.setPassword(password);
    }

    @Override
    public void setPortNumber(int portNumber) throws SQLException {
        log.trace("setPortNumber({})", portNumber);
        super.setPortNumber(portNumber);
    }

    @Override
    public void setPropertyCycle(int propertyCycle) throws SQLException {
        log.trace("setPropertyCycle({})", propertyCycle);
        super.setPropertyCycle(propertyCycle);
    }

    @Override
    public void setQueryTimeout(int queryTimeout) throws SQLException {
        log.trace("setQueryTimeout({})", queryTimeout);
        super.setQueryTimeout(queryTimeout);
    }

    @Override
    public void setReadOnlyInstanceAllowed(boolean readOnlyInstanceAllowed) throws SQLException {
        log.trace("setReadOnlyInstanceAllowed({})", readOnlyInstanceAllowed);
        super.setReadOnlyInstanceAllowed(readOnlyInstanceAllowed);
    }

    @Override
    public void setRoleName(String roleName) throws SQLException {
        log.trace("setRoleName({})", roleName);
        super.setRoleName(roleName);
    }

    @Override
    public void setSecondsToTrustIdleConnection(int secondsToTrustIdleConnection) throws SQLException {
        log.trace("setSecondsToTrustIdleConnection({})", secondsToTrustIdleConnection);
        super.setSecondsToTrustIdleConnection(secondsToTrustIdleConnection);
    }

    @Override
    public void setServerName(String serverName) throws SQLException {
        log.trace("setServerName({})", serverName);
        super.setServerName(serverName);
    }

    @Override
    public void setShardingMode(boolean shardingMode) throws SQLException {
        log.trace("setShardingMode({})", shardingMode);
        super.setShardingMode(shardingMode);
    }

    @Override
    public void setSQLForValidateConnection(String SQLString) throws SQLException {
        log.trace("setSQLForValidateConnection({})", SQLString);
        super.setSQLForValidateConnection(SQLString);
    }

    @Override
    public void setSSLContext(javax.net.ssl.SSLContext sslContext) {
        log.trace("setSSLContext({})", sslContext);
        super.setSSLContext(sslContext);
    }

    @Override
    public void setTimeoutCheckInterval(int timeInterval) throws SQLException {
        log.trace("setTimeoutCheckInterval({})", timeInterval);
        super.setTimeoutCheckInterval(timeInterval);
    }

    @Override
    public void setTimeToLiveConnectionTimeout(int timeToLiveConnectionTimeout) throws SQLException {
        log.trace("setTimeToLiveConnectionTimeout({})", timeToLiveConnectionTimeout);
        super.setTimeToLiveConnectionTimeout(timeToLiveConnectionTimeout);
    }

    @Override
    public void setURL(String url) throws SQLException {
        log.trace("setURL({})", url);
        super.setURL(url);
    }

    @Override
    public void setUser(String username) throws SQLException {
        log.trace("setUser({})", username);
        super.setUser(username);
    }

    @Override
    public void setValidateConnectionOnBorrow(boolean validateConnectionOnBorrow) throws SQLException {
        log.trace("setValidateConnectionOnBorrow({})", validateConnectionOnBorrow);
        super.setValidateConnectionOnBorrow(validateConnectionOnBorrow);
    }

    @Override
    public void startPool() throws SQLException {
        log.debug("startPool({})", getConnectionPoolName());
        super.startPool();
    }
}
