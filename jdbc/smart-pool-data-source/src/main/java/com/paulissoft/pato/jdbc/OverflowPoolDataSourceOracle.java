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

    /*
     * Constructor
     */

    public OverflowPoolDataSourceOracle() {
        super(SimplePoolDataSourceOracle::new);
    }

    protected void updatePool(@NonNull final SimplePoolDataSourceOracle poolDataSource,
                              @NonNull final SimplePoolDataSourceOracle poolDataSourceOverflow) {
        final int maxPoolSizeOverflow = poolDataSource.getMaxPoolSize() - poolDataSource.getMinPoolSize();

        // is there an overflow?
        if (maxPoolSizeOverflow > 0) {
            try {
                // copy the properties
                final PoolDataSourceConfigurationOracle pdsConfig =
                    (PoolDataSourceConfigurationOracle) poolDataSource.get();

                poolDataSourceOverflow.set(pdsConfig); // only password is not set but there is an overriden method setPassword()

                // settings to let the pool data source fail fast so it can use the overflow
                poolDataSource.setMaxPoolSize(poolDataSource.getMaxPoolSize() - maxPoolSizeOverflow);
                poolDataSource.setConnectionWaitTimeout(1); // minimum

                // settings to keep the overflow pool data source as empty as possible
                poolDataSourceOverflow.setMaxPoolSize(maxPoolSizeOverflow);
                poolDataSourceOverflow.setMinPoolSize(0);
                poolDataSourceOverflow.setInitialPoolSize(0);
            } catch (SQLException ex) {
                throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
            }                
        }        
    }
    
    protected interface ToOverrideOracle extends ToOverride {
        // need to set the password twice since getPassword is deprecated
        public void setPassword(String password) throws SQLException;
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
        getPoolDataSourceOverflow().setPassword(password); // get get() call does not copy the password (getPassword() is deprecated)
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
    protected Connection getConnectionOverflow() throws SQLException {
        final Connection conn = super.getConnectionOverflow();
        
        // The setInvalid method of the ValidConnection interface indicates that a connection should be removed from the connection pool when it is closed. 
        ((ValidConnection) conn).setInvalid();

        return conn;
    }
}
