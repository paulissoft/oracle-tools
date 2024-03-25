package com.paulissoft.pato.jdbc;

import jakarta.annotation.PostConstruct;
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

    private static final String POOL_NAME_PREFIX = "OraclePool";

    @Delegate(types=PoolDataSourcePropertiesOracle.class, excludes=ToOverride.class) // do not delegate setPassword()
    private PoolDataSource configPoolDataSource = null;

    @Delegate(excludes=ToOverride.class)
    private PoolDataSource commonPoolDataSource = null;

    public CombiPoolDataSourceOracle() {
        this(new PoolDataSourceImpl());
    }

    private CombiPoolDataSourceOracle(@NonNull final PoolDataSource configPoolDataSource) {
        super(configPoolDataSource, null);
    }
    
    private CombiPoolDataSourceOracle(@NonNull final PoolDataSource configPoolDataSource, final CombiPoolDataSourceOracle combiCommonPoolDataSource) {
        super(configPoolDataSource, combiCommonPoolDataSource);
    }
        
    public String getUsername() {
        return getUser();
    }

    public void setUsername(String username) throws SQLException {
        setUser(username);        
    }

    @Override
    public void setPassword(String password) throws SQLException {
        super.setPassword(password);
        getConfigPoolDataSource().setPassword(password);
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
    @Override
    protected PoolDataSource getConfigPoolDataSource() {
        return super.getConfigPoolDataSource();
    }

    @PostConstruct
    @Override
    public void init() {
        super.init();
        configPoolDataSource = getConfigPoolDataSource();
        commonPoolDataSource = getCommonPoolDataSource();
    }

    protected Connection getConnection1(@NonNull final String usernameSession1,
                                        @NonNull final String passwordSession1) throws SQLException {
        log.debug("getConnection1(usernameSession1={})", usernameSession1);

        return commonPoolDataSource.getConnection(usernameSession1, passwordSession1);
    }
    
    public Connection getConnection() throws SQLException {
        // we do use single-session proxy model so no need to invoke getConnection2()
        return getConnection1(getUsernameSession1(), getPasswordSession1());
    }

    public Connection getConnection(String username, String password) throws SQLException {
        return getCommonPoolDataSource().getConnection(username, password);
    }

    protected void updatePool(@NonNull final PoolDataSource configPoolDataSource,
                              @NonNull final PoolDataSource commonPoolDataSource,
                              final boolean initializing) {
        try {
            log.debug(">updatePool()");
            
            log.debug("pool name: {}; pool sizes before: initial/minimum/maximum: {}/{}/{}",
                      commonPoolDataSource.getConnectionPoolName(),
                      commonPoolDataSource.getInitialPoolSize(),
                      commonPoolDataSource.getMinPoolSize(),
                      commonPoolDataSource.getMaxPoolSize());

            // set pool name
            if (initializing && configPoolDataSource == commonPoolDataSource) {
                commonPoolDataSource.setConnectionPoolName(POOL_NAME_PREFIX);
            }

            final String suffix = "-" + getUsernameSession2();

            if (initializing) {
                commonPoolDataSource.setConnectionPoolName(commonPoolDataSource.getConnectionPoolName() + suffix);
            } else {
                commonPoolDataSource.setConnectionPoolName(commonPoolDataSource.getConnectionPoolName().replace(suffix, ""));
            }

            // when configPoolDataSource equals commonPoolDataSource there is no need to adjust pool sizes
            if (configPoolDataSource == commonPoolDataSource) {
                return;
            }
        
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
            log.debug("pool name: {}; pool sizes after: initial/minimum/maximum: {}/{}/{}",
                      commonPoolDataSource.getConnectionPoolName(),
                      commonPoolDataSource.getInitialPoolSize(),
                      commonPoolDataSource.getMinPoolSize(),
                      commonPoolDataSource.getMaxPoolSize());

            log.debug("<updatePool()");
        }
    }

    public void close() {
    }
}