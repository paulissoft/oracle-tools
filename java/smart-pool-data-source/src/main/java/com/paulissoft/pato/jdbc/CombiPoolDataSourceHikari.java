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

    static final String POOL_NAME_PREFIX = "HikariPool";

    public CombiPoolDataSourceHikari(){
        super(HikariDataSource::new, PoolDataSourceConfigurationHikari::new);
    }
    
    public CombiPoolDataSourceHikari(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari) {
        super(HikariDataSource::new, poolDataSourceConfigurationHikari);
    }

    public CombiPoolDataSourceHikari(@NonNull final CombiPoolDataSourceHikari activeParent) {
        super(PoolDataSourceConfigurationHikari::new, activeParent);
    }

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
            .driverClassName(driverClassName)
            .url(url)
            .username(username)
            .password(password)
            // cannot reference this before supertype constructor has been called, hence can not use this in constructor above
            .type(CombiPoolDataSourceHikari.class.getName())
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

    protected interface ToOverrideHikari extends ToOverride {
        // setUsername(java.lang.String) in com.paulissoft.pato.jdbc.CombiPoolDataSourceHikari
        // cannot implement setUsername(java.lang.String) in com.zaxxer.hikari.HikariConfigMXBean:
        // overridden method does not throw java.sql.SQLException
        public void setUsername(String password) throws SQLException;

        // setPassword(java.lang.String) in com.paulissoft.pato.jdbc.CombiPoolDataSourceHikari
        // cannot implement setPassword(java.lang.String) in com.zaxxer.hikari.HikariConfigMXBean:
        // overridden method does not throw java.sql.SQLException
        public void setPassword(String password) throws SQLException;
    }

    // setXXX methods only (determinePoolDataSourceSetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesSettersHikari.class, excludes=ToOverrideHikari.class) // do not delegate setPassword()
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
    @Delegate(types=PoolDataSourcePropertiesGettersHikari.class, excludes=ToOverrideHikari.class)
    private PoolDataSourcePropertiesGettersHikari getPoolDataSourceGetter() {
        switch (getState()) {
        case CLOSED:
            throw new IllegalStateException("You can not use the pool once it is closed().");
        default:
            return getPoolDataSourceConfiguration();
        }
    }

    // no getXXX() nor setXXX(), just the rest (getPoolDataSource() may return different values depending on state hence use a function)
    @Delegate(excludes={ PoolDataSourcePropertiesSettersHikari.class, PoolDataSourcePropertiesGettersHikari.class, ToOverrideHikari.class })
    @Override
    protected HikariDataSource getPoolDataSource() {
        return super.getPoolDataSource();
    }

    /*
    public String getUrl() {
        return getJdbcUrl();
    }
  
    public void setUrl(String jdbcUrl) {
        setJdbcUrl(jdbcUrl);
    }
    */

    public void setUsername(String username) {
        try {
            getPoolDataSourceSetter().setUsername(username);
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    public void setPassword(String password) {
        try {
            getPoolDataSourceSetter().setPassword(password);        
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    @Override
    protected void tearDown() {
        // must get this info before it is actually closed since then getPoolDataSource() will return a error
        final HikariDataSource poolDataSource = getPoolDataSource(); 
        
        // we are in a synchronized context
        super.tearDown();
        if (getState() == State.CLOSED) {
            poolDataSource.close();
        }
    }

    protected Connection getConnection1(@NonNull final HikariDataSource poolDataSource,
                                        @NonNull final String usernameSession1,
                                        @NonNull final String passwordSession1) throws SQLException {
        log.debug("getConnection1(id={}, usernameSession1={})", getId(), usernameSession1);

        String usernameOrig = null;
        String passwordOrig = null;
        
        try {
            if (!poolDataSource.getUsername().equalsIgnoreCase(usernameSession1)) {
                usernameOrig = poolDataSource.getUsername();
                passwordOrig = poolDataSource.getPassword();
                poolDataSource.setUsername(usernameSession1);
                poolDataSource.setPassword(passwordSession1);
            }
            return poolDataSource.getConnection();
        } finally {
            if (usernameOrig != null) {
                poolDataSource.setUsername(usernameOrig);
                usernameOrig = null;
            }
            if (passwordOrig != null) {
                poolDataSource.setPassword(passwordOrig);
                passwordOrig = null;
            }
        }
    }

    @Override
    protected void updatePool(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfiguration,
                              @NonNull final HikariDataSource poolDataSource,
                              final boolean initializing,
                              final boolean isParentPoolDataSource) {
        log.debug(">updatePool(id={}, isParentPoolDataSource={})", getId(), isParentPoolDataSource);

        try {
            final HikariConfig newConfig = new HikariConfig();

            poolDataSource.copyStateTo(newConfig);
            
            updatePoolName(poolDataSourceConfiguration,
                           newConfig,
                           initializing,
                           isParentPoolDataSource);
            if (!isParentPoolDataSource) {
                updatePoolSizes(poolDataSourceConfiguration,
                                newConfig,
                                initializing);
            }

            newConfig.copyStateTo(poolDataSource);
        } finally {
            log.debug("<updatePool(id={})", getId());
        }
    }
    
    private void updatePoolName(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfiguration,
                                @NonNull final HikariConfig poolDataSource,
                                final boolean initializing,
                                final boolean isParentPoolDataSource) {
        try {
            log.debug(">updatePoolName(id={})", getId());

            log.debug("config pool data source; address: {}; name: {}",
                      poolDataSourceConfiguration,
                      poolDataSourceConfiguration.getPoolName());

            log.debug("common pool data source; address: {}; name: {}",
                      poolDataSource,
                      poolDataSource.getPoolName());

            if (initializing && isParentPoolDataSource) {
                poolDataSource.setPoolName(POOL_NAME_PREFIX);
            }

            final String suffix = "-" + getPoolDataSourceConfiguration().getSchema();

            // set pool name
            if (initializing) {
                poolDataSource.setPoolName(poolDataSource.getPoolName() + suffix);
            } else {
                poolDataSource.setPoolName(poolDataSource.getPoolName().replace(suffix, ""));
            }
            // keep poolDataSourceConfiguration in sync
            poolDataSourceConfiguration.setPoolName(poolDataSource.getPoolName());
        } finally {
            log.debug("config pool data source; address: {}; name: {}",
                      poolDataSourceConfiguration,
                      poolDataSourceConfiguration.getPoolName());

            log.debug("common pool data source; address: {}; name: {}",
                      poolDataSource,
                      poolDataSource.getPoolName());

            log.debug("<updatePoolName(id={})", getId());
        }
    }

    private void updatePoolSizes(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfiguration,
                                 @NonNull final HikariConfig poolDataSource,
                                 final boolean initializing) {
        try {
            log.debug(">updatePoolSizes(id={})", getId());

            assert poolDataSourceConfiguration != null;
            assert poolDataSource != null;

            log.debug("config pool data source; address: {}; name: {}; pool sizes before: minimum/maximum: {}/{}",
                      poolDataSourceConfiguration,
                      poolDataSourceConfiguration.getPoolName(),
                      poolDataSourceConfiguration.getMinimumIdle(),
                      poolDataSourceConfiguration.getMaximumPoolSize());

            log.debug("common pool data source; address: {}; name: {}; pool sizes before: minimum/maximum: {}/{}",
                      poolDataSource,
                      poolDataSource.getPoolName(),
                      poolDataSource.getMinimumIdle(),
                      poolDataSource.getMaximumPoolSize());
            
            final int sign = initializing ? +1 : -1;

            int thisSize, pdsSize;

            pdsSize = poolDataSourceConfiguration.getMinimumIdle();
            thisSize = Integer.max(poolDataSource.getMinimumIdle(), 0);

            log.debug("minimum pool sizes before changing it: this/pds: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {                
                poolDataSource.setMinimumIdle(pdsSize + thisSize);
            }
                
            pdsSize = poolDataSourceConfiguration.getMaximumPoolSize();
            thisSize = Integer.max(poolDataSource.getMaximumPoolSize(), 0);

            log.debug("maximum pool sizes before changing it: this/pds: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {
                poolDataSource.setMaximumPoolSize(pdsSize + thisSize);
            }
        } finally {
            log.debug("config pool data source; address: {}; name: {}; pool sizes after: minimum/maximum: {}/{}",
                      poolDataSourceConfiguration,
                      poolDataSourceConfiguration.getPoolName(),
                      poolDataSourceConfiguration.getMinimumIdle(),
                      poolDataSourceConfiguration.getMaximumPoolSize());

            log.debug("common pool data source; address: {}; name: {}; pool sizes after: minimum/maximum: {}/{}",
                      poolDataSource,
                      poolDataSource.getPoolName(),
                      poolDataSource.getMinimumIdle(),
                      poolDataSource.getMaximumPoolSize());

            log.debug("<updatePoolSizes(id={})", getId());
        }
    }
}
