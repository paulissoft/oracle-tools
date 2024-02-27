package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.pool.HikariPool;
import java.sql.SQLException;
import java.util.concurrent.ConcurrentHashMap;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.DirectFieldAccessor;


@Slf4j
public class SimplePoolDataSourceHikari extends HikariDataSource implements SimplePoolDataSource {

    private final static boolean singleSessionProxyModel = false;
    
    private final static boolean useFixedUsernamePassword = true;

    private static final String POOL_NAME_PREFIX = "HikariPool";
         
    // for join(), valus is irrelevant
    private static final ConcurrentHashMap<SimplePoolDataSource, Boolean> cachedPoolDataSourceConfigurations = new ConcurrentHashMap<>();

    private static final PoolDataSourceStatistics poolDataSourceStatisticsTotal =
        new PoolDataSourceStatistics(() -> POOL_NAME_PREFIX + ": (all)",
                                     PoolDataSourceStatistics.poolDataSourceStatisticsGrandTotal);

    private final PoolDataSourceStatistics poolDataSourceStatistics =
        new PoolDataSourceStatistics(() -> this.getPoolName() + ": (all)",
                                     poolDataSourceStatisticsTotal,
                                     this::isClosed,
                                     this);

    // for test purposes
    static void clear() {
        cachedPoolDataSourceConfigurations.clear();
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
        
    public void join(final SimplePoolDataSource pds, final String schema) {
        final PoolDataSourceConfigurationId otherCommonId =
            new PoolDataSourceConfigurationId(pds.getPoolDataSourceConfiguration(), true);
        final PoolDataSourceConfigurationId thisCommonId =
            new PoolDataSourceConfigurationId(this.getPoolDataSourceConfiguration(), true);
        final Boolean found = cachedPoolDataSourceConfigurations.searchKeys(Long.MAX_VALUE, (k) -> {
                final PoolDataSourceConfigurationId cachedCommonId =
                    new PoolDataSourceConfigurationId(k.getPoolDataSourceConfiguration(), true);
            
                if (cachedCommonId.equals(thisCommonId)) {
                    return true;
                }
                return null;
            });
        final boolean firstPds = found == null;
        
        log.debug(">join(id={}, firstPds={})", pds.toString(), firstPds);

        try {
            try {
                assert(otherCommonId.equals(thisCommonId));
            } catch (AssertionError ex) {
                log.error("otherCommonId: {}", otherCommonId);
                log.error("thisCommonId: {}", thisCommonId);
                throw ex;
            }
        
            cachedPoolDataSourceConfigurations.computeIfAbsent(pds, k -> { join(pds, schema, firstPds); return false; });
        } finally {
            log.debug("<join()");
        }
    }

    public String getPoolNamePrefix() {
        return POOL_NAME_PREFIX;
    }

    public void updatePoolSizes(final SimplePoolDataSource pds) throws SQLException {
        updatePoolSizes((PoolDataSourceConfigurationHikari) pds.getPoolDataSourceConfiguration());
    }

    private void updatePoolSizes(final PoolDataSourceConfigurationHikari pds) throws SQLException {
        log.info(">updatePoolSizes()");

        try {
            log.info("pool sizes before: minimum/maximum: {}/{}",
                     getMinimumIdle(),
                     getMaximumPoolSize());

            int oldSize, newSize;

            newSize = pds.getMinimumIdle();
            oldSize = getMinimumIdle();

            log.info("minimum pool sizes before setting it: old/new: {}/{}",
                     oldSize,
                     newSize);

            if (newSize >= 0) {                
                setMinimumIdle(newSize + Integer.max(oldSize, 0));
            }
                
            newSize = pds.getMaximumPoolSize();
            oldSize = getMaximumPoolSize();

            log.info("maximum pool sizes before setting it: old/new: {}/{}",
                     oldSize,
                     newSize);

            if (newSize >= 0) {
                setMaximumPoolSize(newSize + Integer.max(oldSize, 0));
            }
        } finally {
            log.info("pool sizes after: minimum/maximum: {}/{}",
                     getMinimumIdle(),
                     getMaximumPoolSize());
            
            log.info("<updatePoolSizes()");
        }
    }

    /*TBD*/
    /*
    public String getUrl() {
        return getJdbcUrl();
    }
    
    public void setUrl(String url) {
        setJdbcUrl(url);
    }
    */

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

    @Override
    public void close() {
        // this pool data source should never close
    }

    public boolean isClosed() {
        // when there is at least one attached pool (samen commonId) not closed: return false
        final PoolDataSourceConfigurationId thisCommonId =
            new PoolDataSourceConfigurationId(this.getPoolDataSourceConfiguration(), true);
        final Boolean found = cachedPoolDataSourceConfigurations.searchKeys(Long.MAX_VALUE, (k) -> {
                final PoolDataSourceConfigurationId cachedCommonId =
                    new PoolDataSourceConfigurationId(k.getPoolDataSourceConfiguration(), true);
            
                if (cachedCommonId.equals(thisCommonId) && !k.isClosed()) {
                    return true;
                }
                return null;
            });

        return found == null; // all closed
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
