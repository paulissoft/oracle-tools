package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLTransientConnectionException;
import lombok.NonNull;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class OverflowPoolDataSourceHikari
    extends OverflowPoolDataSource<SimplePoolDataSourceHikari>
    implements SimplePoolDataSource, PoolDataSourcePropertiesSettersHikari, PoolDataSourcePropertiesGettersHikari {

    static final long MIN_CONNECTION_TIMEOUT = 250; // milliseconds for one pool, so twice this number for two

    static final String REX_CONNECTION_TIMEOUT = "^\\S+ - Connection is not available, request timed out after \\d+ms.$";
    

    /*
     * Constructors
     */
    
    public OverflowPoolDataSourceHikari() {
        super(SimplePoolDataSourceHikari::new);
    }

    protected long getMinConnectionTimeout() {
        return MIN_CONNECTION_TIMEOUT;
    }

    protected void updatePool(@NonNull final PoolDataSourceConfiguration pdsConfig,
                              @NonNull final SimplePoolDataSourceHikari poolDataSource,
                              final SimplePoolDataSourceHikari poolDataSourceOverflow) {        
        super.updatePool(pdsConfig, poolDataSource, poolDataSourceOverflow);
        // is there an overflow?
        if (poolDataSourceOverflow != null) {
            // see https://github.com/brettwooldridge/HikariCP?tab=readme-ov-file#youre-probably-doing-it-wrong
            poolDataSourceOverflow.setIdleTimeout(10000); // minimum
            poolDataSourceOverflow.setMaxLifetime(30000); // minimum
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
    protected SimplePoolDataSourceHikari getPoolDataSource() {
        return super.getPoolDataSource();
    }

    protected Connection getConnection(final boolean useOverflow) throws SQLException {
        log.trace(">getConnection({})", useOverflow);

        final SimplePoolDataSourceHikari pds = useOverflow ? getPoolDataSourceOverflow() : getPoolDataSource();

        try {
            return pds.getConnection();
        } catch (SQLTransientConnectionException stce) {
            if (!useOverflow && hasOverflow() && stce.getMessage().matches(REX_CONNECTION_TIMEOUT)) {
                return getConnection(!useOverflow);
            } else {
                throw stce;
            }
        } catch (Exception ex) {
            throw ex;
        } finally {
            log.trace("<getConnection({})", useOverflow);
        }
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
