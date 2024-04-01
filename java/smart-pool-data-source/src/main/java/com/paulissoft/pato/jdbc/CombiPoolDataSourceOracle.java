package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.SQLException;
import lombok.NonNull;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceImpl;


@Slf4j
public class CombiPoolDataSourceOracle
    extends CombiPoolDataSource<PoolDataSource, PoolDataSourceConfigurationOracle>
    implements PoolDataSource, PoolDataSourcePropertiesSettersOracle, PoolDataSourcePropertiesGettersOracle {

    private static final String POOL_NAME_PREFIX = "OraclePool";

    public CombiPoolDataSourceOracle(String url,
                                     String username,
                                     String password,
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
        this(build(url,
                   username,
                   password,
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

    public CombiPoolDataSourceOracle(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle) {
        super(PoolDataSourceImpl::new, PoolDataSourceConfigurationOracle::new, poolDataSourceConfigurationOracle);
    }

    protected static PoolDataSourceConfigurationOracle build(String url,
                                                             String username,
                                                             String password,
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
                                                             int connectionValidationTimeout) {
        return PoolDataSourceConfigurationOracle
            .builder()
            .type(CombiPoolDataSourceOracle.class.getName())
            .url(url)
            .username(username)
            .password(password)
            .connectionPoolName(connectionPoolName)
            .initialPoolSize(initialPoolSize)
            .minPoolSize(minPoolSize)
            .maxPoolSize(maxPoolSize)
            .connectionFactoryClassName(connectionFactoryClassName)
            .validateConnectionOnBorrow(validateConnectionOnBorrow)
            .abandonedConnectionTimeout(abandonedConnectionTimeout)
            .timeToLiveConnectionTimeout(timeToLiveConnectionTimeout)
            .inactiveConnectionTimeout(inactiveConnectionTimeout)
            .timeoutCheckInterval(timeoutCheckInterval)
            .maxStatements(maxStatements)
            .connectionWaitTimeout(connectionWaitTimeout)
            .maxConnectionReuseTime(maxConnectionReuseTime)
            .secondsToTrustIdleConnection(secondsToTrustIdleConnection)
            .connectionValidationTimeout(connectionValidationTimeout)
            .build();
    }

    // setXXX methods only (determinePoolDataSourceSetter() may return different values depending on state hence use a function)
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

    // getXXX methods only (determinePoolDataSourceGetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesGettersOracle.class, excludes=ToOverride.class)
    private PoolDataSourcePropertiesGettersOracle getPoolDataSourceGetter() {
        switch (getState()) {
        case CLOSED:
            throw new IllegalStateException("You can not use the pool once it is closed().");
        default:
            return getPoolDataSourceConfiguration();
        }
    }
    
    // no getXXX() nor setXXX(), just the rest (determineCommonPoolDataSource() may return different values depending on state hence use a function)
    @Delegate(excludes={ PoolDataSourcePropertiesSettersOracle.class, PoolDataSourcePropertiesGettersOracle.class, ToOverride.class })
    private PoolDataSource getCommonPoolDataSource() {
        return determineCommonPoolDataSource();
    }

    public String getUrl() {
        return getURL();
    }
  
    public void setUrl(String jdbcUrl) throws SQLException {
        setURL(jdbcUrl);
    }
  
    public String getUsername() {
        return getUser();
    }

    public void setUsername(String username) throws SQLException {
        setUser(username);        
    }

    protected Connection getConnection1(@NonNull final PoolDataSource commonPoolDataSource,
                                        @NonNull final String usernameSession1,
                                        @NonNull final String passwordSession1) throws SQLException {
        log.debug("getConnection1(usernameSession1={})", usernameSession1);

        return commonPoolDataSource.getConnection(usernameSession1, passwordSession1);
    }
    
    protected Connection getConnection(@NonNull final PoolDataSource commonPoolDataSource,
                                       @NonNull final String usernameSession1,
                                       @NonNull final String passwordSession1,
                                       @NonNull final String usernameSession2) throws SQLException {
        // we do use single-session proxy model so no need to invoke getConnection2()
        return getConnection1(commonPoolDataSource, usernameSession1, passwordSession1);
    }

    protected void updatePool(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfiguration,
                              @NonNull final PoolDataSource commonPoolDataSource,
                              final boolean initializing,
                              final boolean isParentPoolDataSource) {
        try {
            log.debug(">updatePoolName(isParentPoolDataSource={})", isParentPoolDataSource);
            
            log.debug("config pool data source; address: {}; name: {}",
                      poolDataSourceConfiguration,
                      poolDataSourceConfiguration.getConnectionPoolName());

            log.debug("common pool data source; address: {}; name: {}",
                      commonPoolDataSource,
                      commonPoolDataSource.getConnectionPoolName());

            // set pool name
            if (initializing && isParentPoolDataSource) {
                commonPoolDataSource.setConnectionPoolName(POOL_NAME_PREFIX);
            }

            final String suffix = "-" + getPoolDataSourceConfiguration().getSchema();

            if (initializing) {
                commonPoolDataSource.setConnectionPoolName(commonPoolDataSource.getConnectionPoolName() + suffix);
            } else {
                commonPoolDataSource.setConnectionPoolName(commonPoolDataSource.getConnectionPoolName().replace(suffix, ""));
            }
        } catch (SQLException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        } finally {
            log.debug("config pool data source; address: {}; name: {}",
                      poolDataSourceConfiguration,
                      poolDataSourceConfiguration.getConnectionPoolName());

            log.debug("common pool data source; address: {}; name: {}",
                      commonPoolDataSource,
                      commonPoolDataSource.getConnectionPoolName());

            log.debug("<updatePoolName()");
        }
    }

    protected void updatePoolSizes(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfiguration,
                                   @NonNull final PoolDataSource commonPoolDataSource,
                                   final boolean initializing) {
        try {
            log.debug(">updatePoolSizes()");
            
            log.debug("config pool data source; address: {}; name: {}; pool sizes before: initial/minimum/maximum: {}/{}/{}",
                      poolDataSourceConfiguration,
                      poolDataSourceConfiguration.getConnectionPoolName(),
                      poolDataSourceConfiguration.getInitialPoolSize(),
                      poolDataSourceConfiguration.getMinPoolSize(),
                      poolDataSourceConfiguration.getMaxPoolSize());

            log.debug("common pool data source; address: {}; name: {}; pool sizes before: initial/minimum/maximum: {}/{}/{}",
                      commonPoolDataSource,
                      commonPoolDataSource.getConnectionPoolName(),
                      commonPoolDataSource.getInitialPoolSize(),
                      commonPoolDataSource.getMinPoolSize(),
                      commonPoolDataSource.getMaxPoolSize());
            
            // when poolDataSourceConfiguration equals commonPoolDataSource there is no need to adjust pool sizes
            final int sign = initializing ? +1 : -1;

            int thisSize, pdsSize;

            pdsSize = poolDataSourceConfiguration.getInitialPoolSize();
            thisSize = Integer.max(commonPoolDataSource.getInitialPoolSize(), 0);

            log.debug("initial pool sizes before changing it: this/pds: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {
                commonPoolDataSource.setInitialPoolSize(pdsSize + thisSize);
            }

            pdsSize = poolDataSourceConfiguration.getMinPoolSize();
            thisSize = Integer.max(commonPoolDataSource.getMinPoolSize(), 0);

            log.debug("minimum pool sizes before changing it: this/pds: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {                
                commonPoolDataSource.setMinPoolSize(pdsSize + thisSize);
            }
                
            pdsSize = poolDataSourceConfiguration.getMaxPoolSize();
            thisSize = Integer.max(commonPoolDataSource.getMaxPoolSize(), 0);

            log.debug("maximum pool sizes before changing it: this/pds: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {
                commonPoolDataSource.setMaxPoolSize(pdsSize + thisSize);
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
                      commonPoolDataSource,
                      commonPoolDataSource.getConnectionPoolName(),
                      commonPoolDataSource.getInitialPoolSize(),
                      commonPoolDataSource.getMinPoolSize(),
                      commonPoolDataSource.getMaxPoolSize());

            log.debug("<updatePool()");
        }
    }
}
