package com.paulissoft.pato.jdbc;

// import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLTransientConnectionException;
import lombok.NonNull;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class SmartPoolDataSourceHikari
    extends SmartPoolDataSource<SimplePoolDataSourceHikari>
    implements SimplePoolDataSource, PoolDataSourcePropertiesSettersHikari, PoolDataSourcePropertiesGettersHikari {

    static final long MIN_CONNECTION_TIMEOUT = 250; // milliseconds for one pool, so twice this number for two

    static final String REX_CONNECTION_TIMEOUT = "^.+ - Connection is not available, request timed out after \\d+ms\\.$";
    
    private static final String POOL_NAME_PREFIX = SmartPoolDataSourceHikari.class.getSimpleName();

    // Statistics at level 2
    private static final PoolDataSourceStatistics poolDataSourceStatisticsTotal
        = new PoolDataSourceStatistics(() -> POOL_NAME_PREFIX + ": (all)",
                                       PoolDataSourceStatistics.poolDataSourceStatisticsGrandTotal);

    /*
     * Constructors
     */
    
    public SmartPoolDataSourceHikari() {
        this(null);
    }

    public SmartPoolDataSourceHikari(final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari) {
        // configuration is supposed to be set completely
        super(SimplePoolDataSourceHikari::new, poolDataSourceConfigurationHikari);

        final PoolDataSourceStatistics parentPoolDataSourceStatistics =
            new PoolDataSourceStatistics(() -> getPoolName() + ": (all)",
                                         poolDataSourceStatisticsTotal,
                                         () -> !isOpen(),
                                         this::getWithPoolName);
        
        getPoolDataSource().determinePoolDataSourceStatistics(parentPoolDataSourceStatistics);

        assert getPoolDataSource().getPoolDataSourceStatistics() != null : "Pool statistics must be activated.";

        final SimplePoolDataSourceHikari poolDataSourceOverflow = getPoolDataSourceOverflow();

        if (poolDataSourceOverflow != null) {
            poolDataSourceOverflow.determinePoolDataSourceStatistics(parentPoolDataSourceStatistics);
        }
    }

    public SmartPoolDataSourceHikari(String driverClassName,
                                     String url,
                                     String username,
                                     String password,
                                     String type) {
        // configuration is set partially so just use the default constructor
        this();
        set(PoolDataSourceConfigurationHikari.build(driverClassName,
                                                    url,
                                                    username,
                                                    password,
                                                    type != null ? type : SmartPoolDataSourceHikari.class.getName()));
    }

    public SmartPoolDataSourceHikari(String driverClassName,
                                     String url,
                                     String username,
                                     String password,
                                     String type,
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
        this(PoolDataSourceConfigurationHikari.build(driverClassName,
                                                     url,
                                                     username,
                                                     password,
                                                     // cannot reference this before supertype constructor has been called,
                                                     // hence can not use this in constructor above
                                                     type != null ? type : SmartPoolDataSourceHikari.class.getName(),
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

    protected long getMinConnectionTimeout() {
        return MIN_CONNECTION_TIMEOUT;
    }

    protected void updatePool(@NonNull final SimplePoolDataSourceHikari poolDataSource,
                              final SimplePoolDataSourceHikari poolDataSourceOverflow) {        
        super.updatePool(poolDataSource, poolDataSourceOverflow);
        // is there an overflow?
        if (poolDataSourceOverflow != null) {
            // see https://github.com/brettwooldridge/HikariCP?tab=readme-ov-file#youre-probably-doing-it-wrong
            poolDataSourceOverflow.setIdleTimeout(10000); // minimum
            poolDataSourceOverflow.setMaxLifetime(30000); // minimum
        }        
    }
    
    protected interface ToOverrideHikari extends ToOverride {
        // setUsername(java.lang.String) in com.paulissoft.pato.jdbc.SmartPoolDataSourceHikari
        // cannot implement setUsername(java.lang.String) in com.zaxxer.hikari.HikariConfigMXBean:
        // overridden method does not throw java.sql.SQLException
        public void setUsername(String password) throws SQLException;

        // setPassword(java.lang.String) in com.paulissoft.pato.jdbc.SmartPoolDataSourceHikari
        // cannot implement setPassword(java.lang.String) in com.zaxxer.hikari.HikariConfigMXBean:
        // overridden method does not throw java.sql.SQLException
        public void setPassword(String password) throws SQLException;

        public int getMaximumPoolSize(); // may add the overflow

        public void setConnectionTimeout(long connectionTimeout);
    }

    // setXXX methods only (getPoolDataSourceSetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesSettersHikari.class, excludes=ToOverrideHikari.class) // do not delegate setPassword()
    private PoolDataSourcePropertiesSettersHikari getPoolDataSourceSetter() {
        try {
            switch (getState()) {
            case INITIALIZING:
                return getPoolDataSource();
            case CLOSED:
                throw new IllegalStateException("You can not use the pool once it is closed.");
            default:
                throw new IllegalStateException("The configuration of the pool is sealed once started.");
            }
        } catch (IllegalStateException ex) {
            log.error("Exception in getPoolDataSourceSetter(): {}", ex);
            throw ex;
        }
    }
        
    // getXXX methods only (getPoolDataSourceGetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesGettersHikari.class, excludes=ToOverrideHikari.class)
    private PoolDataSourcePropertiesGettersHikari getPoolDataSourceGetter() {
        try {
            switch (getState()) {
            case CLOSED:
                throw new IllegalStateException("You can not use the pool once it is closed.");
            default:
                return getPoolDataSource(); // as soon as the initializing phase is over, the actual pool data source should be used
            }
        } catch (IllegalStateException ex) {
            log.error("Exception in getPoolDataSourceGetter(): {}", ex);
            throw ex;
        }
    }

    // no getXXX() nor setXXX(), just the rest (getPoolDataSource() may return different values depending on state hence use a function)
    @Delegate(excludes={ PoolDataSourcePropertiesSettersHikari.class, PoolDataSourcePropertiesGettersHikari.class, ToOverrideHikari.class })
    @Override
    protected final SimplePoolDataSourceHikari getPoolDataSource() {
        return super.getPoolDataSource();
    }

    protected boolean getConnectionFailsDueToNoIdleConnections(final Exception ex) {
        return (ex instanceof SQLTransientConnectionException) && ex.getMessage().matches(REX_CONNECTION_TIMEOUT);
    }
    
    // methods defined in interface ToOverrideHikari
    public void setUsername(String username) {
        final SimplePoolDataSourceHikari poolDataSource = getPoolDataSource();

        try {
            poolDataSource.setUsername(username);
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    public void setPassword(String password) {
        final SimplePoolDataSourceHikari poolDataSource = getPoolDataSource();

        try {
            poolDataSource.setPassword(password);        
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    public PoolDataSourceConfiguration get() {
        return PoolDataSourceConfigurationHikari
            .builder()
            .driverClassName(getDriverClassName())
            .url(getJdbcUrl())
            .username(getUsername())
            .password(null) // do not copy password
            .type(this.getClass().getName())
            .poolName(null) // do not copy pool name
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

    public int getMaximumPoolSize() {
        final SimplePoolDataSourceHikari poolDataSource = getPoolDataSource();
        SimplePoolDataSourceHikari poolDataSourceOverflow;

        if (getState() == State.INITIALIZING || (poolDataSourceOverflow = getPoolDataSourceOverflow()) == null) {
            return poolDataSource.getMaximumPoolSize();
        } else {
            return poolDataSource.getMaximumPoolSize() + poolDataSourceOverflow.getMaximumPoolSize();
        }
    }
    
    public void setConnectionTimeout(long connectionTimeout) {
        final SimplePoolDataSourceHikari poolDataSource = getPoolDataSource();
        
        if (connectionTimeout < 2 * MIN_CONNECTION_TIMEOUT) { // both pools must have at least this minimum
            // if we subtract we will get an invalid value (less than minimum)
            throw new IllegalArgumentException(String.format("The connection timeout (%d) must be at least %d.",
                                                             connectionTimeout,
                                                             2 * MIN_CONNECTION_TIMEOUT));
        }
        poolDataSource.setConnectionTimeout(connectionTimeout);
    }
}
