package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import lombok.extern.slf4j.Slf4j;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NonNull;


@Slf4j
public abstract class BasePoolDataSourceHikari extends HikariDataSource implements BasePoolDataSource<HikariDataSource> {

    @Getter
    private String usernameSession1;

    @Getter(AccessLevel.PROTECTED)
    private String passwordSession1;

    @Getter
    private String usernameSession2;

    public BasePoolDataSourceHikari() {
    }

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
    }

    public final boolean isSingleSessionProxyModel(){
        return false;
    }

    public final boolean isFixedUsernamePassword() {
        return true; // DataSource.getConnection(username, password) is deprecated and issues a run-time error
    }

    @Override
    public void setUsername(String username) {
        super.setUsername(username);
        
        final PoolDataSourceConfiguration poolDataSourceConfiguration =
            new PoolDataSourceConfiguration("", "", username, "");
        
        usernameSession2 = poolDataSourceConfiguration.getSchema();
        // there may be no proxy session at all
        usernameSession1 = poolDataSourceConfiguration.getProxyUsername() != null ? poolDataSourceConfiguration.getProxyUsername() : usernameSession2;
    }

    @Override
    public void setPassword(String password) {
        super.setPassword(password);

        passwordSession1 = password;
    }
}
