package com.paulissoft.pato.jdbc;

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

    final static int MIN_CONNECTION_WAIT_TIMEOUT = OverflowPoolDataSource.MIN_CONNECTION_WAIT_TIMEOUT;
    /*
     * Constructor
     */

    public OverflowPoolDataSourceOracle() {
        super(SimplePoolDataSourceOracle::new);
    }

    protected void updatePool(@NonNull final SimplePoolDataSourceOracle poolDataSource,
                              final SimplePoolDataSourceOracle poolDataSourceOverflow) {
        // is there an overflow?
        if (poolDataSourceOverflow != null) {
            final int maxPoolSizeOverflow = poolDataSource.getMaxPoolSize() - poolDataSource.getMinPoolSize();
            
            try {
                // copy the properties
                final PoolDataSourceConfigurationOracle pdsConfig =
                    (PoolDataSourceConfigurationOracle) poolDataSource.get();

                poolDataSourceOverflow.set(pdsConfig); // only password is not set but there is an overriden method setPassword()

                // settings to let the pool data source fail fast so it can use the overflow
                poolDataSource.setMaxPoolSize(pdsConfig.getMinPoolSize());
                poolDataSource.setConnectionWaitTimeout(MIN_CONNECTION_WAIT_TIMEOUT); // minimum

                // settings to keep the overflow pool data source as empty as possible
                poolDataSourceOverflow.setMaxPoolSize(maxPoolSizeOverflow);
                poolDataSourceOverflow.setConnectionWaitTimeout(pdsConfig.getConnectionWaitTimeout() - MIN_CONNECTION_WAIT_TIMEOUT);
                poolDataSourceOverflow.setMinPoolSize(0);
                poolDataSourceOverflow.setInitialPoolSize(0);
                
                // set pool name
                if (pdsConfig.getPoolName() == null || pdsConfig.getPoolName().isEmpty()) {
                    pdsConfig.determineConnectInfo();
                    poolDataSource.setPoolName(this.getClass().getSimpleName() + "-" + pdsConfig.getSchema());
                    poolDataSourceOverflow.setPoolName(this.getClass().getSimpleName() + "-" + pdsConfig.getSchema());
                }
                poolDataSourceOverflow.setPoolName(poolDataSourceOverflow.getPoolName() + "-overflow");
            } catch (SQLException ex) {
                throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
            }                
        }        
    }
    
    protected interface ToOverrideOracle extends ToOverride {
        // need to set the password twice since getPassword is deprecated
        public void setPassword(String password) throws SQLException;

        @Deprecated
        public void setConnectionWaitTimeout(int connectionWaitTimeout) throws SQLException;

        @Deprecated
        public int getConnectionWaitTimeout();
    }

    // setXXX methods only (getPoolDataSourceSetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesSettersOracle.class, excludes=ToOverrideOracle.class) // do not delegate setPassword()
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

    public void setPassword(String password) throws SQLException {
        getPoolDataSource().setPassword(password);

        final SimplePoolDataSourceOracle poolDataSourceOverflow = getPoolDataSourceOverflow();

        if (poolDataSourceOverflow != null) {
            poolDataSourceOverflow.setPassword(password); // get get() call does not copy the password (getPassword() is deprecated)
        }
    }

    @Deprecated
    public void setConnectionWaitTimeout(int connectionWaitTimeout) throws SQLException {
        if (connectionWaitTimeout == MIN_CONNECTION_WAIT_TIMEOUT) {
            // if we subtract 1 we will get 0 which is not a timeout but just a de-activation
            throw new IllegalArgumentException(String.format("The connection wait timeout (%d) must be 0 (inactive) or at least 2.", connectionWaitTimeout));
        }
        getPoolDataSource().setConnectionWaitTimeout(connectionWaitTimeout);
    }

    @Deprecated
    public int getConnectionWaitTimeout() {
        final int connectionWaitTimeout = getPoolDataSource().getConnectionWaitTimeout();
        SimplePoolDataSourceOracle poolDataSourceOverflow;

        if (getState() == State.INITIALIZING || (poolDataSourceOverflow = getPoolDataSourceOverflow()) == null) {            
            return connectionWaitTimeout;
        }

        return connectionWaitTimeout + poolDataSourceOverflow.getConnectionWaitTimeout();
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
