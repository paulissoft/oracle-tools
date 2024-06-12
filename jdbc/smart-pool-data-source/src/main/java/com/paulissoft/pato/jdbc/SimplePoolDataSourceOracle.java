package com.paulissoft.pato.jdbc;

import java.time.Duration;
import java.sql.SQLException;
import lombok.extern.slf4j.Slf4j;
import oracle.ucp.UniversalConnectionPool;
import oracle.ucp.UniversalConnectionPoolException;
import oracle.ucp.admin.UniversalConnectionPoolManager;
import oracle.ucp.admin.UniversalConnectionPoolManagerImpl;
import oracle.ucp.jdbc.PoolDataSourceImpl;
    
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
                case 14: setConnectionWaitDurationInMillis(pdsConfig.getConnectionWaitDurationInMillis()); break;
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
        return PoolDataSourceConfigurationOracle
            .builder()
            .driverClassName(null)
            .url(getURL())
            .username(getUsername())
            .password(null) // do not copy password
            .type(SimplePoolDataSourceOracle.class.getName())
            .connectionPoolName(null) // do not copy pool name
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
            .connectionWaitDurationInMillis(getConnectionWaitDurationInMillis())
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
        log.info("{}connectionWaitDurationInMillis: {}", indentPrefix, pdsConfig.getConnectionWaitDurationInMillis());
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
        log.info("{}connectionWaitDurationInMillis: {}", indentPrefix, getConnectionWaitDurationInMillis());
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

    // IMPORTANT
    //
    // Since the connection pool name can notchange once the pool has started,
    // we change the description if we add/remove schemas.
    public String getPoolDescription() {
        final String poolName = getConnectionPoolName();
        final String description = getDescription();
        
        return (poolName == null || poolName.isEmpty() ?
                "" :
                poolName + (description == null || description.isEmpty() ? "" : "-" + description));
    }

    public void setUsername(String username) throws SQLException {
        setUser(username);
    }

    public String getUsername() {
        return getUser();
    }
    
    @SuppressWarnings("deprecation")
    @Override
    public String getPassword() {
        return super.getPassword();
    }

    // Already part of PoolDataSourceImpl:
    // public int getInitialPoolSize();
    // public void setInitialPoolSize(int initialPoolSize);
    // public int getMinPoolSize();
    // public void setMinPoolSize(int minPoolSize);
    // public int getMaxPoolSize();
    // public void setMaxPoolSize(int maxPoolSize);
    
    public long getConnectionTimeout() { // milliseconds
        return getConnectionWaitDurationInMillis();
    }

    public void setConnectionTimeout(long connectionTimeout) throws SQLException { // milliseconds
        setConnectionWaitDurationInMillis(connectionTimeout);
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
            final String connectionPoolName = getConnectionPoolName();
            
            log.info("{} - Close initiated...", connectionPoolName);
            
            // this pool may or may NOT be in the connection pools (implicitly) managed by mgr
            UniversalConnectionPool ucp;

            try {
                ucp = mgr.getConnectionPool(connectionPoolName);
            } catch (Exception ex) {
                ucp = null;
            }

            if (ucp != null) {
                ucp.stop();
                log.info("{} - Close completed.", connectionPoolName);
                // mgr.destroyConnectionPool(getConnectionPoolName()); // will generate a UCP-45 later on
            }
        } catch (UniversalConnectionPoolException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }
    
    @Override
    public long getConnectionWaitDurationInMillis() {
        return getConnectionWaitDuration().toMillis();
    }

    @Override
    public void setConnectionWaitDurationInMillis(long waitTimeout) throws SQLException {
        setConnectionWaitDuration(Duration.ofMillis(waitTimeout));
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

    /*
    @Override
    public int getAbandonedConnectionTimeout() {
        final int result = super.getAbandonedConnectionTimeout();
        log.debug("getAbandonedConnectionTimeout() = {}", result);
        return result;
    }

    @Override
    public void setAbandonedConnectionTimeout(int abandonedConnectionTimeout) throws SQLException {
        log.debug("setAbandonedConnectionTimeout({})", abandonedConnectionTimeout);
        super.setAbandonedConnectionTimeout(abandonedConnectionTimeout);
    }

    @Override
    public String getConnectionFactoryClassName() {
        final String result = super.getConnectionFactoryClassName();
        log.debug("getConnectionFactoryClassName() = {}", result);
        return result;
    }

    @Override
    public void setConnectionFactoryClassName(String factoryClassName) throws SQLException {
        log.debug("setConnectionFactoryClassName({})", factoryClassName);
        super.setConnectionFactoryClassName(factoryClassName);
    }

    @Override
    public String getConnectionPoolName() {
        final String result = super.getConnectionPoolName();
        log.debug("getConnectionPoolName() = {}", result);
        return result;
    }

    @Override
    public void setConnectionPoolName(String connectionPoolName) throws SQLException {
        log.debug("setConnectionPoolName({})", connectionPoolName);
        super.setConnectionPoolName(connectionPoolName);
    }

    @Override
    public int getConnectionValidationTimeout() {
        final int result = super.getConnectionValidationTimeout();
        log.debug("getConnectionValidationTimeout() = {}", result);
        return result;
    }

    @Override
    public void setConnectionValidationTimeout(int connectionValidationTimeout) throws SQLException {
        log.debug("setConnectionValidationTimeout({})", connectionValidationTimeout);
        super.setConnectionValidationTimeout(connectionValidationTimeout);
    }

    @Override
    public int getInactiveConnectionTimeout() {
        final int result = super.getInactiveConnectionTimeout();
        log.debug("getInactiveConnectionTimeout() = {}", result);
        return result;
    }

    @Override
    public void setInactiveConnectionTimeout(int inactivityTimeout) throws SQLException {
        log.debug("setInactiveConnectionTimeout({})", inactivityTimeout);
        super.setInactiveConnectionTimeout(inactivityTimeout);
    }

    @Override
    public int getInitialPoolSize() {
        final int result = super.getInitialPoolSize();
        log.debug("getInitialPoolSize() = {}", result);
        return result;
    }

    @Override
    public void setInitialPoolSize(int initialPoolSize) throws SQLException {
        log.debug("setInitialPoolSize({})", initialPoolSize);
        super.setInitialPoolSize(initialPoolSize);
    }

    @Override
    public long getMaxConnectionReuseTime() {
        final long result = super.getMaxConnectionReuseTime();
        log.debug("getMaxConnectionReuseTime() = {}", result);
        return result;
    }

    @Override
    public void setMaxConnectionReuseTime(long maxConnectionReuseTime) throws SQLException {
        log.debug("setMaxConnectionReuseTime({})", maxConnectionReuseTime);
        super.setMaxConnectionReuseTime(maxConnectionReuseTime);
    }

    @Override
    public int getMaxPoolSize() {
        final int result = super.getMaxPoolSize();
        log.debug("getMaxPoolSize() = {}", result);
        return result;
    }

    @Override
    public void setMaxPoolSize(int maxPoolSize) throws SQLException {
        log.debug("setMaxPoolSize({})", maxPoolSize);
        super.setMaxPoolSize(maxPoolSize);
    }

    @Override
    public int getMaxStatements() {
        final int result = super.getMaxStatements();
        log.debug("getMaxStatements() = {}", result);
        return result;
    }

    @Override
    public void setMaxStatements(int maxStatements) throws SQLException {
        log.debug("setMaxStatements({})", maxStatements);
        super.setMaxStatements(maxStatements);
    }

    @Override
    public int getMinPoolSize() {
        final int result = super.getMinPoolSize();
        log.debug("getMinPoolSize() = {}", result);
        return result;
    }

    @Override
    public void setMinPoolSize(int minPoolSize) throws SQLException {
        log.debug("setMinPoolSize({})", minPoolSize);
        super.setMinPoolSize(minPoolSize);
    }

    @Override
    public int getSecondsToTrustIdleConnection() {
        final int result = super.getSecondsToTrustIdleConnection();
        log.debug("getSecondsToTrustIdleConnection() = {}", result);
        return result;
    }

    @Override
    public void setSecondsToTrustIdleConnection(int secondsToTrustIdleConnection) throws SQLException {
        log.debug("setSecondsToTrustIdleConnection({})", secondsToTrustIdleConnection);
        super.setSecondsToTrustIdleConnection(secondsToTrustIdleConnection);
    }

    @Override
    public void setTimeoutCheckInterval(int timeInterval) throws SQLException {
        log.debug("setTimeoutCheckInterval({})", timeInterval);
        super.setTimeoutCheckInterval(timeInterval);
    }

    @Override
    public int getTimeoutCheckInterval() {
        log.debug("getTimeoutCheckInterval()");
        return super.getTimeoutCheckInterval();
    }

    @Override
    public int getTimeToLiveConnectionTimeout() {
        log.debug("getTimeToLiveConnectionTimeout()");
        return super.getTimeToLiveConnectionTimeout();
    }

    @Override
    public void setTimeToLiveConnectionTimeout(int timeToLiveConnectionTimeout) throws SQLException {
        log.debug("setTimeToLiveConnectionTimeout({})", timeToLiveConnectionTimeout);
        super.setTimeToLiveConnectionTimeout(timeToLiveConnectionTimeout);
    }

    @Override
    public String getURL() {
        log.debug("getURL()");
        return super.getURL();
    }

    @Override
    public void setURL(String url) throws SQLException {
        log.debug("setURL({})", url);
        super.setURL(url);
    }

    @Override
    public String getUser() {
        log.debug("getUser()");
        return super.getUser();
    }

    @Override
    public void setUser(String username) throws SQLException {
        log.debug("setUser({})", username);
        super.setUser(username);
    }

    @Override
    public boolean getValidateConnectionOnBorrow() {
        log.debug("getValidateConnectionOnBorrow()");
        return super.getValidateConnectionOnBorrow();
    }
    
    @Override
    public void setValidateConnectionOnBorrow(boolean validateConnectionOnBorrow) throws SQLException {
        log.debug("setValidateConnectionOnBorrow({})", validateConnectionOnBorrow);
        super.setValidateConnectionOnBorrow(validateConnectionOnBorrow);
    }
    */
}
