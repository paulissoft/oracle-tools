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
    extends CombiPoolDataSource<HikariDataSource>
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
                                     long leakDetectionThreshold)
                                         {
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

    private CombiPoolDataSourceHikari(final Object[] fields) {
        super(fields);
    }

    protected static Object[] build(String driverClassName,
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
                                    long leakDetectionThreshold)
    {
        final HikariDataSource hikariDataSource = new HikariDataSource();
        
        int nr = 0;
        final int maxNr = 18;
        
        do {
            try {
                switch(nr) {
                case 0: hikariDataSource.setDriverClassName(driverClassName); break;
                case 1: hikariDataSource.setJdbcUrl(url); break;
                case 2: hikariDataSource.setUsername(username); break;
                case 3: hikariDataSource.setPassword(password); break;
                case 4: /* connection pool name is not copied here */ break;
                case 5: hikariDataSource.setMaximumPoolSize(maximumPoolSize); break;
                case 6: hikariDataSource.setMinimumIdle(minimumIdle); break;
                case 7: hikariDataSource.setAutoCommit(autoCommit); break;
                case 8: hikariDataSource.setConnectionTimeout(connectionTimeout); break;
                case 9: hikariDataSource.setIdleTimeout(idleTimeout); break;
                case 10: hikariDataSource.setMaxLifetime(maxLifetime); break;
                case 11: hikariDataSource.setConnectionTestQuery(connectionTestQuery); break;
                case 12: hikariDataSource.setInitializationFailTimeout(initializationFailTimeout); break;
                case 13: hikariDataSource.setIsolateInternalQueries(isolateInternalQueries); break;
                case 14: hikariDataSource.setAllowPoolSuspension(allowPoolSuspension); break;
                case 15: hikariDataSource.setReadOnly(readOnly); break;
                case 16: hikariDataSource.setRegisterMbeans(registerMbeans); break;
                case 17: hikariDataSource.setValidationTimeout(validationTimeout); break;
                case 18: hikariDataSource.setLeakDetectionThreshold(leakDetectionThreshold); break;
                default:
                    throw new IllegalArgumentException(String.format("Wrong value for nr (%d): must be between 0 and %d", nr, maxNr));
                }
            } catch (Exception ex) {
                log.warn("nr: {}; exception: {}", nr, SimplePoolDataSource.exceptionToString(ex));
            }
        } while (++nr <= maxNr);

        return new Object[] { hikariDataSource, password };
    }
    
    // setXXX methods only (determinePoolDataSourceSetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesSettersHikari.class, excludes=ToOverride.class) // do not delegate setPassword()
    private HikariDataSource getPoolDataSourceSetter() {
        return determinePoolDataSourceSetter();
    }
        
    // getXXX methods only (determinePoolDataSourceGetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesGettersHikari.class, excludes=ToOverride.class)
    private HikariDataSource getPoolDataSourceGetter() {
        return determinePoolDataSourceGetter();
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
        determinePoolDataSourceGetter().setUsername(username);
    }

    public PoolDataSourceConfiguration getPoolDataSourceConfiguration() {
        return getPoolDataSourceConfiguration(true);
    }
    
    private PoolDataSourceConfiguration getPoolDataSourceConfiguration(final boolean excludeNonIdConfiguration) {
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

            final String suffix = "-" + getUsernameSession2();

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
