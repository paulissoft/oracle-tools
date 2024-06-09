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
    extends OverflowPoolDataSource<SimplePoolDataSourceOracle>
    implements SimplePoolDataSource, PoolDataSourcePropertiesSettersOracle, PoolDataSourcePropertiesGettersOracle {

    final static long MIN_CONNECTION_TIMEOUT = 0; // milliseconds for one pool, so twice this number for two
    
    /*
     * Constructor
     */

    public OverflowPoolDataSourceOracle() {
        super(SimplePoolDataSourceOracle::new);
    }

    protected void updatePool(@NonNull final SimplePoolDataSourceOracle poolDataSource,
                              final SimplePoolDataSourceOracle poolDataSourceOverflow) {
        // copy the properties
        final PoolDataSourceConfigurationOracle pdsConfig =
            (PoolDataSourceConfigurationOracle) poolDataSource.get();

        try {
            // is there an overflow?
            if (poolDataSourceOverflow != null) {
                final int maxPoolSizeOverflow = poolDataSource.getMaxPoolSize() - poolDataSource.getMinPoolSize();
            
                poolDataSourceOverflow.set(pdsConfig); 
                // need to set password explicitly since combination get()/set() does not set the password
                poolDataSourceOverflow.setPassword(poolDataSource.getPassword());

                // settings to let the pool data source fail fast so it can use the overflow
                poolDataSource.setMaxPoolSize(pdsConfig.getMinPoolSize());
                poolDataSource.setConnectionWaitDurationInMillis(MIN_CONNECTION_TIMEOUT);

                // settings to keep the overflow pool data source as empty as possible
                poolDataSourceOverflow.setInitialPoolSize(0);                
                poolDataSourceOverflow.setMinPoolSize(0);
                poolDataSourceOverflow.setMaxPoolSize(maxPoolSizeOverflow);
                poolDataSourceOverflow.setConnectionWaitDurationInMillis(pdsConfig.getConnectionWaitDurationInMillis() - MIN_CONNECTION_TIMEOUT);
            }        

            // set pool name
            if (pdsConfig.getPoolName() == null || pdsConfig.getPoolName().isEmpty()) {
                pdsConfig.determineConnectInfo();
                poolDataSource.setPoolName(this.getClass().getSimpleName() + "-" + pdsConfig.getSchema());
                // use a different name to solve UCP-0
                if (poolDataSourceOverflow != null) {
                    poolDataSourceOverflow.setPoolName(poolDataSourceOverflow.getClass().getSimpleName() + "-" + pdsConfig.getSchema());
                }
            }
            if (poolDataSourceOverflow != null) {
                poolDataSourceOverflow.setPoolName(poolDataSourceOverflow.getPoolName() + "-overflow");
            }
        } catch (SQLException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
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
    
    @Override
    protected void tearDown() {
        if (getState() == State.CLOSED) { // already closed
            return;
        }
        
        // must get this info before it is actually closed since then getPoolDataSource() will return a error
        final SimplePoolDataSourceOracle poolDataSource = getPoolDataSource(); 
        
        // we are in a synchronized context
        super.tearDown();
        if (getState() == State.CLOSED) {
            poolDataSource.close();
        }
    }

    @Override
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
