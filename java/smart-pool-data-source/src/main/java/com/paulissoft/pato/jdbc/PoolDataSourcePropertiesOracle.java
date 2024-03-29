package com.paulissoft.pato.jdbc;

import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceImpl;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class PoolDataSourcePropertiesOracle extends PoolDataSourceProperties<PoolDataSource> {

    public PoolDataSourcePropertiesOracle(String url,
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
        super(PoolDataSourcePropertiesOracle.build(url,
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
        System.out.println("Killroy was here");
    }

    private PoolDataSourcePropertiesOracle(final BuildResult buildResult) {
        super(buildResult);
    }

    protected static BuildResult build(String url,
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

        return new BuildResult(poolDataSource, username, password);
    }
}
