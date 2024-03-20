package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.pool.HikariPool;
import java.sql.SQLException;
import java.util.concurrent.ConcurrentHashMap;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.DirectFieldAccessor;

@Slf4j
public class SimplePoolDataSourceHikari extends HikariDataSource implements SimplePoolDataSource {

    private static final String POOL_NAME_PREFIX = "HikariPool";
         
    private static final PoolDataSourceStatistics poolDataSourceStatisticsTotal
        = new PoolDataSourceStatistics(() -> POOL_NAME_PREFIX + ": (all)",
                                       PoolDataSourceStatistics.poolDataSourceStatisticsGrandTotal);
       
    private final PoolDataSourceStatistics poolDataSourceStatistics =
        new PoolDataSourceStatistics(() -> this.getPoolName() + ": (all)",
                                     poolDataSourceStatisticsTotal,
                                     this::isClosed,
                                     this::getPoolDataSourceConfiguration);
    
    // for join(), value: pool data source open (true) or not (false)
    private final ConcurrentHashMap<PoolDataSourceConfiguration, Boolean> cachedPoolDataSourceConfigurations = new ConcurrentHashMap<>();

    // for test purposes
    static void clear() {
        poolDataSourceStatisticsTotal.reset();
    }
    
    // constructor
    private SimplePoolDataSourceHikari(final PoolDataSourceConfigurationHikari pdsConfigurationHikari) {
        // super();
        pdsConfigurationHikari.copy(this);
    }

    public static SimplePoolDataSourceHikari build(final PoolDataSourceConfiguration pdsConfiguration) {
        return new SimplePoolDataSourceHikari((PoolDataSourceConfigurationHikari)pdsConfiguration);
    }

    public PoolDataSourceConfiguration getPoolDataSourceConfiguration() {
        return getPoolDataSourceConfiguration(true);
    }
    
    public PoolDataSourceConfiguration getPoolDataSourceConfiguration(final boolean excludeNonIdConfiguration) {
        return PoolDataSourceConfigurationHikari
            .builder()
            .driverClassName(getDriverClassName())
            .url(getJdbcUrl())
            .username(getUsername())
            .password(excludeNonIdConfiguration ? null : getPassword())
            .type(SimplePoolDataSourceHikari.class.getName())
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
        
    public void join(final PoolDataSourceConfiguration pds) {
        final PoolDataSourceConfigurationCommonId otherCommonId =
            new PoolDataSourceConfigurationCommonId(pds);
        final PoolDataSourceConfigurationCommonId thisCommonId =
            new PoolDataSourceConfigurationCommonId(this.getPoolDataSourceConfiguration());
        final boolean firstPds = cachedPoolDataSourceConfigurations.isEmpty();
        
        log.debug(">join(id={}, firstPds={})", pds.toString(), firstPds);

        try {
            try {
                assert(otherCommonId.equals(thisCommonId));
            } catch (AssertionError ex) {
                log.error("otherCommonId: {}", otherCommonId);
                log.error("thisCommonId: {}", thisCommonId);
                throw ex;
            }
        
            cachedPoolDataSourceConfigurations.computeIfAbsent(pds, k -> { join(pds, firstPds); return false; });
        } finally {
            log.debug("<join()");
        }
    }

    public String getPoolNamePrefix() {
        return POOL_NAME_PREFIX;
    }

    public void updatePoolSizes(final PoolDataSourceConfiguration pds) throws SQLException {
        updatePoolSizes((PoolDataSourceConfigurationHikari)pds);
    }
    
    private void updatePoolSizes(final PoolDataSourceConfigurationHikari pds) throws SQLException {
        log.debug(">updatePoolSizes({})", pds);

        try {
            log.debug("pool sizes before: minimum/maximum: {}/{}",
                      getMinimumIdle(),
                      getMaximumPoolSize());

            int oldSize, newSize;

            newSize = pds.getMinimumIdle();
            oldSize = getMinimumIdle();

            log.debug("minimum pool sizes before setting it: old/new: {}/{}",
                      oldSize,
                      newSize);

            if (newSize >= 0) {                
                setMinimumIdle(newSize + Integer.max(oldSize, 0));
            }
                
            newSize = pds.getMaximumPoolSize();
            oldSize = getMaximumPoolSize();

            log.debug("maximum pool sizes before setting it: old/new: {}/{}",
                      oldSize,
                      newSize);

            if (newSize >= 0) {
                setMaximumPoolSize(newSize + Integer.max(oldSize, 0));
            }
        } finally {
            log.debug("pool sizes after: minimum/maximum: {}/{}",
                      getMinimumIdle(),
                      getMaximumPoolSize());
            
            log.debug("<updatePoolSizes()");
        }
    }

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

    public void open(final PoolDataSourceConfiguration pds) {
        log.debug("open({})", pds);
        
        cachedPoolDataSourceConfigurations.computeIfPresent(pds, (k, v) -> true);
    }

    public void close(final PoolDataSourceConfiguration pds) {
        log.debug("close({})", pds);
                
        cachedPoolDataSourceConfigurations.computeIfPresent(pds, (k, v) -> false);
    }
 
    @Override
    public void close() {
        // this pool data source should never close
    }

    public boolean isClosed() {
        log.debug(">isClosed()");
        
        // when there is at least one attached pool open: return false
        final Boolean found = cachedPoolDataSourceConfigurations.containsValue(true);

        log.debug("<isClosed() = {}", !found);

        return !found; // all closed
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
}
