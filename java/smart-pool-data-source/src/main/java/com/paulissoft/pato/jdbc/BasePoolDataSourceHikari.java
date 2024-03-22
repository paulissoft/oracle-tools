package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import javax.sql.DataSource;
import lombok.extern.slf4j.Slf4j;
import lombok.Getter;
import lombok.NonNull;


@Slf4j
public abstract class BasePoolDataSourceHikari extends HikariDataSource implements BasePoolDataSource<HikariDataSource> {

    @Getter
    private final String usernameSession1;

    private final String passwordSession1;

    @Getter
    private final String usernameSession2;

    public BasePoolDataSourceHikari(String driverClassName,
                                    @NonNull String url,
                                    @NonNull String username,
                                    @NonNull String password,
                                    String poolName,
                                    int maximumPoolSize,
                                    int minimumIdle,
                                    String dataSourceClassName,
                                    boolean autoCommit,
                                    long connectionTimeout,
                                    long idleTimeout,
                                    long maxLifetime,
                                    String connectionTestQuery,
                                    long initializationFailTimeout,
                                    boolean isolateInternalQueries,
                                    boolean allowPoolSuspension,
                                    boolean readOnly,
                                    boolean registerMbeans,
                                    long validationTimeout,
                                    long leakDetectionThreshold) {
        setDriverClassName(driverClassName);
        setJdbcUrl(url);
        setUsername(username);
        setPassword(password);
        setPoolName(poolName);
        setMaximumPoolSize(maximumPoolSize);
        setMinimumIdle(minimumIdle);
        setDataSourceClassName(dataSourceClassName);
        setAutoCommit(autoCommit);
        setConnectionTimeout(connectionTimeout);
        setIdleTimeout(idleTimeout);
        setMaxLifetime(maxLifetime);
        setConnectionTestQuery(connectionTestQuery);
        setInitializationFailTimeout(initializationFailTimeout);
        setIsolateInternalQueries(isolateInternalQueries);
        setAllowPoolSuspension(allowPoolSuspension);
        setReadOnly(readOnly);
        setRegisterMbeans(registerMbeans);
        setValidationTimeout(validationTimeout);
        setLeakDetectionThreshold(leakDetectionThreshold);

        final PoolDataSourceConfiguration poolDataSourceConfiguration = getPoolDataSourceConfiguration(true);
        
        usernameSession2 = poolDataSourceConfiguration.getSchema();
        // there may be no proxy session at all
        usernameSession1 = poolDataSourceConfiguration.getProxyUsername() != null ? poolDataSourceConfiguration.getProxyUsername() : usernameSession2;
        passwordSession1 = password;
    }

    public PoolDataSourceConfiguration getPoolDataSourceConfiguration(final boolean excludeNonIdConfiguration) {
        return PoolDataSourceConfigurationHikari
            .builder()
            .driverClassName(getDriverClassName())
            .url(getJdbcUrl())
            .username(getUsername())
            .password(excludeNonIdConfiguration ? null : getPassword())
            .type(SimplePoolDataSourceHikari.class.getName())
            .poolName(excludeNonIdConfiguration ? null : getPoolName())
            .maximumPoolSize(getMaximumPoolSize())
            .minimumIdle(getMinimumIdle())
            .autoCommit(isAutoCommit())
            .connectionTimeout(getConnectionTimeout())
            .idleTimeout(getIdleTimeout())
            .maxLifetime(getMaxLifetime())
            .connectionTestQuery(getConnectionTestQuery())
            .initializationFailTimeout(getInitializationFailTimeout())
            .isolateInternalQueries(isIsolateInternalQueries())
            .allowPoolSuspension(isAllowPoolSuspension())
            .readOnly(isReadOnly())
            .registerMbeans(isRegisterMbeans())
            .validationTimeout(getValidationTimeout())
            .leakDetectionThreshold(getLeakDetectionThreshold())
            .build();
    }

    /* to be implemented from the interface */
    
    public final boolean isSingleSessionProxyModel(){
        return false;
    }

    public final boolean isFixedUsernamePassword() {
        return true; // DataSource.getConnection(username, password) deprecated and issues a run-time error
    }
}
