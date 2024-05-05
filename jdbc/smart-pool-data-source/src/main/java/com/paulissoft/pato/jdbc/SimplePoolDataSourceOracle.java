package com.paulissoft.pato.jdbc;

import java.sql.SQLException;
import lombok.extern.slf4j.Slf4j;
import oracle.ucp.jdbc.PoolDataSourceImpl;
//import org.openjdk.jol.vm.VM;

import oracle.ucp.ConnectionAffinityCallback;
import oracle.ucp.jdbc.*;

@Slf4j
public class SimplePoolDataSourceOracle
    extends PoolDataSourceImpl
    implements SimplePoolDataSource, PoolDataSourcePropertiesSettersOracle, PoolDataSourcePropertiesGettersOracle {

    private static final long serialVersionUID = 3886083682048526889L;
    
    private final StringBuffer id = new StringBuffer();
         
    public void setId(final String srcId) {
        SimplePoolDataSource.setId(id, String.format("0x%08x", hashCode())/*(long) System.identityHashCode(this)/*VM.current().addressOf(this)*/, srcId);
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

    /* Class PoolDataSourceImpl */

    public UCPConnectionBuilder createConnectionBuilder() {
        final UCPConnectionBuilder result = super.createConnectionBuilder();
        log.trace("createConnectionBuilder() = {}", result);
        return result;
    }

    protected void createPoolWithDefaultProperties() throws java.sql.SQLException {
        log.trace("createPoolWithDefaultProperties()");
        super.createPoolWithDefaultProperties();
    }

    public int getAbandonedConnectionTimeout() {
        final int result = super.getAbandonedConnectionTimeout();
        log.trace("getAbandonedConnectionTimeout() = {}", result);
        return result;
    }

    public int getAvailableConnectionsCount() {
        final int result = super.getAvailableConnectionsCount();
        log.trace("getAvailableConnectionsCount() = {}", result);
        return result;
    }

    public int getBorrowedConnectionsCount() {
        final int result = super.getBorrowedConnectionsCount();
        log.trace("getBorrowedConnectionsCount() = {}", result);
        return result;
    }

    public java.sql.Connection getConnection() throws java.sql.SQLException {
        final java.sql.Connection result = super.getConnection();
        log.trace("getConnection() = {}", result);
        return result;
    }

    public java.sql.Connection getConnection(java.util.Properties labels) throws java.sql.SQLException {
        final java.sql.Connection result = super.getConnection(labels);
        log.trace("getConnection(labels) = {}", result);
        return result;
    }

    public java.sql.Connection getConnection(java.lang.String username, java.lang.String password) throws java.sql.SQLException {
        final java.sql.Connection result = super.getConnection(username, password);
        log.trace("getConnection(username, password) = {}", result);
        return result;
    }

    public java.sql.Connection getConnection(java.lang.String username, java.lang.String password, java.util.Properties labels) throws java.sql.SQLException {
        final java.sql.Connection result = super.getConnection(username, password, labels);
        log.trace("getConnection(username, password, labels) = {}", result);
        return result;
    }

    public java.lang.String getConnectionFactoryClassName() {
        final java.lang.String result = super.getConnectionFactoryClassName();
        log.trace("getConnectionFactoryClassName() = {}", result);
        return result;
    }

    public java.util.Properties getConnectionFactoryProperties() {
        final java.util.Properties result = super.getConnectionFactoryProperties();
        log.trace("getConnectionFactoryProperties() = {}", result);
        return result;
    }

    public java.lang.String getConnectionFactoryProperty(java.lang.String propertyName) {
        final java.lang.String result = super.getConnectionFactoryProperty(propertyName);
        log.trace("getConnectionFactoryProperty(propertyName) = {}", result);
        return result;
    }

    public int getConnectionHarvestMaxCount() {
        final int result = super.getConnectionHarvestMaxCount();
        log.trace("getConnectionHarvestMaxCount() = {}", result);
        return result;
    }

    public int getConnectionHarvestTriggerCount() {
        final int result = super.getConnectionHarvestTriggerCount();
        log.trace("getConnectionHarvestTriggerCount() = {}", result);
        return result;
    }

    public ConnectionInitializationCallback getConnectionInitializationCallback() {
        final ConnectionInitializationCallback result = super.getConnectionInitializationCallback();
        log.trace("getConnectionInitializationCallback() = {}", result);
        return result;
    }

    public int getConnectionLabelingHighCost() {
        final int result = super.getConnectionLabelingHighCost();
        log.trace("getConnectionLabelingHighCost() = {}", result);
        return result;
    }

    public java.lang.String getConnectionPoolName() {
        final java.lang.String result = super.getConnectionPoolName();
        log.trace("getConnectionPoolName() = {}", result);
        return result;
    }

    public java.util.Properties getConnectionProperties() {
        final java.util.Properties result = super.getConnectionProperties();
        log.trace("getConnectionProperties() = {}", result);
        return result;
    }

    public java.lang.String getConnectionProperty(java.lang.String propertyName) {
        final java.lang.String result = super.getConnectionProperty(propertyName);
        log.trace("getConnectionProperty(propertyName) = {}", result);
        return result;
    }

    public int getConnectionRepurposeThreshold() {
        final int result = super.getConnectionRepurposeThreshold();
        log.trace("getConnectionRepurposeThreshold() = {}", result);
        return result;
    }

    public int getConnectionValidationTimeout() {
        final int result = super.getConnectionValidationTimeout();
        log.trace("getConnectionValidationTimeout() = {}", result);
        return result;
    }

    public int getConnectionWaitTimeout() {
        final int result = super.getConnectionWaitTimeout();
        log.trace("getConnectionWaitTimeout() = {}", result);
        return result;
    }

    public java.lang.String getDatabaseName() {
        final java.lang.String result = super.getDatabaseName();
        log.trace("getDatabaseName() = {}", result);
        return result;
    }

    public java.lang.String getDataSourceName() {
        final java.lang.String result = super.getDataSourceName();
        log.trace("getDataSourceName() = {}", result);
        return result;
    }

    public java.lang.String getDescription() {
        final java.lang.String result = super.getDescription();
        log.trace("getDescription() = {}", result);
        return result;
    }

    public boolean getFastConnectionFailoverEnabled() {
        final boolean result = super.getFastConnectionFailoverEnabled();
        log.trace("getFastConnectionFailoverEnabled() = {}", result);
        return result;
    }

    public int getHighCostConnectionReuseThreshold() {
        final int result = super.getHighCostConnectionReuseThreshold();
        log.trace("getHighCostConnectionReuseThreshold() = {}", result);
        return result;
    }

    public int getInactiveConnectionTimeout() {
        final int result = super.getInactiveConnectionTimeout();
        log.trace("getInactiveConnectionTimeout() = {}", result);
        return result;
    }

    public int getInitialPoolSize() {
        final int result = super.getInitialPoolSize();
        log.trace("getInitialPoolSize() = {}", result);
        return result;
    }

    public int getLoginTimeout() {
        final int result = super.getLoginTimeout();
        log.trace("getLoginTimeout() = {}", result);
        return result;
    }

    public java.io.PrintWriter getLogWriter() throws java.sql.SQLException {
        final java.io.PrintWriter result = super.getLogWriter();
        log.trace("getLogWriter() = {}", result);
        return result;
    }

    public int getMaxConnectionReuseCount() {
        final int result = super.getMaxConnectionReuseCount();
        log.trace("getMaxConnectionReuseCount() = {}", result);
        return result;
    }

    public long getMaxConnectionReuseTime() {
        final long result = super.getMaxConnectionReuseTime();
        log.trace("getMaxConnectionReuseTime() = {}", result);
        return result;
    }

    public int getMaxConnectionsPerService() {
        final int result = super.getMaxConnectionsPerService();
        log.trace("getMaxConnectionsPerService() = {}", result);
        return result;
    }

    public int getMaxConnectionsPerShard() {
        final int result = super.getMaxConnectionsPerShard();
        log.trace("getMaxConnectionsPerShard() = {}", result);
        return result;
    }

    public int getMaxIdleTime() {
        final int result = super.getMaxIdleTime();
        log.trace("getMaxIdleTime() = {}", result);
        return result;
    }

    public int getMaxPoolSize() {
        final int result = super.getMaxPoolSize();
        log.trace("getMaxPoolSize() = {}", result);
        return result;
    }

    public int getMaxStatements() {
        final int result = super.getMaxStatements();
        log.trace("getMaxStatements() = {}", result);
        return result;
    }

    public int getMinPoolSize() {
        final int result = super.getMinPoolSize();
        log.trace("getMinPoolSize() = {}", result);
        return result;
    }

    public java.lang.String getNetworkProtocol() {
        final java.lang.String result = super.getNetworkProtocol();
        log.trace("getNetworkProtocol() = {}", result);
        return result;
    }

    public java.lang.Object getObjectInstance(java.lang.Object refObj,
                                              javax.naming.Name name,
                                              javax.naming.Context nameCtx,
                                              java.util.Hashtable<?,?> env) throws java.lang.Exception {
        final java.lang.Object result = super.getObjectInstance(refObj, name, nameCtx, env);
        log.trace("getObjectInstance(refObj, name, nameCtx, env) = {}", result);
        return result;
    }

    public java.util.logging.Logger getParentLogger() {
        final java.util.logging.Logger result = super.getParentLogger();
        log.trace("getParentLogger() = {}", result);
        return result;
    }

    public java.util.Properties getPdbRoles() {
        final java.util.Properties result = super.getPdbRoles();
        log.trace("getPdbRoles() = {}", result);
        return result;
    }

    public int getPortNumber() {
        final int result = super.getPortNumber();
        log.trace("getPortNumber() = {}", result);
        return result;
    }

    public int getPropertyCycle() {
        final int result = super.getPropertyCycle();
        log.trace("getPropertyCycle() = {}", result);
        return result;
    }

    public int getQueryTimeout() {
        final int result = super.getQueryTimeout();
        log.trace("getQueryTimeout() = {}", result);
        return result;
    }

    public javax.naming.Reference  getReference() {
        final javax.naming.Reference  result = super.getReference();
        log.trace("getReference() = {}", result);
        return result;
    }

    public java.lang.String getRoleName() {
        final java.lang.String result = super.getRoleName();
        log.trace("getRoleName() = {}", result);
        return result;
    }

    public int getSecondsToTrustIdleConnection() {
        final int result = super.getSecondsToTrustIdleConnection();
        log.trace("getSecondsToTrustIdleConnection() = {}", result);
        return result;
    }

    public java.lang.String getServerName() {
        final java.lang.String result = super.getServerName();
        log.trace("getServerName() = {}", result);
        return result;
    }

    public java.lang.String getServiceName() {
        final java.lang.String result = super.getServiceName();
        log.trace("getServiceName() = {}", result);
        return result;
    }

    public boolean getShardingMode() {
        final boolean result = super.getShardingMode();
        log.trace("getShardingMode() = {}", result);
        return result;
    }

    public java.lang.String getSQLForValidateConnection() {
        final java.lang.String result = super.getSQLForValidateConnection();
        log.trace("getSQLForValidateConnection() = {}", result);
        return result;
    }

    protected javax.net.ssl.SSLContext getSSLContext() {
        final javax.net.ssl.SSLContext result = super.getSSLContext();
        log.trace("getSSLContext()");
        return result;
    }

    public JDBCConnectionPoolStatistics getStatistics() {
        log.trace("getStatistics()");
        return super.getStatistics();
    }

    public int getTimeoutCheckInterval() {
        log.trace("getTimeoutCheckInterval()");
        return super.getTimeoutCheckInterval();
    }

    public int getTimeToLiveConnectionTimeout() {
        log.trace("getTimeToLiveConnectionTimeout()");
        return super.getTimeToLiveConnectionTimeout();
    }

    public java.lang.String getURL() {
        log.trace("getURL()");
        return super.getURL();
    }

    public java.lang.String getUser() {
        log.trace("getUser()");
        return super.getUser();
    }

    public boolean getValidateConnectionOnBorrow() {
        log.trace("getValidateConnectionOnBorrow()");
        return super.getValidateConnectionOnBorrow();
    }

    public boolean isReadOnlyInstanceAllowed() {
        final boolean result = super.isReadOnlyInstanceAllowed();
        log.trace("isReadOnlyInstanceAllowed() = {}", result);
        return result;
    }

    public static boolean isSetOnceProperty(java.lang.String key) {
        return PoolDataSourceImpl.isSetOnceProperty(key);
    }

    public boolean isWrapperFor(java.lang.Class<?> iface) throws java.sql.SQLException {
        final boolean result = super.isWrapperFor(iface);
        log.trace("isWrapperFor(iface) = {}", result);
        return result;
    }

    public void reconfigureDataSource(java.util.Properties configuration) throws java.sql.SQLException {
        log.trace("reconfigureDataSource(configuration)");
        super.reconfigureDataSource(configuration);
    }

    public void registerConnectionAffinityCallback(ConnectionAffinityCallback cbk) throws java.sql.SQLException {
        log.trace("registerConnectionAffinityCallback(cbk)");
        super.registerConnectionAffinityCallback(cbk);
    }

    public void registerConnectionInitializationCallback(ConnectionInitializationCallback cbk) throws java.sql.SQLException {
        log.trace("registerConnectionInitializationCallback(cbk)");
        super.registerConnectionInitializationCallback(cbk);
    }

    public void registerConnectionLabelingCallback(ConnectionLabelingCallback cbk) throws java.sql.SQLException {
        log.trace("registerConnectionLabelingCallback(cbk)");
        super.registerConnectionLabelingCallback(cbk);
    }

    public void removeConnectionAffinityCallback() throws java.sql.SQLException {
        log.trace("removeConnectionAffinityCallback()");
        super.removeConnectionAffinityCallback();
    }

    public void removeConnectionLabelingCallback() throws java.sql.SQLException {
        log.trace("removeConnectionLabelingCallback()");
        super.removeConnectionLabelingCallback();
    }

    public void setAbandonedConnectionTimeout(int abandonedConnectionTimeout) throws java.sql.SQLException {
        log.trace("setAbandonedConnectionTimeout({})", abandonedConnectionTimeout);
        super.setAbandonedConnectionTimeout(abandonedConnectionTimeout);
    }

    public void setConnectionFactoryClassName(java.lang.String factoryClassName) throws java.sql.SQLException {
        log.trace("setConnectionFactoryClassName({})", factoryClassName);
        super.setConnectionFactoryClassName(factoryClassName);
    }

    public void setConnectionFactoryProperties(java.util.Properties factoryProperties) throws java.sql.SQLException {
        log.trace("setConnectionFactoryProperties({})", factoryProperties);
        super.setConnectionFactoryProperties(factoryProperties);
    }

    public void setConnectionFactoryProperty(java.lang.String name, java.lang.String value) throws java.sql.SQLException {
        log.trace("setConnectionFactoryProperty({}, {})", name, value);
        super.setConnectionFactoryProperty(name, value);
    }

    public void setConnectionHarvestMaxCount(int connectionHarvestMaxCount) throws java.sql.SQLException {
        log.trace("setConnectionHarvestMaxCount({})", connectionHarvestMaxCount);
        super.setConnectionHarvestMaxCount(connectionHarvestMaxCount);
    }

    public void setConnectionHarvestTriggerCount(int connectionHarvestTriggerCount) throws java.sql.SQLException {
        log.trace("setConnectionHarvestTriggerCount({})", connectionHarvestTriggerCount);
        super.setConnectionHarvestTriggerCount(connectionHarvestTriggerCount);
    }

    public void setConnectionLabelingHighCost(int highCost) throws java.sql.SQLException {
        log.trace("setConnectionLabelingHighCost()", highCost);
        super.setConnectionLabelingHighCost(highCost);
    }

    public void setConnectionPoolName(java.lang.String connectionPoolName) throws java.sql.SQLException {
        log.trace("setConnectionPoolName({})", connectionPoolName);
        super.setConnectionPoolName(connectionPoolName);
    }

    public void setConnectionProperties(java.util.Properties connectionProperties) throws java.sql.SQLException {
        log.trace("setConnectionProperties({})", connectionProperties);
        super.setConnectionProperties(connectionProperties);
    }

    public void setConnectionProperty(java.lang.String name, java.lang.String value) throws java.sql.SQLException {
        log.trace("setConnectionProperty({}, {})", name, value);
        super.setConnectionProperty(name, value);
    }

    public void setConnectionRepurposeThreshold(int threshold) throws java.sql.SQLException {
        log.trace("setConnectionRepurposeThreshold({})", threshold);
        super.setConnectionRepurposeThreshold(threshold);
    }

    public void setConnectionValidationTimeout(int connectionValidationTimeout) throws java.sql.SQLException {
        log.trace("setConnectionValidationTimeout({})", connectionValidationTimeout);
        super.setConnectionValidationTimeout(connectionValidationTimeout);
    }

    public void setConnectionWaitTimeout(int waitTimeout) throws java.sql.SQLException {
        log.trace("setConnectionWaitTimeout({})", waitTimeout);
        super.setConnectionWaitTimeout(waitTimeout);
    }

    public void setDatabaseName(java.lang.String databaseName) throws java.sql.SQLException {
        log.trace("setDatabaseName({})", databaseName);
        super.setDatabaseName(databaseName);
    }

    public void setDataSourceName(java.lang.String dataSourceName) throws java.sql.SQLException {
        log.trace("setDataSourceName({})", dataSourceName);
        super.setDataSourceName(dataSourceName);
    }

    public void setDescription(java.lang.String dataSourceDescription) throws java.sql.SQLException {
        log.trace("setDescription({})", dataSourceDescription);
        super.setDescription(dataSourceDescription);
    }

    public void setFastConnectionFailoverEnabled(boolean failoverEnabled) throws java.sql.SQLException {
        log.trace("setFastConnectionFailoverEnabled({})", failoverEnabled);
        super.setFastConnectionFailoverEnabled(failoverEnabled);
    }

    public void setHighCostConnectionReuseThreshold(int threshold) throws java.sql.SQLException {
        log.trace("setHighCostConnectionReuseThreshold({})", threshold);
        super.setHighCostConnectionReuseThreshold(threshold);
    }

    public void setInactiveConnectionTimeout(int inactivityTimeout) throws java.sql.SQLException {
        log.trace("setInactiveConnectionTimeout({})", inactivityTimeout);
        super.setInactiveConnectionTimeout(inactivityTimeout);
    }

    public void setInitialPoolSize(int initialPoolSize) throws java.sql.SQLException {
        log.trace("setInitialPoolSize({})", initialPoolSize);
        super.setInitialPoolSize(initialPoolSize);
    }

    public void setLoginTimeout(int seconds) throws java.sql.SQLException {
        log.trace("setLoginTimeout({})", seconds);
        super.setLoginTimeout(seconds);
    }

    public void setLogWriter(java.io.PrintWriter logWriter) throws java.sql.SQLException {
        log.trace("setLogWriter({})", logWriter);
        super.setLogWriter(logWriter);
    }

    public void setMaxConnectionReuseCount(int maxConnectionReuseCount) throws java.sql.SQLException {
        log.trace("setMaxConnectionReuseCount({})", maxConnectionReuseCount);
        super.setMaxConnectionReuseCount(maxConnectionReuseCount);
    }

    public void setMaxConnectionReuseTime(long maxConnectionReuseTime) throws java.sql.SQLException {
        log.trace("setMaxConnectionReuseTime({})", maxConnectionReuseTime);
        super.setMaxConnectionReuseTime(maxConnectionReuseTime);
    }

    public void setMaxConnectionsPerShard(int maxConnectionsPerShard) throws java.sql.SQLException {
        log.trace("setMaxConnectionsPerShard({})", maxConnectionsPerShard);
        super.setMaxConnectionsPerShard(maxConnectionsPerShard);
    }

    public void setMaxIdleTime(int idleTime) throws java.sql.SQLException {
        log.trace("setMaxIdleTime({})", idleTime);
        super.setMaxIdleTime(idleTime);
    }

    public void setMaxPoolSize(int maxPoolSize) throws java.sql.SQLException {
        log.trace("setMaxPoolSize({})", maxPoolSize);
        super.setMaxPoolSize(maxPoolSize);
    }

    public void setMaxStatements(int maxStatements) throws java.sql.SQLException {
        log.trace("setMaxStatements({})", maxStatements);
        super.setMaxStatements(maxStatements);
    }

    public void setMinPoolSize(int minPoolSize) throws java.sql.SQLException {
        log.trace("setMinPoolSize({})", minPoolSize);
        super.setMinPoolSize(minPoolSize);
    }

    public void setNetworkProtocol(java.lang.String networkProtocol) throws java.sql.SQLException {
        log.trace("setNetworkProtocol({})", networkProtocol);
        super.setNetworkProtocol(networkProtocol);
    }

    public void setONSConfiguration(java.lang.String onsConfigStr) {
        log.trace("setONSConfiguration({})", onsConfigStr);
        super.setONSConfiguration(onsConfigStr);
    }

    public void setPassword(java.lang.String password) throws java.sql.SQLException {
        log.trace("setPassword({})", password);
        super.setPassword(password);
    }

    public void setPortNumber(int portNumber) throws java.sql.SQLException {
        log.trace("setPortNumber({})", portNumber);
        super.setPortNumber(portNumber);
    }

    public void setPropertyCycle(int propertyCycle) throws java.sql.SQLException {
        log.trace("setPropertyCycle({})", propertyCycle);
        super.setPropertyCycle(propertyCycle);
    }

    public void setQueryTimeout(int queryTimeout) throws java.sql.SQLException {
        log.trace("setQueryTimeout({})", queryTimeout);
        super.setQueryTimeout(queryTimeout);
    }

    public void setReadOnlyInstanceAllowed(boolean readOnlyInstanceAllowed) throws java.sql.SQLException {
        log.trace("setReadOnlyInstanceAllowed({})", readOnlyInstanceAllowed);
        super.setReadOnlyInstanceAllowed(readOnlyInstanceAllowed);
    }

    public void setRoleName(java.lang.String roleName) throws java.sql.SQLException {
        log.trace("setRoleName({})", roleName);
        super.setRoleName(roleName);
    }

    public void setSecondsToTrustIdleConnection(int secondsToTrustIdleConnection) throws java.sql.SQLException {
        log.trace("setSecondsToTrustIdleConnection({})", secondsToTrustIdleConnection);
        super.setSecondsToTrustIdleConnection(secondsToTrustIdleConnection);
    }

    public void setServerName(java.lang.String serverName) throws java.sql.SQLException {
        log.trace("setServerName({})", serverName);
        super.setServerName(serverName);
    }

    public void setShardingMode(boolean shardingMode) throws java.sql.SQLException {
        log.trace("setShardingMode({})", shardingMode);
        super.setShardingMode(shardingMode);
    }

    public void setSQLForValidateConnection(java.lang.String SQLString) throws java.sql.SQLException {
        log.trace("setSQLForValidateConnection({})", SQLString);
        super.setSQLForValidateConnection(SQLString);
    }

    public void setSSLContext(javax.net.ssl.SSLContext sslContext) {
        log.trace("setSSLContext({})", sslContext);
        super.setSSLContext(sslContext);
    }

    public void setTimeoutCheckInterval(int timeInterval) throws java.sql.SQLException {
        log.trace("setTimeoutCheckInterval({})", timeInterval);
        super.setTimeoutCheckInterval(timeInterval);
    }

    public void setTimeToLiveConnectionTimeout(int timeToLiveConnectionTimeout) throws java.sql.SQLException {
        log.trace("setTimeToLiveConnectionTimeout({})", timeToLiveConnectionTimeout);
        super.setTimeToLiveConnectionTimeout(timeToLiveConnectionTimeout);
    }

    public void setURL(java.lang.String url) throws java.sql.SQLException {
        log.trace("setURL({})", url);
        super.setURL(url);
    }

    public void setUser(java.lang.String username) throws java.sql.SQLException {
        log.trace("setUser({})", username);
        super.setUser(username);
    }

    public void setValidateConnectionOnBorrow(boolean validateConnectionOnBorrow) throws java.sql.SQLException {
        log.trace("setValidateConnectionOnBorrow({})", validateConnectionOnBorrow);
        super.setValidateConnectionOnBorrow(validateConnectionOnBorrow);
    }

    public void startPool() throws java.sql.SQLException {
        log.trace("startPool()");
        super.startPool();
    }
}
