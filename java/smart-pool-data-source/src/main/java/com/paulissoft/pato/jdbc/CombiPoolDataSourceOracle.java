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
    extends CombiPoolDataSource<PoolDataSource>
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

    private CombiPoolDataSourceOracle(final Object[] fields) {
        super(fields);
    }

    protected static Object[] build(String url,
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

        final PoolDataSourceImpl poolDataSource = new PoolDataSourceImpl();

        int nr = 0;
        final int maxNr = 17;
        
        do {
            try {
                /* this.driverClassName is ignored */
                switch(nr) {
                case 0: poolDataSource.setURL(url); break;
                case 1: poolDataSource.setUser(username); break;
                case 2: poolDataSource.setPassword(password); break;
                case 3: /* connection pool name is not copied here */ break;
                case 4: poolDataSource.setInitialPoolSize(initialPoolSize); break;
                case 5: poolDataSource.setMinPoolSize(minPoolSize); break;
                case 6: poolDataSource.setMaxPoolSize(maxPoolSize); break;
                case 7: poolDataSource.setConnectionFactoryClassName(connectionFactoryClassName); break;
                case 8: poolDataSource.setValidateConnectionOnBorrow(validateConnectionOnBorrow); break;
                case 9: poolDataSource.setAbandonedConnectionTimeout(abandonedConnectionTimeout); break;
                case 10: poolDataSource.setTimeToLiveConnectionTimeout(timeToLiveConnectionTimeout); break;
                case 11: poolDataSource.setInactiveConnectionTimeout(inactiveConnectionTimeout); break;
                case 12: poolDataSource.setTimeoutCheckInterval(timeoutCheckInterval); break;
                case 13: poolDataSource.setMaxStatements(maxStatements); break;
                case 14: poolDataSource.setConnectionWaitTimeout(connectionWaitTimeout); break;
                case 15: poolDataSource.setMaxConnectionReuseTime(maxConnectionReuseTime); break;
                case 16: poolDataSource.setSecondsToTrustIdleConnection(secondsToTrustIdleConnection); break;
                case 17: poolDataSource.setConnectionValidationTimeout(connectionValidationTimeout); break;
                default:
                    throw new IllegalArgumentException(String.format("Wrong value for nr (%d): must be between 0 and %d", nr, maxNr));
                }
            } catch (Exception ex) {
                log.warn("nr: {}; exception: {}", nr, SimplePoolDataSource.exceptionToString(ex));
            }
        } while (++nr <= maxNr);

        return new Object[]{ poolDataSource, password };
    }

    // setXXX methods only (determinePoolDataSourceSetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesSettersOracle.class, excludes=ToOverride.class) // do not delegate setPassword()
    private PoolDataSource getPoolDataSourceSetter() {
        return determinePoolDataSourceSetter();
    }

    // getXXX methods only (determinePoolDataSourceGetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesGettersOracle.class, excludes=ToOverride.class)
    private PoolDataSource getPoolDataSourceGetter() {
        return determinePoolDataSourceGetter();
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

    public PoolDataSourceConfiguration getPoolDataSourceConfiguration() {
        return getPoolDataSourceConfiguration(true);
    }
    
    private PoolDataSourceConfiguration getPoolDataSourceConfiguration(final boolean excludeNonIdConfiguration) {
        return PoolDataSourceConfigurationOracle
            .builder()
            .driverClassName(null)
            .url(getURL())
            .username(getUser())
            .password(excludeNonIdConfiguration ? null : getPassword())
            .type(SimplePoolDataSourceOracle.class.getName())
            .connectionPoolName(excludeNonIdConfiguration ? null : getConnectionPoolName())
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
            .connectionWaitTimeout(getConnectionWaitTimeout())
            .maxConnectionReuseTime(getMaxConnectionReuseTime())
            .secondsToTrustIdleConnection(getSecondsToTrustIdleConnection())
            .connectionValidationTimeout(getConnectionValidationTimeout())
            .build();
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

    protected void updatePool(@NonNull final PoolDataSource configPoolDataSource,
                              @NonNull final PoolDataSource commonPoolDataSource,
                              final boolean initializing,
                              final boolean isParentPoolDataSource) {
        try {
            log.debug(">updatePoolName(isParentPoolDataSource={})", isParentPoolDataSource);
            
            log.debug("config pool data source; address: {}; name: {}",
                      configPoolDataSource,
                      configPoolDataSource.getConnectionPoolName());

            log.debug("common pool data source; address: {}; name: {}",
                      commonPoolDataSource,
                      commonPoolDataSource.getConnectionPoolName());

            // set pool name
            if (initializing && isParentPoolDataSource) {
                commonPoolDataSource.setConnectionPoolName(POOL_NAME_PREFIX);
            }

            final String suffix = "-" + getUsernameSession2();

            if (initializing) {
                commonPoolDataSource.setConnectionPoolName(commonPoolDataSource.getConnectionPoolName() + suffix);
            } else {
                commonPoolDataSource.setConnectionPoolName(commonPoolDataSource.getConnectionPoolName().replace(suffix, ""));
            }
        } catch (SQLException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        } finally {
            log.debug("config pool data source; address: {}; name: {}",
                      configPoolDataSource,
                      configPoolDataSource.getConnectionPoolName());

            log.debug("common pool data source; address: {}; name: {}",
                      commonPoolDataSource,
                      commonPoolDataSource.getConnectionPoolName());

            log.debug("<updatePoolName()");
        }
    }

    protected void updatePoolSizes(@NonNull final PoolDataSource configPoolDataSource,
                                   @NonNull final PoolDataSource commonPoolDataSource,
                                   final boolean initializing) {
        try {
            log.debug(">updatePoolSizes()");
            
            log.debug("config pool data source; address: {}; name: {}; pool sizes before: initial/minimum/maximum: {}/{}/{}",
                      configPoolDataSource,
                      configPoolDataSource.getConnectionPoolName(),
                      configPoolDataSource.getInitialPoolSize(),
                      configPoolDataSource.getMinPoolSize(),
                      configPoolDataSource.getMaxPoolSize());

            log.debug("common pool data source; address: {}; name: {}; pool sizes before: initial/minimum/maximum: {}/{}/{}",
                      commonPoolDataSource,
                      commonPoolDataSource.getConnectionPoolName(),
                      commonPoolDataSource.getInitialPoolSize(),
                      commonPoolDataSource.getMinPoolSize(),
                      commonPoolDataSource.getMaxPoolSize());
            
            // when configPoolDataSource equals commonPoolDataSource there is no need to adjust pool sizes
            final int sign = initializing ? +1 : -1;

            int thisSize, pdsSize;

            pdsSize = configPoolDataSource.getInitialPoolSize();
            thisSize = Integer.max(commonPoolDataSource.getInitialPoolSize(), 0);

            log.debug("initial pool sizes before changing it: this/pds: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {
                commonPoolDataSource.setInitialPoolSize(pdsSize + thisSize);
            }

            pdsSize = configPoolDataSource.getMinPoolSize();
            thisSize = Integer.max(commonPoolDataSource.getMinPoolSize(), 0);

            log.debug("minimum pool sizes before changing it: this/pds: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {                
                commonPoolDataSource.setMinPoolSize(pdsSize + thisSize);
            }
                
            pdsSize = configPoolDataSource.getMaxPoolSize();
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
                      configPoolDataSource,
                      configPoolDataSource.getConnectionPoolName(),
                      configPoolDataSource.getInitialPoolSize(),
                      configPoolDataSource.getMinPoolSize(),
                      configPoolDataSource.getMaxPoolSize());

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
