package com.paulissoft.pato.jdbc;

//import jakarta.annotation.PostConstruct;
//import jakarta.annotation.PreDestroy;
import java.sql.Connection;
import java.sql.SQLException;
import lombok.NonNull;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceImpl;


@Slf4j
public class CombiPoolDataSourceOracle extends CombiPoolDataSource<PoolDataSource> implements PoolDataSource, PoolDataSourcePropertiesOracle {

    private CombiPoolDataSourceOracle() {
        this(new PoolDataSourceImpl());
    }

    private CombiPoolDataSourceOracle(@NonNull final PoolDataSource poolDataSourceConfig) {
        super(poolDataSourceConfig, null);
    }
    
    private CombiPoolDataSourceOracle(@NonNull final PoolDataSource poolDataSourceConfig, final CombiPoolDataSourceOracle poolDataSourceExec) {
        super(poolDataSourceConfig, poolDataSourceExec);
    }

    public static CombiPoolDataSourceOracle build(@NonNull final PoolDataSource poolDataSourceConfig) {
        return new CombiPoolDataSourceOracle(poolDataSourceConfig);
    }
    
    public static CombiPoolDataSourceOracle build(@NonNull final PoolDataSource poolDataSourceConfig, final CombiPoolDataSourceOracle poolDataSourceExec) {
        return new CombiPoolDataSourceOracle(poolDataSourceConfig, poolDataSourceExec);
    }

    protected boolean isSingleSessionProxyModel() {
        return true;
    }

    protected boolean isFixedUsernamePassword() {
        return false;
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

    // only setters and getters
    @Delegate(types=PoolDataSourcePropertiesOracle.class)
    @Override
    protected PoolDataSource getPoolDataSourceConfig() {
        return super.getPoolDataSourceConfig();
    }

    // the rest
    @Delegate(excludes=ToOverride.class)
    @Override
    protected PoolDataSource getPoolDataSourceExec() {        
        return super.getPoolDataSourceExec();
    }

    public Connection getConnection() throws SQLException {
        return null;
    }

    public Connection getConnection(String username, String password) throws SQLException {
        return null;
    }
    
    protected void updatePool() {
    }

    public void close() {
    }
}
