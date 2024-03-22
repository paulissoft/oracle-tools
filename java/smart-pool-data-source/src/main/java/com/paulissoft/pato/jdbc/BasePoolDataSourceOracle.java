package com.paulissoft.pato.jdbc;

import java.sql.SQLException;
import javax.sql.DataSource;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceImpl;
import lombok.extern.slf4j.Slf4j;
import lombok.Getter;
import lombok.NonNull;


@Slf4j
public abstract class BasePoolDataSourceOracle extends PoolDataSourceImpl implements BasePoolDataSource<PoolDataSource> {

    @Getter
    private final String usernameSession1;

    private final String passwordSession1;

    @Getter
    private final String usernameSession2;

    public BasePoolDataSourceOracle(@NonNull String url,
                                    @NonNull String username,
                                    @NonNull String password,
                                    String connectionPoolName,
                                    int initialPoolSize,
                                    int minPoolSize,
                                    int maxPoolSize,
                                    @NonNull String connectionFactoryClassName,
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
        try {
            setURL(url);
            setUser(username);
            setPassword(password);
            setConnectionPoolName(connectionPoolName);
            setInitialPoolSize(initialPoolSize);
            setMinPoolSize(minPoolSize);
            setMaxPoolSize(maxPoolSize);
            setConnectionFactoryClassName(connectionFactoryClassName);
            setValidateConnectionOnBorrow(validateConnectionOnBorrow);
            setAbandonedConnectionTimeout(abandonedConnectionTimeout);
            setTimeToLiveConnectionTimeout(timeToLiveConnectionTimeout);
            setInactiveConnectionTimeout(inactiveConnectionTimeout);
            setTimeoutCheckInterval(timeoutCheckInterval);
            setMaxStatements(maxStatements);
            setConnectionWaitTimeout(connectionWaitTimeout);
            setMaxConnectionReuseTime(maxConnectionReuseTime);
            setSecondsToTrustIdleConnection(secondsToTrustIdleConnection);
            setConnectionValidationTimeout(connectionValidationTimeout);

            final PoolDataSourceConfiguration poolDataSourceConfiguration = getPoolDataSourceConfiguration(true);
        
            usernameSession2 = poolDataSourceConfiguration.getSchema();
            // there may be no proxy session at all
            usernameSession1 = poolDataSourceConfiguration.getProxyUsername() != null ? poolDataSourceConfiguration.getProxyUsername() : usernameSession2;
            passwordSession1 = password;
        } catch (SQLException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    public PoolDataSourceConfiguration getPoolDataSourceConfiguration(final boolean excludeNonIdConfiguration) {
        return PoolDataSourceConfigurationOracle
            .builder()
            .driverClassName(null)
            .url(getURL())
            .username(getUsername())
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

    /* to be implemented from the interface */
    
    public final boolean isSingleSessionProxyModel(){
        return true;
    }

    public final boolean isFixedUsernamePassword() {
        return false;
    }

    public String getUsername() {
        return super.getUser();
    }

    public void setUsername(String username) {
        try {
            super.setUser(username);
        } catch (SQLException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    public void setPassword(String password) {
        try {
            super.setPassword(password);
        } catch (SQLException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }
}
