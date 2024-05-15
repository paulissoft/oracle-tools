package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import lombok.NonNull;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class CombiPoolDataSourceOracle
    extends CombiPoolDataSource<SimplePoolDataSourceOracle, PoolDataSourceConfigurationOracle>
    implements SimplePoolDataSource, PoolDataSourcePropertiesSettersOracle, PoolDataSourcePropertiesGettersOracle {

    /*
     * Constructors
     */

    public CombiPoolDataSourceOracle() {
        super(new SimplePoolDataSourceOracle(), new PoolDataSourceConfigurationOracle());
        log.debug("constructor 1: everything null, INITIALIZING");
    }
    
    public CombiPoolDataSourceOracle(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle) {
        super(SimplePoolDataSourceOracle::new, poolDataSourceConfigurationOracle);
        log.debug("constructor 2: poolDataSourceConfigurationOracle != null (fixed), OPEN");
    }

    public CombiPoolDataSourceOracle(@NonNull final CombiPoolDataSourceOracle activeParent) {
        this(new PoolDataSourceConfigurationOracle(), activeParent);
        log.debug("constructor 3: activeParent != null, INITIALIZING");
    }

    public CombiPoolDataSourceOracle(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle,
                                     @NonNull final CombiPoolDataSourceOracle activeParent) {
        super(poolDataSourceConfigurationOracle, activeParent);
        log.debug("constructor 4: poolDataSourceConfigurationOracle != null (fixed), activeParent != null, INITIALIZING");
    }
    
    public CombiPoolDataSourceOracle(@NonNull final CombiPoolDataSourceOracle activeParent,
                                     String url,
                                     String username,
                                     String password,
                                     String type)
    {
        this(PoolDataSourceConfigurationOracle.build(url,
                                                     username,
                                                     password,
                                                     type != null ? type : CombiPoolDataSourceOracle.class.getName()),
             activeParent);
        log.debug("constructor 5: connection properties != null (fixed), activeParent != null, INITIALIZING");
    }

    public CombiPoolDataSourceOracle(String url,
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
                                     int connectionWaitTimeout,
                                     long maxConnectionReuseTime,
                                     int secondsToTrustIdleConnection,
                                     int connectionValidationTimeout)
    {
        this(PoolDataSourceConfigurationOracle.build(url,
                                                     username,
                                                     password,
                                                     // cannot reference this before supertype constructor has been called,
                                                     // hence can not use this in constructor above
                                                     type != null ? type : CombiPoolDataSourceOracle.class.getName(),
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
                                                     connectionWaitTimeout,
                                                     maxConnectionReuseTime,
                                                     secondsToTrustIdleConnection,
                                                     connectionValidationTimeout));
        log.debug("constructor 6: properties != null (fixed), activeParent != null, OPEN");
    }

    // setXXX methods only (getPoolDataSourceSetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesSettersOracle.class, excludes=ToOverride.class) // do not delegate setPassword()
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
    @Delegate(types=PoolDataSourcePropertiesGettersOracle.class, excludes=ToOverride.class)
    private PoolDataSourcePropertiesGettersOracle getPoolDataSourceGetter() {
        try {
            switch (getState()) {
            case CLOSED:
                throw new IllegalStateException("You can not use the pool once it is closed.");
            case INITIALIZING:
                return getPoolDataSourceConfiguration();
            default:
                return getPoolDataSource(); // as soon as the initializing phase is over, the actual pool data source should be used
            }
        } catch (IllegalStateException ex) {
            log.error("Exception in getPoolDataSourceGetter(): {}", ex);
            throw ex;
        }
    }
    
    // no getXXX() nor setXXX(), just the rest (getPoolDataSource() may return different values depending on state hence use a function)
    @Delegate(excludes={ PoolDataSourcePropertiesSettersOracle.class, PoolDataSourcePropertiesGettersOracle.class, ToOverride.class })
    @Override
    protected SimplePoolDataSourceOracle getPoolDataSource() {
        return super.getPoolDataSource();
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

    /*
     * Connection
     */
    protected Connection getConnection(@NonNull final SimplePoolDataSourceOracle poolDataSource,
                                       @NonNull final String usernameSession1,
                                       @NonNull final String passwordSession1,
                                       @NonNull final String usernameSession2) throws SQLException {
        log.debug("getConnection(id={}, usernameSession1={}, usernameSession2={})", getId(), usernameSession1, usernameSession2);

        // we do use single-session proxy model so no need to invoke getConnection2()
        return getConnection1(poolDataSource, usernameSession1, passwordSession1);
    }

    protected Connection getConnection1(@NonNull final SimplePoolDataSourceOracle poolDataSource,
                                        @NonNull final String usernameSession1,
                                        @NonNull final String passwordSession1) throws SQLException {
        log.debug("getConnection1(id={}, usernameSession1={})", getId(), usernameSession1);

        return poolDataSource.getConnection(usernameSession1, passwordSession1);
    }

    public String getPoolNamePrefix() {
        return this.getClass().getSimpleName();
    }

    // IMPORTANT
    //
    // Since the connection pool name can notchange once the pool has started,
    // we change the description if we add/remove schemas.
    public String getPoolDescription() {
        return getPoolDescription(getPoolDataSource());
    }

    private static String getPoolDescription(@NonNull final SimplePoolDataSourceOracle poolDataSource) {
        final String poolName = poolDataSource.getConnectionPoolName();
        final String description = poolDataSource.getDescription();
        
        return (poolName  != null ? poolName : "") + (description != null ? description : "");
    }

    @Override
    protected void updatePoolDescription(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfiguration,
                                         @NonNull final SimplePoolDataSourceOracle poolDataSource,
                                         final boolean initializing,
                                         final boolean isParentPoolDataSource) {
        try {
            log.debug(">updatePoolDescription(id={}, isParentPoolDataSource={})", getId(), isParentPoolDataSource);            
            log.debug("config pool data source; name: {}; address: {}",
                      poolDataSourceConfiguration.getConnectionPoolName(),
                      poolDataSourceConfiguration);
            log.debug("common pool data source; name: {}; address: {}",
                      poolDataSource.getConnectionPoolName(),
                      poolDataSource);

            // IMPORTANT
            //
            // Since the connection pool name can notchange once the pool has started,
            // we change the description if we add/remove schemas.

            final String poolDescription = getPoolDescription(poolDataSource);
            final ArrayList<String> items = new ArrayList(Arrays.asList(poolDescription.split("-"))); // use pool description not just name
            final String schema = getPoolDataSourceConfiguration().getSchema();

            log.debug("items: {}; schema: {}", items, schema);
                        
            if (initializing) {
                if (isParentPoolDataSource) {
                    items.clear();
                    items.add(getPoolNamePrefix());
                    items.add(schema);
                } else if (!isParentPoolDataSource && !items.contains(schema)) {
                    items.add(schema);
                }
            } else if (!isParentPoolDataSource && items.contains(schema)) {
                items.remove(schema);
            }

            if (items.size() >= 2) {
                poolDataSource.setConnectionPoolName(items.get(0) + "-" + items.get(1));
                items.remove(0);
                items.remove(0);
                if (items.size() >= 1) {
                    poolDataSource.setDescription(String.join("-", items));
                } else {
                    poolDataSource.setDescription("");
                }
            }

            // keep poolDataSource.getPoolDescription() and poolDataSourceConfiguration.getConnectionPoolName() in sync
            poolDataSourceConfiguration.setConnectionPoolName(getPoolDescription(poolDataSource));
        } catch (SQLException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        } finally {
            log.debug("config pool data source; name: {}; address: {}",
                      poolDataSourceConfiguration.getConnectionPoolName(),
                      poolDataSourceConfiguration);
            log.debug("common pool data source; name: {}; address: {}",
                      poolDataSource.getConnectionPoolName(),
                      poolDataSource);
            log.debug("<updatePoolDescription(id={})", getId());
        }
    }

    @Override
    protected void updatePoolSizes(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfiguration,
                                   @NonNull final SimplePoolDataSourceOracle poolDataSource,
                                   final boolean initializing) {
        try {
            log.debug(">updatePoolSizes(id={})", getId());            
            log.debug("config pool data source; name: {}; address: {}; pool sizes before: initial/minimum/maximum: {}/{}/{}",
                      poolDataSourceConfiguration.getConnectionPoolName(),
                      poolDataSourceConfiguration,
                      poolDataSourceConfiguration.getInitialPoolSize(),
                      poolDataSourceConfiguration.getMinPoolSize(),
                      poolDataSourceConfiguration.getMaxPoolSize());
            log.debug("common pool data source; name: {}; address: {}; pool sizes before: initial/minimum/maximum: {}/{}/{}",
                      poolDataSource.getConnectionPoolName(),
                      poolDataSource,
                      poolDataSource.getInitialPoolSize(),
                      poolDataSource.getMinPoolSize(),
                      poolDataSource.getMaxPoolSize());
            
            // when poolDataSourceConfiguration equals poolDataSource there is no need to adjust pool sizes
            final int sign = initializing ? +1 : -1;

            int thisSize, pdsSize;

            pdsSize = poolDataSourceConfiguration.getInitialPoolSize();
            thisSize = Integer.max(poolDataSource.getInitialPoolSize(), 0);

            log.debug("initial pool sizes before changing it: this/pds: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {
                poolDataSource.setInitialPoolSize(pdsSize + thisSize);
            }

            pdsSize = poolDataSourceConfiguration.getMinPoolSize();
            thisSize = Integer.max(poolDataSource.getMinPoolSize(), 0);

            log.debug("minimum pool sizes before changing it: this/pds: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {                
                poolDataSource.setMinPoolSize(pdsSize + thisSize);
            }
                
            pdsSize = poolDataSourceConfiguration.getMaxPoolSize();
            thisSize = Integer.max(poolDataSource.getMaxPoolSize(), 0);

            log.debug("maximum pool sizes before changing it: this/pds: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize && pdsSize + thisSize > 0) {
                poolDataSource.setMaxPoolSize(pdsSize + thisSize);
            }
        } catch (SQLException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        } finally {
            log.debug("config pool data source; name: {}; address: {}; pool sizes after: initial/minimum/maximum: {}/{}/{}",
                      poolDataSourceConfiguration.getConnectionPoolName(),
                      poolDataSourceConfiguration,
                      poolDataSourceConfiguration.getInitialPoolSize(),
                      poolDataSourceConfiguration.getMinPoolSize(),
                      poolDataSourceConfiguration.getMaxPoolSize());
            log.debug("common pool data source; name: {}; address: {}; pool sizes after: initial/minimum/maximum: {}/{}/{}",
                      poolDataSource.getConnectionPoolName(),
                      poolDataSource,
                      poolDataSource.getInitialPoolSize(),
                      poolDataSource.getMinPoolSize(),
                      poolDataSource.getMaxPoolSize());
            log.debug("<updatePoolSizes(id={})", getId());
        }
    }
}
