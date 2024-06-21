package com.paulissoft.pato.jdbc;

// import java.time.Duration;
import java.sql.Connection;
import java.sql.SQLException;
import oracle.ucp.jdbc.ValidConnection;
// import lombok.NonNull;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class SmartPoolDataSourceOracle
    extends SmartPoolDataSource<SimplePoolDataSourceOracle>
    implements SimplePoolDataSource, PoolDataSourcePropertiesSettersOracle, PoolDataSourcePropertiesGettersOracle {

    static final long MIN_CONNECTION_TIMEOUT = 0; // milliseconds for one pool, so twice this number for two

    static final String REX_CONNECTION_TIMEOUT = "^UCP-29: Failed to get a connection$";
    
    private static final String POOL_NAME_PREFIX = SmartPoolDataSourceOracle.class.getSimpleName();

    // Statistics at level 2
    private static final PoolDataSourceStatistics poolDataSourceStatisticsTotal
        = new PoolDataSourceStatistics(() -> POOL_NAME_PREFIX + ": (all)",
                                       PoolDataSourceStatistics.poolDataSourceStatisticsGrandTotal);

    /*
     * Constructor
     */

    public SmartPoolDataSourceOracle() {
        this(null);
    }

    public SmartPoolDataSourceOracle(final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle) {
        // configuration is supposed to be set completely
        super(SimplePoolDataSourceOracle::new, poolDataSourceConfigurationOracle);

        final PoolDataSourceStatistics parentPoolDataSourceStatistics =
            new PoolDataSourceStatistics(() -> getPoolName() + ": (all)",
                                         poolDataSourceStatisticsTotal,
                                         () -> !isOpen(),
                                         this::getWithPoolName);
        
        getPoolDataSource().determinePoolDataSourceStatistics(parentPoolDataSourceStatistics); 

        assert getPoolDataSource().getPoolDataSourceStatistics() != null : "Pool statistics must be activated.";

        final SimplePoolDataSourceOracle poolDataSourceOverflow = getPoolDataSourceOverflow();

        if (poolDataSourceOverflow != null) {
            poolDataSourceOverflow.determinePoolDataSourceStatistics(parentPoolDataSourceStatistics);
        }
   }

    public SmartPoolDataSourceOracle(String url,
                                     String username,
                                     String password,
                                     String type)
    {
        this();
        // configuration is set partially so just use the default constructor
        set(PoolDataSourceConfigurationOracle.build(url,
                                                    username,
                                                    password,
                                                    type != null ? type : SmartPoolDataSourceOracle.class.getName()));
    }

    public SmartPoolDataSourceOracle(String url,
                                     String username,
                                     String password,
                                     String type,
                                     String connectionPoolName,
                                     int initialPoolSize,
                                     int minPoolSize,
                                     int maxPoolSize,
                                     String connectionFactoryClassName,
                                     boolean validateConnectionOnBorrow,
                                     int abandonedConnectionTimeout,
                                     int timeToLiveConnectionTimeout,
                                     int inactiveConnectionTimeout,
                                     int timeoutCheckInterval,
                                     int maxStatements,
                                     long connectionWaitDurationInMillis,
                                     long maxConnectionReuseTime,
                                     int secondsToTrustIdleConnection,
                                     int connectionValidationTimeout)
    {
        this(PoolDataSourceConfigurationOracle.build(url,
                                                     username,
                                                     password,
                                                     // cannot reference this before supertype constructor has been called,
                                                     // hence can not use this in constructor above
                                                     type != null ? type : SmartPoolDataSourceOracle.class.getName(),
                                                     connectionPoolName,
                                                     initialPoolSize,
                                                     minPoolSize,
                                                     maxPoolSize,
                                                     connectionFactoryClassName,
                                                     validateConnectionOnBorrow,
                                                     abandonedConnectionTimeout,
                                                     timeToLiveConnectionTimeout,
                                                     inactiveConnectionTimeout,
                                                     timeoutCheckInterval,
                                                     maxStatements,
                                                     connectionWaitDurationInMillis,
                                                     maxConnectionReuseTime,
                                                     secondsToTrustIdleConnection,
                                                     connectionValidationTimeout));
    }

    protected long getMinConnectionTimeout() {
        return MIN_CONNECTION_TIMEOUT;
    }

    protected interface ToOverrideOracle extends ToOverride {
        public long getConnectionWaitDurationInMillis(); // may add the overflow

        public void setConnectionWaitDurationInMillis(long connectionWaitDurationInMillis) throws SQLException; // check for minimum

        public int getBorrowedConnectionsCount();
        
        public int getAvailableConnectionsCount();
    }

    // setXXX methods only (getPoolDataSourceSetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesSettersOracle.class, excludes=ToOverrideOracle.class)
    private PoolDataSourcePropertiesSettersOracle getPoolDataSourceSetter() {
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
    @Delegate(types=PoolDataSourcePropertiesGettersOracle.class, excludes=ToOverrideOracle.class)
    private PoolDataSourcePropertiesGettersOracle getPoolDataSourceGetter() {
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
    @Delegate(excludes={ PoolDataSourcePropertiesSettersOracle.class, PoolDataSourcePropertiesGettersOracle.class, ToOverrideOracle.class })
    @Override
    protected final SimplePoolDataSourceOracle getPoolDataSource() {
        return super.getPoolDataSource();
    }

    // methods defined in interface ToOverrideOracle
    
    public PoolDataSourceConfiguration get() {
        return PoolDataSourceConfigurationOracle
            .builder()
            .driverClassName(null)
            .url(getURL())
            .username(getUsername())
            .password(null) // do not copy password
            .type(this.getClass().getName())
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

    public long getConnectionWaitDurationInMillis() {
        final SimplePoolDataSourceOracle poolDataSource = getPoolDataSource();
        SimplePoolDataSourceOracle poolDataSourceOverflow;

        if (getState() == State.INITIALIZING || (poolDataSourceOverflow = getPoolDataSourceOverflow()) == null) {
            return poolDataSource.getConnectionWaitDurationInMillis();
        } else {
            return poolDataSource.getConnectionWaitDurationInMillis() + poolDataSourceOverflow.getConnectionWaitDurationInMillis();
        }
    }

    public void setConnectionWaitDurationInMillis(long connectionWaitDurationInMillis) throws SQLException {
        final SimplePoolDataSourceOracle poolDataSource = getPoolDataSource();
        
        if (connectionWaitDurationInMillis < 2 * MIN_CONNECTION_TIMEOUT) { // both pools must have at least this minimum
            // if we subtract we will get an invalid value (less than minimum)
            throw new IllegalArgumentException(String.format("The connection wait duration in milliseconds (%d) must be at least %d.",
                                                             connectionWaitDurationInMillis,
                                                             2 * MIN_CONNECTION_TIMEOUT));
        }
        poolDataSource.setConnectionWaitDurationInMillis(connectionWaitDurationInMillis);
    }

    public int getBorrowedConnectionsCount() {
        final SimplePoolDataSourceOracle poolDataSource = getPoolDataSource();
        SimplePoolDataSourceOracle poolDataSourceOverflow;

        if (getState() == State.INITIALIZING || (poolDataSourceOverflow = getPoolDataSourceOverflow()) == null) {
            return poolDataSource.getBorrowedConnectionsCount();
        } else {
            return poolDataSource.getBorrowedConnectionsCount() + poolDataSourceOverflow.getBorrowedConnectionsCount();
        }
    }
        
    public int getAvailableConnectionsCount() {
        final SimplePoolDataSourceOracle poolDataSource = getPoolDataSource();
        SimplePoolDataSourceOracle poolDataSourceOverflow;

        if (getState() == State.INITIALIZING || (poolDataSourceOverflow = getPoolDataSourceOverflow()) == null) {
            return poolDataSource.getAvailableConnectionsCount();
        } else {
            return poolDataSource.getAvailableConnectionsCount() + poolDataSourceOverflow.getAvailableConnectionsCount();
        }
    }

    protected boolean getConnectionFailsDueToNoIdleConnections(final Exception ex) {
        return (ex instanceof SQLException) && ex.getMessage().matches(REX_CONNECTION_TIMEOUT);
    }

    protected Connection getConnection(final boolean useOverflow) throws SQLException {
        final Connection conn = super.getConnection(useOverflow);
            
        if (useOverflow) {
            // The setInvalid method of the ValidConnection interface
            // indicates that a connection should be removed from the connection pool when it is closed. 
            ((ValidConnection) conn).setInvalid();
        }

        return conn;
    }
}
