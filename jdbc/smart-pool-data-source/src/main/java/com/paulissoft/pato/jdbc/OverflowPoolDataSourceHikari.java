package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariConfig;
import java.sql.SQLException;
import lombok.experimental.Delegate;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class OverflowPoolDataSourceHikari
    extends OverflowPoolDataSource<SimplePoolDataSourceHikari>
    implements SimplePoolDataSource, PoolDataSourcePropertiesSettersHikari, PoolDataSourcePropertiesGettersHikari {

    /*
     * Constructors
     */
    
    public OverflowPoolDataSourceHikari() {
        super(SimplePoolDataSourceHikari::new);
    }

    protected void updatePool(@NonNull final SimplePoolDataSourceHikari poolDataSource,
                              @NonNull final SimplePoolDataSourceHikari poolDataSourceOverflow) {
        final int maximumPoolSizeOverflow = poolDataSource.getMaximumPoolSize() - poolDataSource.getMinimumIdle();
        
        // is there an overflow?
        if (maximumPoolSizeOverflow > 0) {
            final HikariConfig configOverflow = new HikariConfig();
            
            poolDataSource.copyStateTo(configOverflow);
            configOverflow.copyStateTo(poolDataSourceOverflow);

            // see https://github.com/brettwooldridge/HikariCP?tab=readme-ov-file#youre-probably-doing-it-wrong

            // settings to let the pool data source fail fast so it can use the overflow
            poolDataSource.setMaximumPoolSize(poolDataSource.getMaximumPoolSize() - maximumPoolSizeOverflow);
            poolDataSource.setConnectionTimeout(250); // minimum value: time out on getConnection() quickly 

            // settings to keep the overflow pool data source as empty as possible
            poolDataSourceOverflow.setMaximumPoolSize(maximumPoolSizeOverflow);
            poolDataSourceOverflow.setMinimumIdle(0);
            poolDataSourceOverflow.setIdleTimeout(10000); // minimum
            poolDataSourceOverflow.setMaxLifetime(30000); // minimum
            if (poolDataSource.getPoolName() != null && poolDataSource.getPoolName().length() > 0) {
                poolDataSourceOverflow.setPoolName(poolDataSource.getPoolName() + "-overflow");
            }
        }        
    }
    
    protected interface ToOverrideHikari extends ToOverride {
        // setUsername(java.lang.String) in com.paulissoft.pato.jdbc.OverflowPoolDataSourceHikari
        // cannot implement setUsername(java.lang.String) in com.zaxxer.hikari.HikariConfigMXBean:
        // overridden method does not throw java.sql.SQLException
        public void setUsername(String password) throws SQLException;

        // setPassword(java.lang.String) in com.paulissoft.pato.jdbc.OverflowPoolDataSourceHikari
        // cannot implement setPassword(java.lang.String) in com.zaxxer.hikari.HikariConfigMXBean:
        // overridden method does not throw java.sql.SQLException
        public void setPassword(String password) throws SQLException;
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
    protected SimplePoolDataSourceHikari getPoolDataSource() {
        return super.getPoolDataSource();
    }

    public void setUsername(String username) {
        try {
            getPoolDataSource().setUsername(username);
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    public void setPassword(String password) {
        try {
            getPoolDataSource().setPassword(password);        
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    @Override
    protected void tearDown() {
        if (getState() == State.CLOSED) { // already closed
            return;
        }
        
        // must get this info before it is actually closed since then getPoolDataSource() will return a error
        final SimplePoolDataSourceHikari poolDataSource = getPoolDataSource(); 
        
        // we are in a synchronized context
        super.tearDown();
        if (getState() == State.CLOSED) {
            poolDataSource.close();
        }
    }
}
