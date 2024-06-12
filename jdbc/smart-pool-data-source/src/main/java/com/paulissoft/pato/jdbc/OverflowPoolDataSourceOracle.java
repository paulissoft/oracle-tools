package com.paulissoft.pato.jdbc;

// import java.time.Duration;
import java.sql.Connection;
import java.sql.SQLException;
import oracle.ucp.jdbc.ValidConnection;
import lombok.NonNull;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class OverflowPoolDataSourceOracle
    extends OverflowPoolDataSource<SimplePoolDataSourceOracle, PoolDataSourceConfigurationOracle>
    implements SimplePoolDataSource, PoolDataSourcePropertiesSettersOracle, PoolDataSourcePropertiesGettersOracle {

    static final long MIN_CONNECTION_TIMEOUT = 0; // milliseconds for one pool, so twice this number for two

    static final String REX_CONNECTION_TIMEOUT = "^UCP-29: Failed to get a connection$";
    
    /*
     * Constructor
     */

    public OverflowPoolDataSourceOracle() {
        super(SimplePoolDataSourceOracle::new, new PoolDataSourceConfigurationOracle());
    }

    public OverflowPoolDataSourceOracle(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle) {
        super(SimplePoolDataSourceOracle::new, poolDataSourceConfigurationOracle);
    }

    public OverflowPoolDataSourceOracle(String url,
                                        String username,
                                        String password,
                                        String type)
    {
        this(PoolDataSourceConfigurationOracle.build(url,
                                                     username,
                                                     password,
                                                     type != null ? type : OverflowPoolDataSourceOracle.class.getName()));
    }

    public OverflowPoolDataSourceOracle(String url,
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
                                                     type != null ? type : OverflowPoolDataSourceOracle.class.getName(),
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
    }

    // setXXX methods only (getPoolDataSourceSetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesSettersOracle.class, excludes=ToOverrideOracle.class)
    private PoolDataSourcePropertiesSettersOracle getPoolDataSourceSetter() {
        try {
            switch (getState()) {
            case INITIALIZING:
                return getPoolDataSourceConfiguration();
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
                return getPoolDataSourceConfiguration(); // as soon as the initializing phase is over, the actual pool data source should be used
            }
        } catch (IllegalStateException ex) {
            log.error("Exception in getPoolDataSourceGetter(): {}", ex);
            throw ex;
        }
    }
    
    // no getXXX() nor setXXX(), just the rest (getPoolDataSource() may return different values depending on state hence use a function)
    @Delegate(excludes={ PoolDataSourcePropertiesSettersOracle.class, PoolDataSourcePropertiesGettersOracle.class, ToOverrideOracle.class })
    @Override
    protected SimplePoolDataSourceOracle getPoolDataSource() {
        return super.getPoolDataSource();
    }

    // methods defined in interface ToOverrideOracle
    
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

    protected boolean getConnectionFailsDueToNoIdleConnections(final SimplePoolDataSourceOracle pds, final Exception ex) {
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
