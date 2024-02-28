package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.pool.HikariPool;
import java.sql.SQLException;
import java.util.concurrent.atomic.AtomicBoolean;
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
    private final ConcurrentHashMap<PoolDataSourceConfiguration, AtomicBoolean> cachedPoolDataSourceConfigurations = new ConcurrentHashMap<>();

    // for test purposes
    static void clear() {
        poolDataSourceStatisticsTotal.reset();
    }
    
    // constructor
    private SimplePoolDataSourceHikari(final PoolDataSourceConfigurationHikari pdsConfigurationHikari) {
        // super();
        
        int nr = 0;
        final int maxNr = 18;
        
        do {
            try {
                switch(nr) {
                case 0: setDriverClassName(pdsConfigurationHikari.getDriverClassName()); break;
                case 1: setJdbcUrl(pdsConfigurationHikari.getUrl()); break;
                case 2: setUsername(pdsConfigurationHikari.getUsername()); break;
                case 3: setPassword(pdsConfigurationHikari.getPassword()); break;
                case 4: /* set in super() via join() */ break;
                case 5: setMaximumPoolSize(pdsConfigurationHikari.getMaximumPoolSize()); break;
                case 6: setMinimumIdle(pdsConfigurationHikari.getMinimumIdle()); break;
                case 7: setAutoCommit(pdsConfigurationHikari.isAutoCommit()); break;
                case 8: setConnectionTimeout(pdsConfigurationHikari.getConnectionTimeout()); break;
                case 9: setIdleTimeout(pdsConfigurationHikari.getIdleTimeout()); break;
                case 10: setMaxLifetime(pdsConfigurationHikari.getMaxLifetime()); break;
                case 11: setConnectionTestQuery(pdsConfigurationHikari.getConnectionTestQuery()); break;
                case 12: setInitializationFailTimeout(pdsConfigurationHikari.getInitializationFailTimeout()); break;
                case 13: setIsolateInternalQueries(pdsConfigurationHikari.isIsolateInternalQueries()); break;
                case 14: setAllowPoolSuspension(pdsConfigurationHikari.isAllowPoolSuspension()); break;
                case 15: setReadOnly(pdsConfigurationHikari.isReadOnly()); break;
                case 16: setRegisterMbeans(pdsConfigurationHikari.isRegisterMbeans()); break;
                case 17: setValidationTimeout(pdsConfigurationHikari.getValidationTimeout()); break;
                case 18: setLeakDetectionThreshold(pdsConfigurationHikari.getLeakDetectionThreshold()); break;
                default:
                    throw new IllegalArgumentException(String.format("Wrong value for nr (%d): must be between 0 and %d", nr, maxNr));
                }
            } catch (Exception ex) {
                log.warn("nr: {}; exception: {}", nr, SimplePoolDataSource.exceptionToString(ex));
            }
        } while (++nr <= maxNr);
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
        final PoolDataSourceConfigurationId otherCommonId =
            new PoolDataSourceConfigurationId(pds, true);
        final PoolDataSourceConfigurationId thisCommonId =
            new PoolDataSourceConfigurationId(this.getPoolDataSourceConfiguration(), true);
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
        
            cachedPoolDataSourceConfigurations.computeIfAbsent(pds, k -> { join(pds, firstPds); return new AtomicBoolean(false); });
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
        
        cachedPoolDataSourceConfigurations.computeIfPresent(pds, (k, v) -> v).set(true);
    }

    public void close(final PoolDataSourceConfiguration pds) {
        log.debug("close({})", pds);
                
        cachedPoolDataSourceConfigurations.computeIfPresent(pds, (k, v) -> v).set(false);
    }
 
    @Override
    public void close() {
        // this pool data source should never close
    }

    public boolean isClosed() {
        log.debug(">isClosed()");
        
        // when there is at least one attached pool open: return false
        final Boolean found = cachedPoolDataSourceConfigurations.searchEntries(Long.MAX_VALUE, (e) -> {
                log.debug("key: {}; value: {}", e.getKey(), e.getValue().get());
                if (e.getValue().get()) {                    
                    return true;
                }
                return null;
            });

        log.debug("<isClosed() = {}", found == null);

        return found == null; // all closed
    }

    public void show() {
        log.info("pool: {}", getPoolName());

        /* info from PoolDataSourceConfiguration */
        log.info("driverClassName: {}", getDriverClassName());
        log.info("url: {}", getJdbcUrl());
        log.info("username: {}", getUsername());
        // log.info("password: {}", getPassword());

        /* info from PoolDataSourceConfigurationHikari */
        log.info("maximumPoolSize: {}", getMaximumPoolSize());
        log.info("minimumIdle: {}", getMinimumIdle());
        log.info("dataSourceClassName: {}", getDataSourceClassName());
        log.info("autoCommit: {}", isAutoCommit());
        log.info("connectionTimeout: {}", getConnectionTimeout());
        log.info("idleTimeout: {}", getIdleTimeout());
        log.info("maxLifetime: {}", getMaxLifetime());
        log.info("connectionTestQuery: {}", getConnectionTestQuery());
        log.info("initializationFailTimeout: {}", getInitializationFailTimeout());
        log.info("isolateInternalQueries: {}", isIsolateInternalQueries());
        log.info("allowPoolSuspension: {}", isAllowPoolSuspension());
        log.info("readOnly: {}", isReadOnly());
        log.info("registerMbeans: {}", isRegisterMbeans());
        log.info("validationTimeout: {}", getValidationTimeout());
        log.info("leakDetectionThreshold: {}", getLeakDetectionThreshold());
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
