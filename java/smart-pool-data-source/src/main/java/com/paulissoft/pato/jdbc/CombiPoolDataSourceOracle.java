package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.SQLException;
import lombok.NonNull;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class CombiPoolDataSourceOracle
    extends CombiPoolDataSource<SimplePoolDataSourceOracle, PoolDataSourceConfigurationOracle>
    implements SimplePoolDataSource, PoolDataSourcePropertiesSettersOracle, PoolDataSourcePropertiesGettersOracle {

    static final String POOL_NAME_PREFIX = "OraclePool";

    /*
     * Constructors
     */

    public CombiPoolDataSourceOracle() {
        super(new SimplePoolDataSourceOracle(), new PoolDataSourceConfigurationOracle());
    }
    
    public CombiPoolDataSourceOracle(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle) {
        super(SimplePoolDataSourceOracle::new, poolDataSourceConfigurationOracle);
    }

    public CombiPoolDataSourceOracle(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle,
                                     @NonNull final CombiPoolDataSourceOracle activeParent) {
        super(poolDataSourceConfigurationOracle, activeParent);
    }
    
    public CombiPoolDataSourceOracle(@NonNull final CombiPoolDataSourceOracle activeParent) {
        this(new PoolDataSourceConfigurationOracle(), activeParent);
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
    }

    // setXXX methods only (getPoolDataSourceSetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesSettersOracle.class, excludes=ToOverride.class) // do not delegate setPassword()
    private PoolDataSourcePropertiesSettersOracle getPoolDataSourceSetter() {
        switch (getState()) {
        case INITIALIZING:
            return getPoolDataSourceConfiguration();
        case CLOSED:
            throw new IllegalStateException("You can not use the pool once it is closed().");
        default:
            throw new IllegalStateException("The configuration of the pool is sealed once started.");
        }
    }

    // getXXX methods only (getPoolDataSourceGetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesGettersOracle.class, excludes=ToOverride.class)
    private PoolDataSourcePropertiesGettersOracle getPoolDataSourceGetter() {
        switch (getState()) {
        case CLOSED:
            throw new IllegalStateException("You can not use the pool once it is closed().");
        case INITIALIZING:
            return getPoolDataSourceConfiguration();
        default:
            return getPoolDataSource(); // as soon as the initializing phase is over, the actual pool data source should be used
        }
    }
    
    // no getXXX() nor setXXX(), just the rest (getPoolDataSource() may return different values depending on state hence use a function)
    @Delegate(excludes={ PoolDataSourcePropertiesSettersOracle.class, PoolDataSourcePropertiesGettersOracle.class, ToOverride.class })
    @Override
    protected SimplePoolDataSourceOracle getPoolDataSource() {
        return super.getPoolDataSource();
    }

    /*
     * Connection
     */

    protected Connection getConnection1(@NonNull final SimplePoolDataSourceOracle poolDataSource,
                                        @NonNull final String usernameSession1,
                                        @NonNull final String passwordSession1) throws SQLException {
        log.debug("getConnection1(id={}, usernameSession1={})", getId(), usernameSession1);

        return poolDataSource.getConnection(usernameSession1, passwordSession1);
    }

    @Override
    protected Connection getConnection(@NonNull final SimplePoolDataSourceOracle poolDataSource,
                                       @NonNull final String usernameSession1,
                                       @NonNull final String passwordSession1,
                                       @NonNull final String usernameSession2) throws SQLException {
        log.debug("getConnection(id={}, usernameSession1={}, usernameSession2={})", getId(), usernameSession1, usernameSession2);

        // we do use single-session proxy model so no need to invoke getConnection2()
        return getConnection1(poolDataSource, usernameSession1, passwordSession1);
    }

    @Override
    protected void updatePoolName(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfiguration,
                                  @NonNull final SimplePoolDataSourceOracle poolDataSource,
                                  final boolean initializing,
                                  final boolean isParentPoolDataSource) {
        try {
            log.debug(">updatePoolName(id={}, isParentPoolDataSource={})", getId(), isParentPoolDataSource);
            
            log.debug("config pool data source; address: {}; name: {}",
                      poolDataSourceConfiguration,
                      poolDataSourceConfiguration.getConnectionPoolName());

            log.debug("common pool data source; address: {}; name: {}",
                      poolDataSource,
                      poolDataSource.getConnectionPoolName());

            // set pool name
            if (initializing && isParentPoolDataSource) {
                poolDataSource.setConnectionPoolName(POOL_NAME_PREFIX);
            }

            final String suffix = "-" + getPoolDataSourceConfiguration().getSchema();

            if (initializing) {
                poolDataSource.setConnectionPoolName(poolDataSource.getConnectionPoolName() + suffix);
            } else {
                poolDataSource.setConnectionPoolName(poolDataSource.getConnectionPoolName().replace(suffix, ""));
            }
            // keep poolDataSourceConfiguration in sync
            poolDataSourceConfiguration.setConnectionPoolName(poolDataSource.getConnectionPoolName());
        } catch (SQLException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        } finally {
            log.debug("config pool data source; address: {}; name: {}",
                      poolDataSourceConfiguration,
                      poolDataSourceConfiguration.getConnectionPoolName());

            log.debug("common pool data source; address: {}; name: {}",
                      poolDataSource,
                      poolDataSource.getConnectionPoolName());

            log.debug("<updatePoolName(id={})", getId());
        }
    }

    @Override
    protected void updatePoolSizes(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfiguration,
                                   @NonNull final SimplePoolDataSourceOracle poolDataSource,
                                   final boolean initializing) {
        try {
            log.debug(">updatePoolSizes(id={})", getId());
            
            log.debug("config pool data source; address: {}; name: {}; pool sizes before: initial/minimum/maximum: {}/{}/{}",
                      poolDataSourceConfiguration,
                      poolDataSourceConfiguration.getConnectionPoolName(),
                      poolDataSourceConfiguration.getInitialPoolSize(),
                      poolDataSourceConfiguration.getMinPoolSize(),
                      poolDataSourceConfiguration.getMaxPoolSize());

            log.debug("common pool data source; address: {}; name: {}; pool sizes before: initial/minimum/maximum: {}/{}/{}",
                      poolDataSource,
                      poolDataSource.getConnectionPoolName(),
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
            log.debug("config pool data source; address: {}; name: {}; pool sizes after: initial/minimum/maximum: {}/{}/{}",
                      poolDataSourceConfiguration,
                      poolDataSourceConfiguration.getConnectionPoolName(),
                      poolDataSourceConfiguration.getInitialPoolSize(),
                      poolDataSourceConfiguration.getMinPoolSize(),
                      poolDataSourceConfiguration.getMaxPoolSize());

            log.debug("common pool data source; address: {}; name: {}; pool sizes after: initial/minimum/maximum: {}/{}/{}",
                      poolDataSource,
                      poolDataSource.getConnectionPoolName(),
                      poolDataSource.getInitialPoolSize(),
                      poolDataSource.getMinPoolSize(),
                      poolDataSource.getMaxPoolSize());

            log.debug("<updatePoolSizes(id={})", getId());
        }
    }
}
