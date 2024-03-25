package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariConfigMXBean;
import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import java.sql.Connection;
import java.sql.SQLException;
import lombok.NonNull;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class CombiPoolDataSourceHikari extends CombiPoolDataSource<HikariDataSource> implements HikariConfigMXBean, PoolDataSourcePropertiesHikari {

    private static final String POOL_NAME_PREFIX = "HikariPool";

    @Delegate(types=PoolDataSourcePropertiesHikari.class, excludes=ToOverride.class) // do not delegate setPassword()
    private HikariDataSource configPoolDataSource = null; // must be set in constructor and changed to commonPoolDataSource in init()

    @Delegate(excludes=ToOverride.class)
    private HikariDataSource commonPoolDataSource = null; // must be set in init

    public CombiPoolDataSourceHikari() {
        this(new HikariDataSource());
        log.info("CombiPoolDataSourceHikari()");
    }

    private CombiPoolDataSourceHikari(@NonNull final HikariDataSource configPoolDataSource) {
        this(configPoolDataSource, null);
        log.info("CombiPoolDataSourceHikari({})", configPoolDataSource);
    }
    
    private CombiPoolDataSourceHikari(@NonNull final HikariDataSource configPoolDataSource, final CombiPoolDataSourceHikari commonCombiPoolDataSource) {
        super(configPoolDataSource, commonCombiPoolDataSource);
        this.configPoolDataSource = configPoolDataSource;
        log.info("CombiPoolDataSourceHikari({}, {})", configPoolDataSource, commonCombiPoolDataSource);
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
        configPoolDataSource.setUsername(username);
    }

    public PoolDataSourceConfiguration getPoolDataSourceConfiguration() {
        return getPoolDataSourceConfiguration(true);
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

    @PostConstruct
    @Override
    public void init() {
        super.init();
        // from now on getX() calls wil return common characterics (think of getMaximumPoolSize())
        configPoolDataSource = commonPoolDataSource = getCommonPoolDataSource();
    }

    @PreDestroy
    @Override
    public void done() {
        super.done();
        configPoolDataSource = null;
        // commonPoolDataSource = null; /* do not do this because it is needed in close() below */
    }

    protected Connection getConnection1(@NonNull final String usernameSession1,
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

    public Connection getConnection() throws SQLException {
        return getConnection(getUsernameSession1(), getPasswordSession1(), getUsernameSession2());
    }

    public Connection getConnection(String username, String password) throws SQLException {
        return commonPoolDataSource.getConnection(username, password);
    }

    protected void updatePool(@NonNull final HikariDataSource configPoolDataSource,
                              @NonNull final HikariDataSource commonPoolDataSource,
                              final boolean initializing) {
        log.debug(">updatePool(isParentPoolDataSource={})", isParentPoolDataSource());

        final HikariConfig newConfig = new HikariConfig();

        commonPoolDataSource.copyStateTo(newConfig);
            
        updatePoolName(configPoolDataSource,
                       newConfig,
                       initializing);
        updatePoolSizes(configPoolDataSource,
                        newConfig,
                        initializing);

        newConfig.copyStateTo(commonPoolDataSource);

        log.debug("<updatePool()");
    }
    
    private void updatePoolName(@NonNull final HikariDataSource configPoolDataSource,
                                @NonNull final HikariConfig commonPoolDataSource,
                                final boolean initializing) {
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

            final String suffix = "-" + getUsernameSession2();

            // set pool name
            if (initializing) {
                if (isParentPoolDataSource()) {
                    commonPoolDataSource.setPoolName(POOL_NAME_PREFIX);
                    commonPoolDataSource.setPoolName(commonPoolDataSource.getPoolName() + suffix);
                }
                //configPoolDataSource.setPoolName(POOL_NAME_PREFIX);
                //configPoolDataSource.setPoolName(configPoolDataSource.getPoolName() + suffix);
            } else {
                if (isParentPoolDataSource()) {
                    commonPoolDataSource.setPoolName(commonPoolDataSource.getPoolName().replace(suffix, ""));
                }
                //configPoolDataSource.setPoolName(configPoolDataSource.getPoolName().replace(suffix, ""));
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

            // when configPoolDataSource equals commonPoolDataSource there is no need to adjust pool sizes
            if (isParentPoolDataSource()) {
                return;
            }
            
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

    @Override
    public void close() {
        if (canClose()) {
            super.close();
            commonPoolDataSource.close();
        }
    }
}
