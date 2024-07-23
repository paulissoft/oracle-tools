package com.paulissoft.pato.jdbc;

import java.sql.SQLException;
import java.sql.SQLTransientConnectionException;
import lombok.NonNull;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class SmartPoolDataSourceHikari
    extends SmartPoolDataSource<SimplePoolDataSourceHikari>
    implements SimplePoolDataSource, PoolDataSourcePropertiesSettersHikari, PoolDataSourcePropertiesGettersHikari {

    static final long MIN_CONNECTION_TIMEOUT = SimplePoolDataSourceHikari.MIN_CONNECTION_TIMEOUT; // milliseconds for one pool, so twice this number for two

    static final String REX_CONNECTION_TIMEOUT = "^.+ - Connection is not available, request timed out after \\d+ms\\.$";
    
    /*
     * Constructors
     */
    
    public SmartPoolDataSourceHikari() {
        super(SimplePoolDataSourceHikari::new);
    }

    public SmartPoolDataSourceHikari(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari) {
        // configuration is supposed to be set completely
        super(SimplePoolDataSourceHikari::new, poolDataSourceConfigurationHikari);
    }

    public SmartPoolDataSourceHikari(String driverClassName,
                                     String url,
                                     String username,
                                     String password,
                                     String type) {
        // configuration is set partially so just use the default constructor
        this(PoolDataSourceConfigurationHikari.build(driverClassName,
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

    protected interface ToOverrideHikari extends ToOverride {
        // setUsername(java.lang.String) in com.paulissoft.pato.jdbc.SmartPoolDataSourceHikari
        // cannot implement setUsername(java.lang.String) in com.zaxxer.hikari.HikariConfigMXBean:
        // overridden method does not throw java.sql.SQLException
        void setUsername(String password) /*throws SQLException*/;

        // setPassword(java.lang.String) in com.paulissoft.pato.jdbc.SmartPoolDataSourceHikari
        // cannot implement setPassword(java.lang.String) in com.zaxxer.hikari.HikariConfigMXBean:
        // overridden method does not throw java.sql.SQLException
        void setPassword(String password) /*throws SQLException*/;

        int getMaximumPoolSize(); // may add the overflow

        void setConnectionTimeout(long connectionTimeout);
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
                throw new IllegalStateException("The configuration of the pool is sealed once initialized or started.");
            }
        } catch (IllegalStateException ex) {
            log.error("Exception in getPoolDataSourceSetter():", ex);
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
                return getPoolDataSource();
            }
        } catch (IllegalStateException ex) {
            log.error("Exception in getPoolDataSourceGetter():", ex);
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

        if (getState() == State.INITIALIZING || getState() == State.INITIALIZED || (poolDataSourceOverflow = getPoolDataSourceOverflow()) == null) {
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
    
    @Override
    protected void initializeOverflowPool(final PoolDataSourceConfiguration poolDataSourceConfiguration,
					  final int maxPoolSizeOverflow) throws SQLException {
	super.initializeOverflowPool(poolDataSourceConfiguration, maxPoolSizeOverflow);
	
        final SimplePoolDataSourceHikari poolDataSourceOverflow = getPoolDataSourceOverflow();

        poolDataSourceOverflow.setConnectionTimeout(poolDataSourceOverflow.getConnectionTimeout() - getMinConnectionTimeout());

        if (isOverflowStatic()) {
            poolDataSourceOverflow.setMinimumIdle(maxPoolSizeOverflow);
        } else {
            // settings to keep the overflow pool data source as empty as possible
            // see https://github.com/brettwooldridge/HikariCP?tab=readme-ov-file#youre-probably-doing-it-wrong
            poolDataSourceOverflow.setMinimumIdle(0);
            poolDataSourceOverflow.setIdleTimeout(10000); // minimum
            poolDataSourceOverflow.setMaxLifetime(30000); // minimum
        }
    }
}
