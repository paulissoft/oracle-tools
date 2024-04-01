package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariConfigMXBean;
import java.sql.Connection;
import java.sql.SQLException;
import lombok.NonNull;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class CombiPoolDataSourceHikari
    extends CombiPoolDataSource<HikariDataSource, PoolDataSourceConfigurationHikari>
    implements HikariConfigMXBean, PoolDataSourcePropertiesSettersHikari, PoolDataSourcePropertiesGettersHikari {

    private static final String POOL_NAME_PREFIX = "HikariPool";

    public CombiPoolDataSourceHikari(String driverClassName,
                                     String url,
                                     String username,
                                     String password,
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
        this(build(driverClassName,
                   url,
                   username,
                   password,
                   poolName,
                   maximumPoolSize,
                   minimumIdle,
                   dataSourceClassName,
                   autoCommit,
                   connectionTimeout,
                   idleTimeout,
                   maxLifetime,
                   connectionTestQuery,
                   initializationFailTimeout,
                   isolateInternalQueries,
                   allowPoolSuspension,
                   readOnly,
                   registerMbeans,    
                   validationTimeout,
                   leakDetectionThreshold));
    }

    public CombiPoolDataSourceHikari(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari) {
        super(poolDataSourceConfigurationHikari);
    }

    protected static PoolDataSourceConfigurationHikari build(String driverClassName,
                                                             String url,
                                                             String username,
                                                             String password,
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
        return PoolDataSourceConfigurationHikari
            .builder()
            .type(CombiPoolDataSourceHikari.class.getName())
            .driverClassName(driverClassName)
            .url(url)
            .username(username)
            .password(password)
            .poolName(poolName)
            .maximumPoolSize(maximumPoolSize)
            .minimumIdle(minimumIdle)
            .autoCommit(autoCommit)
            .connectionTimeout(connectionTimeout)
            .idleTimeout(idleTimeout)
            .maxLifetime(maxLifetime)
            .connectionTestQuery(connectionTestQuery)
            .initializationFailTimeout(initializationFailTimeout)
            .isolateInternalQueries(isolateInternalQueries)
            .allowPoolSuspension(allowPoolSuspension)
            .readOnly(readOnly)
            .registerMbeans(registerMbeans)
            .validationTimeout(validationTimeout)
            .leakDetectionThreshold(leakDetectionThreshold)
            .build();
    }
    
    // setXXX methods only (determinePoolDataSourceSetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesSettersHikari.class, excludes=ToOverride.class) // do not delegate setPassword()
    private PoolDataSourcePropertiesSettersHikari getPoolDataSourceSetter() {
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
    @Delegate(types=PoolDataSourcePropertiesGettersHikari.class, excludes=ToOverride.class)
    private PoolDataSourcePropertiesGettersHikari getPoolDataSourceGetter() {
        switch (getState()) {
        case CLOSED:
            throw new IllegalStateException("You can not use the pool once it is closed().");
        default:
            return getPoolDataSourceConfiguration();
        }
    }

    // no getXXX() nor setXXX(), just the rest (determineCommonPoolDataSource() may return different values depending on state hence use a function)
    @Delegate(excludes={ PoolDataSourcePropertiesSettersHikari.class, PoolDataSourcePropertiesGettersHikari.class, ToOverride.class })
    private HikariDataSource getCommonPoolDataSource() {
        return determineCommonPoolDataSource();
    }

    protected boolean isSingleSessionProxyModel() {
        return PoolDataSourceConfigurationHikari.SINGLE_SESSION_PROXY_MODEL;
    }

    protected boolean isFixedUsernamePassword() {
        return PoolDataSourceConfigurationHikari.FIXED_USERNAME_PASSWORD;
    }

    public String getUrl() {
        return getJdbcUrl();
    }
  
    public void setUrl(String jdbcUrl) {
        setJdbcUrl(jdbcUrl);
    }
    
    @Override
    public void setUsername(String username) {
        try {
            getPoolDataSourceSetter().setUsername(username);
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    @Override
    protected void tearDown() {
        // must get this info before it is actually closed since then getCommonPoolDataSource() will return a error
        final HikariDataSource commonPoolDataSource = getCommonPoolDataSource(); 
        
        // we are in a synchronized context
        super.tearDown();
        if (getState() == State.CLOSED) {
            commonPoolDataSource.close();
        }
    }

    protected Connection getConnection1(@NonNull final HikariDataSource commonPoolDataSource,
                                        @NonNull final String usernameSession1,
                                        @NonNull final String passwordSession1) throws SQLException {
        log.debug("getConnection1(usernameSession1={})", usernameSession1);

        String usernameOrig = null;
        String passwordOrig = null;
        
        try {
            if (!commonPoolDataSource.getUsername().equalsIgnoreCase(usernameSession1)) {
                usernameOrig = commonPoolDataSource.getUsername();
                passwordOrig = commonPoolDataSource.getPassword();
                commonPoolDataSource.setUsername(usernameSession1);
                commonPoolDataSource.setPassword(passwordSession1);
            }
            return commonPoolDataSource.getConnection();
        } finally {
            if (usernameOrig != null) {
                commonPoolDataSource.setUsername(usernameOrig);
                usernameOrig = null;
            }
            if (passwordOrig != null) {
                commonPoolDataSource.setPassword(passwordOrig);
                passwordOrig = null;
            }
        }
    }

    protected void updatePool(@NonNull final HikariDataSource configPoolDataSource,
                              @NonNull final HikariDataSource commonPoolDataSource,
                              final boolean initializing,
                              final boolean isParentPoolDataSource) {
        log.debug(">updatePool(isParentPoolDataSource={})", isParentPoolDataSource);

        try {
            final HikariConfig newConfig = new HikariConfig();

            commonPoolDataSource.copyStateTo(newConfig);
            
            updatePoolName(configPoolDataSource,
                           newConfig,
                           initializing,
                           isParentPoolDataSource);
            if (!isParentPoolDataSource) {
                updatePoolSizes(configPoolDataSource,
                                newConfig,
                                initializing);
            }

            newConfig.copyStateTo(commonPoolDataSource);
        } finally {
            log.debug("<updatePool()");
        }
    }
    
    private void updatePoolName(@NonNull final HikariDataSource configPoolDataSource,
                                @NonNull final HikariConfig commonPoolDataSource,
                                final boolean initializing,
                                final boolean isParentPoolDataSource) {
        try {
            log.debug(">updatePoolName()");

            assert configPoolDataSource != null;
            assert commonPoolDataSource != null;
            
            log.debug("config pool data source; address: {}; name: {}",
                      configPoolDataSource,
                      configPoolDataSource.getPoolName());

            log.debug("common pool data source; address: {}; name: {}",
                      commonPoolDataSource,
                      commonPoolDataSource.getPoolName());

            if (initializing && isParentPoolDataSource) {
                commonPoolDataSource.setPoolName(POOL_NAME_PREFIX);                
            }

            final String suffix = "-" + getPoolDataSourceConfiguration().getSchema();

            // set pool name
            if (initializing) {
                commonPoolDataSource.setPoolName(commonPoolDataSource.getPoolName() + suffix);
            } else {
                commonPoolDataSource.setPoolName(commonPoolDataSource.getPoolName().replace(suffix, ""));
            }
        } finally {
            log.debug("config pool data source; address: {}; name: {}",
                      configPoolDataSource,
                      configPoolDataSource.getPoolName());

            log.debug("common pool data source; address: {}; name: {}",
                      commonPoolDataSource,
                      commonPoolDataSource.getPoolName());

            log.debug("<updatePoolName()");
        }
    }

    private void updatePoolSizes(@NonNull final HikariDataSource configPoolDataSource,
                                 @NonNull final HikariConfig commonPoolDataSource,
                                 final boolean initializing) {
        try {
            log.debug(">updatePoolSizes()");

            assert configPoolDataSource != null;
            assert commonPoolDataSource != null;

            log.debug("config pool data source; address: {}; name: {}; pool sizes before: minimum/maximum: {}/{}",
                      configPoolDataSource,
                      configPoolDataSource.getPoolName(),
                      configPoolDataSource.getMinimumIdle(),
                      configPoolDataSource.getMaximumPoolSize());

            log.debug("common pool data source; address: {}; name: {}; pool sizes before: minimum/maximum: {}/{}",
                      commonPoolDataSource,
                      commonPoolDataSource.getPoolName(),
                      commonPoolDataSource.getMinimumIdle(),
                      commonPoolDataSource.getMaximumPoolSize());
            
            final int sign = initializing ? +1 : -1;

            int thisSize, pdsSize;

            pdsSize = configPoolDataSource.getMinimumIdle();
            thisSize = Integer.max(commonPoolDataSource.getMinimumIdle(), 0);

            log.debug("minimum pool sizes before changing it: this/pds: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {                
                commonPoolDataSource.setMinimumIdle(pdsSize + thisSize);
            }
                
            pdsSize = configPoolDataSource.getMaximumPoolSize();
            thisSize = Integer.max(commonPoolDataSource.getMaximumPoolSize(), 0);

            log.debug("maximum pool sizes before changing it: this/pds: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {
                commonPoolDataSource.setMaximumPoolSize(pdsSize + thisSize);
            }
        } finally {
            log.debug("config pool data source; address: {}; name: {}; pool sizes after: minimum/maximum: {}/{}",
                      configPoolDataSource,
                      configPoolDataSource.getPoolName(),
                      configPoolDataSource.getMinimumIdle(),
                      configPoolDataSource.getMaximumPoolSize());

            log.debug("common pool data source; address: {}; name: {}; pool sizes after: minimum/maximum: {}/{}",
                      commonPoolDataSource,
                      commonPoolDataSource.getPoolName(),
                      commonPoolDataSource.getMinimumIdle(),
                      commonPoolDataSource.getMaximumPoolSize());

            log.debug("<updatePoolSizes()");
        }
    }
}
