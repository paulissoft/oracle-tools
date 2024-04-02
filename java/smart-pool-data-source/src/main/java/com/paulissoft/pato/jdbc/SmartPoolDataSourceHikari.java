package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.pool.HikariPool;
import java.util.concurrent.ConcurrentHashMap;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.DirectFieldAccessor;


@Slf4j
public class SmartPoolDataSourceHikari extends CombiPoolDataSourceHikari {

    private static final String POOL_NAME_PREFIX = CombiPoolDataSourceHikari.POOL_NAME_PREFIX;
         
    // Statistics at level 2
    private static final PoolDataSourceStatistics poolDataSourceStatisticsTotal
        = new PoolDataSourceStatistics(() -> POOL_NAME_PREFIX + ": (all)",
                                       PoolDataSourceStatistics.poolDataSourceStatisticsGrandTotal);
       
    // Every parent must have statistics at level 3
    private static final ConcurrentHashMap<PoolDataSourceConfigurationCommonId, PoolDataSourceStatistics> activeParentPoolDataSourceStatistics =
        new ConcurrentHashMap<>();

    static void clear() {
        activeParentPoolDataSourceStatistics.clear();
    }
    
    // Every item must have statistics at level 4
    private final PoolDataSourceStatistics poolDataSourceStatistics;
    /*
        new PoolDataSourceStatistics(() -> this.getPoolName() + ": (all)",
                                     poolDataSourceStatisticsTotal,
                                     () -> getState() != CombiPoolDataSource.State.OPEN,
                                     this::getPoolDataSourceConfiguration);
    */

    public SmartPoolDataSourceHikari(){
        poolDataSourceStatistics =
            new PoolDataSourceStatistics(() -> this.getPoolName() + ": (all)",
                                         getActiveParent() == null ?
                                         poolDataSourceStatisticsTotal :
                                         ((SmartPoolDataSourceHikari)getActiveParent()).poolDataSourceStatistics,
                                         () -> getState() != CombiPoolDataSource.State.OPEN,
                                         this::getPoolDataSourceConfiguration);
    }
    
    public SmartPoolDataSourceHikari(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari) {
        super(poolDataSourceConfigurationHikari);
        poolDataSourceStatistics =
            new PoolDataSourceStatistics(() -> this.getPoolName() + ": (all)",
                                         getActiveParent() == null ?
                                         poolDataSourceStatisticsTotal :
                                         ((SmartPoolDataSourceHikari)getActiveParent()).poolDataSourceStatistics,
                                         () -> getState() != CombiPoolDataSource.State.OPEN,
                                         this::getPoolDataSourceConfiguration);
    }

    public SmartPoolDataSourceHikari(@NonNull final SmartPoolDataSourceHikari activeParent) {
        super(activeParent);
        poolDataSourceStatistics =
            new PoolDataSourceStatistics(() -> this.getPoolName() + ": (all)",
                                         getActiveParent() == null ?
                                         poolDataSourceStatisticsTotal :
                                         ((SmartPoolDataSourceHikari)getActiveParent()).poolDataSourceStatistics,
                                         () -> getState() != CombiPoolDataSource.State.OPEN,
                                         this::getPoolDataSourceConfiguration);
    }

    public SmartPoolDataSourceHikari(String driverClassName,
                                     String url,
                                     String username,
                                     String password,
                                     String poolName,
                                     int maximumPoolSize,
                                     int minimumIdle,
                                     String dataSourceClassName,
                                     boolean autoCommit,
                                     long connectionTimeout,
                                     long idleTimeout,
                                     long maxLifetime,
                                     String connectionTestQuery,
                                     long initializationFailTimeout,
                                     boolean isolateInternalQueries,
                                     boolean allowPoolSuspension,
                                     boolean readOnly,
                                     boolean registerMbeans,    
                                     long validationTimeout,
                                     long leakDetectionThreshold) {
        this(build(driverClassName,
                   url,
                   username,
                   password,
                   poolName,
                   maximumPoolSize,
                   minimumIdle,
                   dataSourceClassName,
                   autoCommit,
                   connectionTimeout,
                   idleTimeout,
                   maxLifetime,
                   connectionTestQuery,
                   initializationFailTimeout,
                   isolateInternalQueries,
                   allowPoolSuspension,
                   readOnly,
                   registerMbeans,    
                   validationTimeout,
                   leakDetectionThreshold));
    }

    protected static PoolDataSourceConfigurationHikari build(String driverClassName,
                                                             String url,
                                                             String username,
                                                             String password,
                                                             String poolName,
                                                             int maximumPoolSize,
                                                             int minimumIdle,
                                                             String dataSourceClassName,
                                                             boolean autoCommit,
                                                             long connectionTimeout,
                                                             long idleTimeout,
                                                             long maxLifetime,
                                                             String connectionTestQuery,
                                                             long initializationFailTimeout,
                                                             boolean isolateInternalQueries,
                                                             boolean allowPoolSuspension,
                                                             boolean readOnly,
                                                             boolean registerMbeans,    
                                                             long validationTimeout,
                                                             long leakDetectionThreshold) {
        return PoolDataSourceConfigurationHikari
            .builder()
            .driverClassName(driverClassName)
            .url(url)
            .username(username)
            .password(password)
            // cannot reference this before supertype constructor has been called, hence can not use this in constructor above
            .type(SmartPoolDataSourceHikari.class.getName())
            .poolName(poolName)
            .maximumPoolSize(maximumPoolSize)
            .minimumIdle(minimumIdle)
            .autoCommit(autoCommit)
            .connectionTimeout(connectionTimeout)
            .idleTimeout(idleTimeout)
            .maxLifetime(maxLifetime)
            .connectionTestQuery(connectionTestQuery)
            .initializationFailTimeout(initializationFailTimeout)
            .isolateInternalQueries(isolateInternalQueries)
            .allowPoolSuspension(allowPoolSuspension)
            .readOnly(readOnly)
            .registerMbeans(registerMbeans)
            .validationTimeout(validationTimeout)
            .leakDetectionThreshold(leakDetectionThreshold)
            .build();
    }

    // https://stackoverflow.com/questions/40784965/how-to-get-the-number-of-active-connections-for-hikaricp
    private HikariPool getHikariPool() {
        return (HikariPool) new DirectFieldAccessor(this).getPropertyValue("pool");
    }

    public int getActiveConnections() {
        try {
            return getHikariPool().getActiveConnections();
        } catch (NullPointerException ex) {
            return -1;
        }
    }

    public int getIdleConnections() {
        try {
            return getHikariPool().getIdleConnections();
        } catch (NullPointerException ex) {
            return -1;
        }
    }

    public int getTotalConnections() {
        try {
            return getHikariPool().getTotalConnections();
        } catch (NullPointerException ex) {
            return -1;
        }
    }

    public PoolDataSourceStatistics getPoolDataSourceStatistics() {
        return poolDataSourceStatistics;
    }

    public void show(final PoolDataSourceConfiguration pds) {
        show((PoolDataSourceConfigurationHikari)pds);
    }
    
    private void show(final PoolDataSourceConfigurationHikari pds) {
        final String indentPrefix = PoolDataSourceStatistics.INDENT_PREFIX;

        /* Smart Pool Data Source */
        
        log.info("Properties for smart pool connecting to schema {} via {}", pds.getSchema(), pds.getUsernameToConnectTo());

        /* info from PoolDataSourceConfiguration */
        log.info("{}url: {}", indentPrefix, pds.getUrl());
        log.info("{}username: {}", indentPrefix, pds.getUsername());
        // do not log passwords
        log.info("{}type: {}", indentPrefix, pds.getType());

        /* info from PoolDataSourceConfigurationHikari */
        log.info("{}maximumPoolSize: {}", indentPrefix, pds.getMaximumPoolSize());
        log.info("{}minimumIdle: {}", indentPrefix, pds.getMinimumIdle());
        log.info("{}dataSourceClassName: {}", indentPrefix, pds.getDataSourceClassName());
        log.info("{}autoCommit: {}", indentPrefix, pds.isAutoCommit());
        log.info("{}connectionTimeout: {}", indentPrefix, pds.getConnectionTimeout());
        log.info("{}idleTimeout: {}", indentPrefix, pds.getIdleTimeout());
        log.info("{}maxLifetime: {}", indentPrefix, pds.getMaxLifetime());
        log.info("{}connectionTestQuery: {}", indentPrefix, pds.getConnectionTestQuery());
        log.info("{}initializationFailTimeout: {}", indentPrefix, pds.getInitializationFailTimeout());
        log.info("{}isolateInternalQueries: {}", indentPrefix, pds.isIsolateInternalQueries());
        log.info("{}allowPoolSuspension: {}", indentPrefix, pds.isAllowPoolSuspension());
        log.info("{}readOnly: {}", indentPrefix, pds.isReadOnly());
        log.info("{}registerMbeans: {}", indentPrefix, pds.isRegisterMbeans());
        log.info("{}validationTimeout: {}", indentPrefix, pds.getValidationTimeout());
        log.info("{}leakDetectionThreshold: {}", indentPrefix, pds.getLeakDetectionThreshold());

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
}
