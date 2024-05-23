package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import lombok.extern.slf4j.Slf4j;
//import org.openjdk.jol.vm.VM;


@Slf4j
public class SimplePoolDataSourceHikari
    extends HikariDataSource
    implements SimplePoolDataSource, PoolDataSourcePropertiesSettersHikari, PoolDataSourcePropertiesGettersHikari {

    private final StringBuffer id = new StringBuffer();
         
    public void setId(final String srcId) {
        SimplePoolDataSource.setId(id, String.format("0x%08x", hashCode())/*(long) System.identityHashCode(this)/*VM.current().addressOf(this)*/, srcId);
    }

    public String getId() {
        return id.toString();
    }

    public void set(final PoolDataSourceConfiguration pdsConfig) {
        set((PoolDataSourceConfigurationHikari)pdsConfig);
    }
    
    private void set(final PoolDataSourceConfigurationHikari pdsConfig) {
        log.debug(">set(pdsConfig={})", pdsConfig);
        
        int nr = 0;
        final int maxNr = 18;
        
        do {
            try {
                switch(nr) {
                case  0: setDriverClassName(pdsConfig.getDriverClassName()); break;
                case  1: setJdbcUrl(pdsConfig.getUrl()); break;
                case  2: setUsername(pdsConfig.getUsername()); break;
                case  3: setPassword(pdsConfig.getPassword()); break;
                case  4: setPoolName(pdsConfig.getPoolName()); break;
                case  5: setMaximumPoolSize(pdsConfig.getMaximumPoolSize()); break;
                case  6: setMinimumIdle(pdsConfig.getMinimumIdle()); break;
                case  7: setAutoCommit(pdsConfig.isAutoCommit()); break;
                case  8: setConnectionTimeout(pdsConfig.getConnectionTimeout()); break;
                case  9: setIdleTimeout(pdsConfig.getIdleTimeout()); break;
                case 10: setMaxLifetime(pdsConfig.getMaxLifetime()); break;
                case 11: setConnectionTestQuery(pdsConfig.getConnectionTestQuery()); break;
                case 12: setInitializationFailTimeout(pdsConfig.getInitializationFailTimeout()); break;
                case 13: setIsolateInternalQueries(pdsConfig.isIsolateInternalQueries()); break;
                case 14: setAllowPoolSuspension(pdsConfig.isAllowPoolSuspension()); break;
                case 15: setReadOnly(pdsConfig.isReadOnly()); break;
                case 16: setRegisterMbeans(pdsConfig.isRegisterMbeans()); break;
                case 17: setValidationTimeout(pdsConfig.getValidationTimeout()); break;
                case 18: setLeakDetectionThreshold(pdsConfig.getLeakDetectionThreshold()); break;
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
    
    private PoolDataSourceConfiguration get(final boolean excludeNonIdConfiguration) {
        return PoolDataSourceConfigurationHikari
            .builder()
            .driverClassName(getDriverClassName())
            .url(getJdbcUrl())
            .username(getUsername())
            .password(excludeNonIdConfiguration ? null : getPassword())
            .type(this.getClass().getName())
            .poolName(excludeNonIdConfiguration ? null : getPoolName())
            .maximumPoolSize(getMaximumPoolSize())
            .minimumIdle(getMinimumIdle())
            .autoCommit(isAutoCommit())
            .connectionTimeout(getConnectionTimeout())
            .idleTimeout(getIdleTimeout())
            .maxLifetime(getMaxLifetime())
            .connectionTestQuery(getConnectionTestQuery())
            .initializationFailTimeout(getInitializationFailTimeout())
            .isolateInternalQueries(isIsolateInternalQueries())
            .allowPoolSuspension(isAllowPoolSuspension())
            .readOnly(isReadOnly())
            .registerMbeans(isRegisterMbeans())
            .validationTimeout(getValidationTimeout())
            .leakDetectionThreshold(getLeakDetectionThreshold())
            .build();
    }
        
    public void show(final PoolDataSourceConfiguration pdsConfig) {
        show((PoolDataSourceConfigurationHikari)pdsConfig);
    }
    
    private void show(final PoolDataSourceConfigurationHikari pdsConfig) {
        final String indentPrefix = PoolDataSourceStatistics.INDENT_PREFIX;

        /* Smart Pool Data Source */
        
        log.info("Properties for smart pool connecting to schema {} via {}", pdsConfig.getSchema(), pdsConfig.getUsernameToConnectTo());

        /* info from PoolDataSourceConfiguration */
        log.info("{}url: {}", indentPrefix, pdsConfig.getUrl());
        log.info("{}username: {}", indentPrefix, pdsConfig.getUsername());
        // do not log passwords
        log.info("{}type: {}", indentPrefix, pdsConfig.getType());

        /* info from PoolDataSourceConfigurationHikari */
        log.info("{}maximumPoolSize: {}", indentPrefix, pdsConfig.getMaximumPoolSize());
        log.info("{}minimumIdle: {}", indentPrefix, pdsConfig.getMinimumIdle());
        log.info("{}dataSourceClassName: {}", indentPrefix, pdsConfig.getDataSourceClassName());
        log.info("{}autoCommit: {}", indentPrefix, pdsConfig.isAutoCommit());
        log.info("{}connectionTimeout: {}", indentPrefix, pdsConfig.getConnectionTimeout());
        log.info("{}idleTimeout: {}", indentPrefix, pdsConfig.getIdleTimeout());
        log.info("{}maxLifetime: {}", indentPrefix, pdsConfig.getMaxLifetime());
        log.info("{}connectionTestQuery: {}", indentPrefix, pdsConfig.getConnectionTestQuery());
        log.info("{}initializationFailTimeout: {}", indentPrefix, pdsConfig.getInitializationFailTimeout());
        log.info("{}isolateInternalQueries: {}", indentPrefix, pdsConfig.isIsolateInternalQueries());
        log.info("{}allowPoolSuspension: {}", indentPrefix, pdsConfig.isAllowPoolSuspension());
        log.info("{}readOnly: {}", indentPrefix, pdsConfig.isReadOnly());
        log.info("{}registerMbeans: {}", indentPrefix, pdsConfig.isRegisterMbeans());
        log.info("{}validationTimeout: {}", indentPrefix, pdsConfig.getValidationTimeout());
        log.info("{}leakDetectionThreshold: {}", indentPrefix, pdsConfig.getLeakDetectionThreshold());

        /* Common Simple Pool Data Source */
        
        log.info("Properties for common simple pool: {}", getPoolName());
        
        /* info from PoolDataSourceConfiguration */
        log.info("{}driverClassName: {}", indentPrefix, getDriverClassName());
        log.info("{}url: {}", indentPrefix, getJdbcUrl());
        log.info("{}username: {}", indentPrefix, getUsername());
        // do not log passwords
        /* info from PoolDataSourceConfigurationHikari */
        log.info("{}maximumPoolSize: {}", indentPrefix, getMaximumPoolSize());
        log.info("{}minimumIdle: {}", indentPrefix, getMinimumIdle());
        log.info("{}dataSourceClassName: {}", indentPrefix, getDataSourceClassName());
        log.info("{}autoCommit: {}", indentPrefix, isAutoCommit());
        log.info("{}connectionTimeout: {}", indentPrefix, getConnectionTimeout());
        log.info("{}idleTimeout: {}", indentPrefix, getIdleTimeout());
        log.info("{}maxLifetime: {}", indentPrefix, getMaxLifetime());
        log.info("{}connectionTestQuery: {}", indentPrefix, getConnectionTestQuery());
        log.info("{}initializationFailTimeout: {}", indentPrefix, getInitializationFailTimeout());
        log.info("{}isolateInternalQueries: {}", indentPrefix, isIsolateInternalQueries());
        log.info("{}allowPoolSuspension: {}", indentPrefix, isAllowPoolSuspension());
        log.info("{}readOnly: {}", indentPrefix, isReadOnly());
        log.info("{}registerMbeans: {}", indentPrefix, isRegisterMbeans());
        log.info("{}validationTimeout: {}", indentPrefix, getValidationTimeout());
        log.info("{}leakDetectionThreshold: {}", indentPrefix, getLeakDetectionThreshold());
        /*
        log.info("metricRegistry: {}", getMetricRegistry());
        log.info("healthCheckRegistry: {}", getHealthCheckRegistry());
        log.info("catalog: {}", getCatalog());
        log.info("connectionInitSql: {}", getConnectionInitSql());
        log.info("transactionIsolation: {}", getTransactionIsolation());
        log.info("dataSource: {}", getDataSource());
        log.info("schema: {}", getSchema());
        log.info("threadFactory: {}", getThreadFactory());
        log.info("scheduledExecutor: {}", getScheduledExecutor());
        */
    }

    /* Interface PoolDataSourcePropertiesSettersHikari */
    
    public void setUrl(String url) {
        setJdbcUrl(url);
    }

    public void setType(String type) {
    }

    /* Interface PoolDataSourcePropertiesGettersHikari */
    
    public String getUrl() {
        return getJdbcUrl();
    }  

    // public void setPoolName(String poolName) throws SQLException;

    // public String getPoolName();
    
    // public void setUsername(String username) throws SQLException;

    // public String getUsername();

    // public void setPassword(String password) throws SQLException;

    // public String getPassword();
    
    // HikariCP does NOT know of an initial pool size so just return getMinPoolSize()
    public int getInitialPoolSize() {
        return getMinPoolSize();
    }

    // HikariCP does NOT know of a minimum pool size but minimumIdle seems to be the equivalent
    public int getMinPoolSize() {
        return getMinimumIdle();
    }

    public int getMaxPoolSize() {
        return getMaximumPoolSize();
    }

    // public long getConnectionTimeout(); // milliseconds

    public int getActiveConnections() {
        try {
            return getHikariPoolMXBean().getActiveConnections();
        } catch (NullPointerException ex) {
            return -1;
        }
    }

    public int getIdleConnections() {
        try {
            return getHikariPoolMXBean().getIdleConnections();
        } catch (NullPointerException ex) {
            return -1;
        }
    }

    public int getTotalConnections() {
        try {
            return getHikariPoolMXBean().getTotalConnections();
        } catch (NullPointerException ex) {
            return -1;
        }
    }

    /*
    @Override
    public boolean equals(Object obj) {
        if (obj == null || !(obj instanceof SimplePoolDataSourceHikari)) {
            return false;
        }

        final SimplePoolDataSourceHikari other = (SimplePoolDataSourceHikari) obj;
        
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

    @Override
    public String getDriverClassName() {
        final String result = super.getDriverClassName();
        log.debug("getDriverClassName() = {}", result);
        return result;
    }
    
    @Override
    public void setDriverClassName(String driverClassName) {
        log.debug("setDriverClassName({})", driverClassName);
        super.setDriverClassName(driverClassName);
    }    
    
    @Override
    public String getJdbcUrl() {
        final String result = super.getJdbcUrl();
        log.debug("getJdbcUrl() = {}", result);
        return result;
    }
  
    @Override
    public void setJdbcUrl(String jdbcUrl) {
        log.debug("setJdbcUrl({})", jdbcUrl);
        super.setJdbcUrl(jdbcUrl);
    }    
  
    @Override
    public String getPoolName() {
        final String result = super.getPoolName();
        log.debug("getPoolName() = {}", result);
        return result;
    }

    @Override
    public void setPoolName(String poolName) {
        log.debug("setPoolName({})", poolName);
        super.setPoolName(poolName);
    }    

    @Override
    public int getMaximumPoolSize() {
        final int result = super.getMaximumPoolSize();
        log.debug("getMaximumPoolSize() = {}", result);
        return result;
    }

    @Override
    public void setMaximumPoolSize(int maxPoolSize) {
        log.debug("setMaximumPoolSize({})", maxPoolSize);
        super.setMaximumPoolSize(maxPoolSize);
    }    

    @Override
    public int getMinimumIdle() {
        final int result = super.getMinimumIdle();
        log.debug("getMinimumIdle() = {}", result);
        return result;
    }

    @Override
    public void setMinimumIdle(int minIdle) {
        log.debug("setMinimumIdle({})", minIdle);
        super.setMinimumIdle(minIdle);
    }    

    @Override
    public String getDataSourceClassName() {
        final String result = super.getDataSourceClassName();
        log.debug("getDataSourceClassName() = {}", result);
        return result;
    }

    @Override
    public void setDataSourceClassName(String dataSourceClassName) {
        log.debug("setDataSourceClassName({})", dataSourceClassName);
        super.setDataSourceClassName(dataSourceClassName);
    }    

    @Override
    public boolean isAutoCommit() {
        final boolean result = super.isAutoCommit();
        log.debug("isAutoCommit() = {}", result);
        return result;
    }

    @Override
    public void setAutoCommit(boolean isAutoCommit) {
        log.debug("setAutoCommit({})", isAutoCommit);
        super.setAutoCommit(isAutoCommit);
    }    

    @Override
    public long getConnectionTimeout() {
        final long result = super.getConnectionTimeout();
        log.debug("getConnectionTimeout() = {}", result);
        return result;
    }

    @Override
    public void setConnectionTimeout(long connectionTimeoutMs) {
        log.debug("setConnectionTimeout({})", connectionTimeoutMs);
        super.setConnectionTimeout(connectionTimeoutMs);
    }    

    @Override
    public long getIdleTimeout() {
        final long result = super.getIdleTimeout();
        log.debug("getIdleTimeout() = {}", result);
        return result;
    }

    @Override
    public void setIdleTimeout(long idleTimeoutMs) {
        log.debug("setIdleTimeout({})", idleTimeoutMs);
        super.setIdleTimeout(idleTimeoutMs);
    }    

    @Override
    public long getMaxLifetime() {
        final long result = super.getMaxLifetime();
        log.debug("getMaxLifetime() = {}", result);
        return result;
    }

    @Override
    public void setMaxLifetime(long maxLifetimeMs) {
        log.debug("setMaxLifetime({})", maxLifetimeMs);
        super.setMaxLifetime(maxLifetimeMs);
    }    

    @Override
    public String getConnectionTestQuery() {
        final String result = super.getConnectionTestQuery();
        log.debug("getConnectionTestQuery() = {}", result);
        return result;
    }

    @Override
    public void setConnectionTestQuery(String connectionTestQuery) {
        log.debug("setConnectionTestQuery({})", connectionTestQuery);
        super.setConnectionTestQuery(connectionTestQuery);
    }    

    @Override
    public long getInitializationFailTimeout() {
        final long result = super.getInitializationFailTimeout();
        log.debug("getInitializationFailTimeout() = {}", result);
        return result;
    }

    @Override
    public void setInitializationFailTimeout(long initializationFailTimeout) {
        log.debug("setInitializationFailTimeout({})", initializationFailTimeout);
        super.setInitializationFailTimeout(initializationFailTimeout);
    }    

    @Override
    public boolean isIsolateInternalQueries() {
        final boolean result = super.isIsolateInternalQueries();
        log.debug("isIsolateInternalQueries() = {}", result);
        return result;
    }

    @Override
    public void setIsolateInternalQueries(boolean isolate) {
        log.debug("setIsolateInternalQueries({})", isolate);
        super.setIsolateInternalQueries(isolate);
    }    

    @Override
    public boolean isAllowPoolSuspension() {
        final boolean result = super.isAllowPoolSuspension();
        log.debug("isAllowPoolSuspension() = {}", result);
        return result;
    }

    @Override
    public void setAllowPoolSuspension(boolean isAllowPoolSuspension) {
        log.debug("setAllowPoolSuspension({})", isAllowPoolSuspension);
        super.setAllowPoolSuspension(isAllowPoolSuspension);
    }    

    @Override
    public boolean isReadOnly() {
        final boolean result = super.isReadOnly();
        log.debug("isReadOnly() = {}", result);
        return result;
    }

    @Override
    public void setReadOnly(boolean readOnly) {
        log.debug("setReadOnly({})", readOnly);
        super.setReadOnly(readOnly);
    }    

    @Override
    public boolean isRegisterMbeans() {
        final boolean result = super.isRegisterMbeans();
        log.debug("isRegisterMbeans() = {}", result);
        return result;
    }
    
    @Override
    public void setRegisterMbeans(boolean register) {
        log.debug("setRegisterMbeans({})", register);
        super.setRegisterMbeans(register);
    }    
    
    @Override
    public long getValidationTimeout() {
        final long result = super.getValidationTimeout();
        log.debug("getValidationTimeout() = {}", result);
        return result;
    }

    @Override
    public void setValidationTimeout(long validationTimeoutMs) {
        log.debug("setValidationTimeout({})", validationTimeoutMs);
        super.setValidationTimeout(validationTimeoutMs);
    }    

    @Override
    public long getLeakDetectionThreshold() {
        final long result = super.getLeakDetectionThreshold();
        log.debug("getLeakDetectionThreshold() = {}", result);
        return result;
    }

    @Override
    public void setLeakDetectionThreshold(long leakDetectionThreshold) {
        log.debug("setLeakDetectionThreshold({})", leakDetectionThreshold);
        super.setLeakDetectionThreshold(leakDetectionThreshold);
    }    
}
