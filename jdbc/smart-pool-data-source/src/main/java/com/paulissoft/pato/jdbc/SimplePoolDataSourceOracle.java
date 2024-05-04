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
        log.debug("createConnectionBuilder()");
        return super.createConnectionBuilder();
    }

    protected void createPoolWithDefaultProperties() throws java.sql.SQLException {
        log.debug("createPoolWithDefaultProperties()");
        super.createPoolWithDefaultProperties();
    }

    public int getAbandonedConnectionTimeout() {
        log.debug("getAbandonedConnectionTimeout()");
        return super.getAbandonedConnectionTimeout();
    }

    public int getAvailableConnectionsCount() {
        log.debug("getAvailableConnectionsCount()");
        return super.getAvailableConnectionsCount();
    }

    public int getBorrowedConnectionsCount() {
        log.debug("getBorrowedConnectionsCount()");
        return super.getBorrowedConnectionsCount();
    }

    public java.sql.Connection getConnection() throws java.sql.SQLException {
        log.debug("getConnection()");
        return super.getConnection();
    }

    public java.sql.Connection getConnection(java.util.Properties labels) throws java.sql.SQLException {
        log.debug("getConnection(labels)");
        return super.getConnection(labels);
    }

    public java.sql.Connection getConnection(java.lang.String username, java.lang.String password) throws java.sql.SQLException {
        log.debug("getConnection(username, password)");
        return super.getConnection(username, password);
    }

    public java.sql.Connection getConnection(java.lang.String username, java.lang.String password, java.util.Properties labels) throws java.sql.SQLException {
        log.debug("getConnection(username, password, labels)");
        return super.getConnection(username, password, labels);
    }

    public java.lang.String getConnectionFactoryClassName() {
        log.debug("getConnectionFactoryClassName()");
        return super.getConnectionFactoryClassName();
    }

    public java.util.Properties getConnectionFactoryProperties() {
        log.debug("getConnectionFactoryProperties()");
        return super.getConnectionFactoryProperties();
    }

    public java.lang.String getConnectionFactoryProperty(java.lang.String propertyName) {
        log.debug("getConnectionFactoryProperty(propertyName)");
        return super.getConnectionFactoryProperty(propertyName);
    }

    public int getConnectionHarvestMaxCount() {
        log.debug("getConnectionHarvestMaxCount()");
        return super.getConnectionHarvestMaxCount();
    }

    public int getConnectionHarvestTriggerCount() {
        log.debug("getConnectionHarvestTriggerCount()");
        return super.getConnectionHarvestTriggerCount();
    }

    public ConnectionInitializationCallback getConnectionInitializationCallback() {
        log.debug("getConnectionInitializationCallback()");
        return super.getConnectionInitializationCallback();
    }

    public int getConnectionLabelingHighCost() {
        log.debug("getConnectionLabelingHighCost()");
        return super.getConnectionLabelingHighCost();
    }

    public java.lang.String getConnectionPoolName() {
        log.debug("getConnectionPoolName()");
        return super.getConnectionPoolName();
    }

    public java.util.Properties getConnectionProperties() {
        log.debug("getConnectionProperties()");
        return super.getConnectionProperties();
    }

    public java.lang.String getConnectionProperty(java.lang.String propertyName) {
        log.debug("getConnectionProperty(propertyName)");
        return super.getConnectionProperty(propertyName);
    }

    public int getConnectionRepurposeThreshold() {
        log.debug("getConnectionRepurposeThreshold()");
        return super.getConnectionRepurposeThreshold();
    }

    public int getConnectionValidationTimeout() {
        log.debug("getConnectionValidationTimeout()");
        return super.getConnectionValidationTimeout();
    }

    public int getConnectionWaitTimeout() {
        log.debug("getConnectionWaitTimeout()");
        return super.getConnectionWaitTimeout();
    }

    public java.lang.String getDatabaseName() {
        log.debug("getDatabaseName()");
        return super.getDatabaseName();
    }

    public java.lang.String getDataSourceName() {
        log.debug("getDataSourceName()");
        return super.getDataSourceName();
    }

    public java.lang.String getDescription() {
        log.debug("getDescription()");
        return super.getDescription();
    }

    public boolean getFastConnectionFailoverEnabled() {
        log.debug("getFastConnectionFailoverEnabled()");
        return super.getFastConnectionFailoverEnabled();
    }

    public int getHighCostConnectionReuseThreshold() {
        log.debug("getHighCostConnectionReuseThreshold()");
        return super.getHighCostConnectionReuseThreshold();
    }

    public int getInactiveConnectionTimeout() {
        log.debug("getInactiveConnectionTimeout()");
        return super.getInactiveConnectionTimeout();
    }

    public int getInitialPoolSize() {
        log.debug("getInitialPoolSize()");
        return super.getInitialPoolSize();
    }

    public int getLoginTimeout() {
        log.debug("getLoginTimeout()");
        return super.getLoginTimeout();
    }

    public java.io.PrintWriter getLogWriter() throws java.sql.SQLException {
        log.debug("getLogWriter()");
        return super.getLogWriter();
    }

    public int getMaxConnectionReuseCount() {
        log.debug("getMaxConnectionReuseCount()");
        return super.getMaxConnectionReuseCount();
    }

    public long getMaxConnectionReuseTime() {
        log.debug("getMaxConnectionReuseTime()");
        return super.getMaxConnectionReuseTime();
    }

    public int getMaxConnectionsPerService() {
        log.debug("getMaxConnectionsPerService()");
        return super.getMaxConnectionsPerService();
    }

    public int getMaxConnectionsPerShard() {
        log.debug("getMaxConnectionsPerShard()");
        return super.getMaxConnectionsPerShard();
    }

    public int getMaxIdleTime() {
        log.debug("getMaxIdleTime()");
        return super.getMaxIdleTime();
    }

    public int getMaxPoolSize() {
        log.debug("getMaxPoolSize()");
        return super.getMaxPoolSize();
    }

    public int getMaxStatements() {
        log.debug("getMaxStatements()");
        return super.getMaxStatements();
    }

    public int getMinPoolSize() {
        log.debug("getMinPoolSize()");
        return super.getMinPoolSize();
    }

    public java.lang.String getNetworkProtocol() {
        log.debug("getNetworkProtocol()");
        return super.getNetworkProtocol();
    }

    public java.lang.Object getObjectInstance(java.lang.Object refObj,
                                              javax.naming.Name name,
                                              javax.naming.Context nameCtx,
                                              java.util.Hashtable<?,?> env) throws java.lang.Exception {
        log.debug("getObjectInstance(refObj, name, nameCtx, env)");
        return super.getObjectInstance(refObj, name, nameCtx, env);
    }

    public java.util.logging.Logger getParentLogger() {
        log.debug("getParentLogger()");
        return super.getParentLogger();
    }

    public java.util.Properties getPdbRoles() {
        log.debug("getPdbRoles()");
        return super.getPdbRoles();
    }

    public int getPortNumber() {
        log.debug("getPortNumber()");
        return super.getPortNumber();
    }

    public int getPropertyCycle() {
        log.debug("getPropertyCycle()");
        return super.getPropertyCycle();
    }

    public int getQueryTimeout() {
        log.debug("getQueryTimeout()");
        return super.getQueryTimeout();
    }

    public javax.naming.Reference  getReference() {
        log.debug("getReference()");
        return super.getReference();
    }

    public java.lang.String getRoleName() {
        log.debug("getRoleName()");
        return super.getRoleName();
    }

    public int getSecondsToTrustIdleConnection() {
        log.debug("getSecondsToTrustIdleConnection()");
        return super.getSecondsToTrustIdleConnection();
    }

    public java.lang.String getServerName() {
        log.debug("getServerName()");
        return super.getServerName();
    }

    public java.lang.String getServiceName() {
        log.debug("getServiceName()");
        return super.getServiceName();
    }

    public boolean getShardingMode() {
        log.debug("getShardingMode()");
        return super.getShardingMode();
    }

    public java.lang.String getSQLForValidateConnection() {
        log.debug("getSQLForValidateConnection()");
        return super.getSQLForValidateConnection();
    }

    protected javax.net.ssl.SSLContext  getSSLContext() {
        log.debug("getSSLContext()");
        return super.getSSLContext();
    }

    public JDBCConnectionPoolStatistics getStatistics() {
        log.debug("getStatistics()");
        return super.getStatistics();
    }

    public int getTimeoutCheckInterval() {
        log.debug("getTimeoutCheckInterval()");
        return super.getTimeoutCheckInterval();
    }

    public int getTimeToLiveConnectionTimeout() {
        log.debug("getTimeToLiveConnectionTimeout()");
        return super.getTimeToLiveConnectionTimeout();
    }

    public java.lang.String getURL() {
        log.debug("getURL()");
        return super.getURL();
    }

    public java.lang.String getUser() {
        log.debug("getUser()");
        return super.getUser();
    }

    public boolean getValidateConnectionOnBorrow() {
        log.debug("getValidateConnectionOnBorrow()");
        return super.getValidateConnectionOnBorrow();
    }

    public boolean isReadOnlyInstanceAllowed() {
        log.debug("isReadOnlyInstanceAllowed()");
        return super.isReadOnlyInstanceAllowed();
    }

    public static boolean isSetOnceProperty(java.lang.String key) {
        return PoolDataSourceImpl.isSetOnceProperty(key);
    }

    public boolean isWrapperFor(java.lang.Class<?> iface) throws java.sql.SQLException {
        log.debug("isWrapperFor(iface)");
        return super.isWrapperFor(iface);
    }

    public void reconfigureDataSource(java.util.Properties configuration) throws java.sql.SQLException {
        log.debug("reconfigureDataSource(configuration)");
        super.reconfigureDataSource(configuration);
    }

    public void registerConnectionAffinityCallback(ConnectionAffinityCallback cbk) throws java.sql.SQLException {
        log.debug("registerConnectionAffinityCallback(cbk)");
        super.registerConnectionAffinityCallback(cbk);
    }

    public void registerConnectionInitializationCallback(ConnectionInitializationCallback cbk) throws java.sql.SQLException {
        log.debug("registerConnectionInitializationCallback(cbk)");
        super.registerConnectionInitializationCallback(cbk);
    }

    public void registerConnectionLabelingCallback(ConnectionLabelingCallback cbk) throws java.sql.SQLException {
        log.debug("registerConnectionLabelingCallback(cbk)");
        super.registerConnectionLabelingCallback(cbk);
    }

    public void removeConnectionAffinityCallback() throws java.sql.SQLException {
        log.debug("removeConnectionAffinityCallback()");
        super.removeConnectionAffinityCallback();
    }

    public void removeConnectionLabelingCallback() throws java.sql.SQLException {
        log.debug("removeConnectionLabelingCallback()");
        super.removeConnectionLabelingCallback();
    }

    public void setAbandonedConnectionTimeout(int abandonedConnectionTimeout) throws java.sql.SQLException {
        log.debug("setAbandonedConnectionTimeout({})", abandonedConnectionTimeout);
        super.setAbandonedConnectionTimeout(abandonedConnectionTimeout);
    }

    public void setConnectionFactoryClassName(java.lang.String factoryClassName) throws java.sql.SQLException {
        log.debug("setConnectionFactoryClassName({})", factoryClassName);
        super.setConnectionFactoryClassName(factoryClassName);
    }

    public void setConnectionFactoryProperties(java.util.Properties factoryProperties) throws java.sql.SQLException {
        log.debug("setConnectionFactoryProperties({})", factoryProperties);
        super.setConnectionFactoryProperties(factoryProperties);
    }

    public void setConnectionFactoryProperty(java.lang.String name, java.lang.String value) throws java.sql.SQLException {
        log.debug("setConnectionFactoryProperty({}, {})", name, value);
        super.setConnectionFactoryProperty(name, value);
    }

    public void setConnectionHarvestMaxCount(int connectionHarvestMaxCount) throws java.sql.SQLException {
        log.debug("setConnectionHarvestMaxCount({})", connectionHarvestMaxCount);
        super.setConnectionHarvestMaxCount(connectionHarvestMaxCount);
    }

    public void setConnectionHarvestTriggerCount(int connectionHarvestTriggerCount) throws java.sql.SQLException {
        log.debug("setConnectionHarvestTriggerCount({})", connectionHarvestTriggerCount);
        super.setConnectionHarvestTriggerCount(connectionHarvestTriggerCount);
    }

    public void setConnectionLabelingHighCost(int highCost) throws java.sql.SQLException {
        log.debug("setConnectionLabelingHighCost()", highCost);
        super.setConnectionLabelingHighCost(highCost);
    }

    public void setConnectionPoolName(java.lang.String connectionPoolName) throws java.sql.SQLException {
        log.debug("setConnectionPoolName({})", connectionPoolName);
        super.setConnectionPoolName(connectionPoolName);
    }

    public void setConnectionProperties(java.util.Properties connectionProperties) throws java.sql.SQLException {
        log.debug("setConnectionProperties({})", connectionProperties);
        super.setConnectionProperties(connectionProperties);
    }

    public void setConnectionProperty(java.lang.String name, java.lang.String value) throws java.sql.SQLException {
        log.debug("setConnectionProperty({}, {})", name, value);
        super.setConnectionProperty(name, value);
    }

    public void setConnectionRepurposeThreshold(int threshold) throws java.sql.SQLException {
        log.debug("setConnectionRepurposeThreshold({})", threshold);
        super.setConnectionRepurposeThreshold(threshold);
    }

    public void setConnectionValidationTimeout(int connectionValidationTimeout) throws java.sql.SQLException {
        log.debug("setConnectionValidationTimeout({})", connectionValidationTimeout);
        super.setConnectionValidationTimeout(connectionValidationTimeout);
    }

    public void setConnectionWaitTimeout(int waitTimeout) throws java.sql.SQLException {
        log.debug("setConnectionWaitTimeout({})", waitTimeout);
        super.setConnectionWaitTimeout(waitTimeout);
    }

    public void setDatabaseName(java.lang.String databaseName) throws java.sql.SQLException {
        log.debug("setDatabaseName({})", databaseName);
        super.setDatabaseName(databaseName);
    }

    public void setDataSourceName(java.lang.String dataSourceName) throws java.sql.SQLException {
        log.debug("setDataSourceName({})", dataSourceName);
        super.setDataSourceName(dataSourceName);
    }

    public void setDescription(java.lang.String dataSourceDescription) throws java.sql.SQLException {
        log.debug("setDescription({})", dataSourceDescription);
        super.setDescription(dataSourceDescription);
    }

    public void setFastConnectionFailoverEnabled(boolean failoverEnabled) throws java.sql.SQLException {
        log.debug("setFastConnectionFailoverEnabled({})", failoverEnabled);
        super.setFastConnectionFailoverEnabled(failoverEnabled);
    }

    public void setHighCostConnectionReuseThreshold(int threshold) throws java.sql.SQLException {
        log.debug("setHighCostConnectionReuseThreshold({})", threshold);
        super.setHighCostConnectionReuseThreshold(threshold);
    }

    public void setInactiveConnectionTimeout(int inactivityTimeout) throws java.sql.SQLException {
        log.debug("setInactiveConnectionTimeout({})", inactivityTimeout);
        super.setInactiveConnectionTimeout(inactivityTimeout);
    }

    public void setInitialPoolSize(int initialPoolSize) throws java.sql.SQLException {
        log.debug("setInitialPoolSize({})", initialPoolSize);
        super.setInitialPoolSize(initialPoolSize);
    }

    public void setLoginTimeout(int seconds) throws java.sql.SQLException {
        log.debug("setLoginTimeout({})", seconds);
        super.setLoginTimeout(seconds);
    }

    public void setLogWriter(java.io.PrintWriter logWriter) throws java.sql.SQLException {
        log.debug("setLogWriter({})", logWriter);
        super.setLogWriter(logWriter);
    }

    public void setMaxConnectionReuseCount(int maxConnectionReuseCount) throws java.sql.SQLException {
        log.debug("setMaxConnectionReuseCount({})", maxConnectionReuseCount);
        super.setMaxConnectionReuseCount(maxConnectionReuseCount);
    }

    public void setMaxConnectionReuseTime(long maxConnectionReuseTime) throws java.sql.SQLException {
        log.debug("setMaxConnectionReuseTime({})", maxConnectionReuseTime);
        super.setMaxConnectionReuseTime(maxConnectionReuseTime);
    }

    public void setMaxConnectionsPerShard(int maxConnectionsPerShard) throws java.sql.SQLException {
        log.debug("setMaxConnectionsPerShard({})", maxConnectionsPerShard);
        super.setMaxConnectionsPerShard(maxConnectionsPerShard);
    }

    public void setMaxIdleTime(int idleTime) throws java.sql.SQLException {
        log.debug("setMaxIdleTime({})", idleTime);
        super.setMaxIdleTime(idleTime);
    }

    public void setMaxPoolSize(int maxPoolSize) throws java.sql.SQLException {
        log.debug("setMaxPoolSize({})", maxPoolSize);
        super.setMaxPoolSize(maxPoolSize);
    }

    public void setMaxStatements(int maxStatements) throws java.sql.SQLException {
        log.debug("setMaxStatements({})", maxStatements);
        super.setMaxStatements(maxStatements);
    }

    public void setMinPoolSize(int minPoolSize) throws java.sql.SQLException {
        log.debug("setMinPoolSize({})", minPoolSize);
        super.setMinPoolSize(minPoolSize);
    }

    public void setNetworkProtocol(java.lang.String networkProtocol) throws java.sql.SQLException {
        log.debug("setNetworkProtocol({})", networkProtocol);
        super.setNetworkProtocol(networkProtocol);
    }

    public void setONSConfiguration(java.lang.String onsConfigStr) {
        log.debug("setONSConfiguration({})", onsConfigStr);
        super.setONSConfiguration(onsConfigStr);
    }

    public void setPassword(java.lang.String password) throws java.sql.SQLException {
        log.debug("setPassword({})", password);
        super.setPassword(password);
    }

    public void setPortNumber(int portNumber) throws java.sql.SQLException {
        log.debug("setPortNumber({})", portNumber);
        super.setPortNumber(portNumber);
    }

    public void setPropertyCycle(int propertyCycle) throws java.sql.SQLException {
        log.debug("setPropertyCycle({})", propertyCycle);
        super.setPropertyCycle(propertyCycle);
    }

    public void setQueryTimeout(int queryTimeout) throws java.sql.SQLException {
        log.debug("setQueryTimeout({})", queryTimeout);
        super.setQueryTimeout(queryTimeout);
    }

    public void setReadOnlyInstanceAllowed(boolean readOnlyInstanceAllowed) throws java.sql.SQLException {
        log.debug("setReadOnlyInstanceAllowed({})", readOnlyInstanceAllowed);
        super.setReadOnlyInstanceAllowed(readOnlyInstanceAllowed);
    }

    public void setRoleName(java.lang.String roleName) throws java.sql.SQLException {
        log.debug("setRoleName({})", roleName);
        super.setRoleName(roleName);
    }

    public void setSecondsToTrustIdleConnection(int secondsToTrustIdleConnection) throws java.sql.SQLException {
        log.debug("setSecondsToTrustIdleConnection({})", secondsToTrustIdleConnection);
        super.setSecondsToTrustIdleConnection(secondsToTrustIdleConnection);
    }

    public void setServerName(java.lang.String serverName) throws java.sql.SQLException {
        log.debug("setServerName({})", serverName);
        super.setServerName(serverName);
    }

    public void setShardingMode(boolean shardingMode) throws java.sql.SQLException {
        log.debug("setShardingMode({})", shardingMode);
        super.setShardingMode(shardingMode);
    }

    public void setSQLForValidateConnection(java.lang.String SQLString) throws java.sql.SQLException {
        log.debug("setSQLForValidateConnection({})", SQLString);
        super.setSQLForValidateConnection(SQLString);
    }

    public void setSSLContext(javax.net.ssl.SSLContext sslContext) {
        log.debug("setSSLContext({})", sslContext);
        super.setSSLContext(sslContext);
    }

    public void setTimeoutCheckInterval(int timeInterval) throws java.sql.SQLException {
        log.debug("setTimeoutCheckInterval({})", timeInterval);
        super.setTimeoutCheckInterval(timeInterval);
    }

    public void setTimeToLiveConnectionTimeout(int timeToLiveConnectionTimeout) throws java.sql.SQLException {
        log.debug("setTimeToLiveConnectionTimeout({})", timeToLiveConnectionTimeout);
        super.setTimeToLiveConnectionTimeout(timeToLiveConnectionTimeout);
    }

    public void setURL(java.lang.String url) throws java.sql.SQLException {
        log.debug("setURL({})", url);
        super.setURL(url);
    }

    public void setUser(java.lang.String username) throws java.sql.SQLException {
        log.debug("setUser({})", username);
        super.setUser(username);
    }

    public void setValidateConnectionOnBorrow(boolean validateConnectionOnBorrow) throws java.sql.SQLException {
        log.debug("setValidateConnectionOnBorrow({})", validateConnectionOnBorrow);
        super.setValidateConnectionOnBorrow(validateConnectionOnBorrow);
    }

    public void startPool() throws java.sql.SQLException {
        log.debug("startPool()");
        super.startPool();
    }
}
