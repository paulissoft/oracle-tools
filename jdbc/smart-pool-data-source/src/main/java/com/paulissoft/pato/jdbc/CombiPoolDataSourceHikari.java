package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariConfig;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import lombok.NonNull;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class CombiPoolDataSourceHikari
    extends CombiPoolDataSource<SimplePoolDataSourceHikari, PoolDataSourceConfigurationHikari>
    implements SimplePoolDataSource, PoolDataSourcePropertiesSettersHikari, PoolDataSourcePropertiesGettersHikari {

    /*
     * Constructors
     */
    
    public CombiPoolDataSourceHikari() {
        super(new SimplePoolDataSourceHikari(), new PoolDataSourceConfigurationHikari());
        log.debug("constructor 1: everything null, INITIALIZING");
    }
    
    public CombiPoolDataSourceHikari(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari) {
        super(SimplePoolDataSourceHikari::new, poolDataSourceConfigurationHikari);
        log.debug("constructor 2: poolDataSourceConfigurationHikari != null (fixed), OPEN");
    }

    public CombiPoolDataSourceHikari(@NonNull final CombiPoolDataSourceHikari activeParent) {
        this(new PoolDataSourceConfigurationHikari(), activeParent);
        log.debug("constructor 3: activeParent != null, INITIALIZING");
    }

    public CombiPoolDataSourceHikari(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari,
                                     @NonNull final CombiPoolDataSourceHikari activeParent) {
        super(poolDataSourceConfigurationHikari, activeParent);
        log.debug("constructor 4: poolDataSourceConfigurationHikari != null (fixed), activeParent != null, INITIALIZING");
    }
    
    public CombiPoolDataSourceHikari(@NonNull final CombiPoolDataSourceHikari activeParent,
                                     String driverClassName,
                                     String url,
                                     String username,
                                     String password,
                                     String type) {
        this(PoolDataSourceConfigurationHikari.build(driverClassName,
                                                     url,
                                                     username,
                                                     password,
                                                     type != null ? type : CombiPoolDataSourceHikari.class.getName()),
             activeParent);
        log.debug("constructor 5: connection properties != null (fixed), activeParent != null, INITIALIZING");
    }

    public CombiPoolDataSourceHikari(String driverClassName,
                                     String url,
                                     String username,
                                     String password,
                                     String type,
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
        this(PoolDataSourceConfigurationHikari.build(driverClassName,
                                                     url,
                                                     username,
                                                     password,
                                                     // cannot reference this before supertype constructor has been called,
                                                     // hence can not use this in constructor above
                                                     type != null ? type : CombiPoolDataSourceHikari.class.getName(),
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
        log.debug("constructor 6: properties != null (fixed), activeParent != null, OPEN");
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

    // setXXX methods only (getPoolDataSourceSetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesSettersHikari.class, excludes=ToOverrideHikari.class) // do not delegate setPassword()
    private PoolDataSourcePropertiesSettersHikari getPoolDataSourceSetter() {
        try {
            switch (getState()) {
            case INITIALIZING:
                return getPoolDataSourceConfiguration();
            case CLOSED:
                throw new IllegalStateException("You can not use the pool once it is closed.");
            default:
                throw new IllegalStateException("The configuration of the pool is sealed once started.");
            }
        } catch (IllegalStateException ex) {
            log.error("Exception in getPoolDataSourceSetter(): {}", ex);
            throw ex;
        }
    }
        
    // getXXX methods only (getPoolDataSourceGetter() may return different values depending on state hence use a function)
    @Delegate(types=PoolDataSourcePropertiesGettersHikari.class, excludes=ToOverrideHikari.class)
    private PoolDataSourcePropertiesGettersHikari getPoolDataSourceGetter() {
        try {
            switch (getState()) {
            case CLOSED:
                throw new IllegalStateException("You can not use the pool once it is closed.");
            case INITIALIZING:
                return getPoolDataSourceConfiguration();
            default:
                return getPoolDataSource(); // as soon as the initializing phase is over, the actual pool data source should be used
            }
        } catch (IllegalStateException ex) {
            log.error("Exception in getPoolDataSourceGetter(): {}", ex);
            throw ex;
        }
    }

    // no getXXX() nor setXXX(), just the rest (getPoolDataSource() may return different values depending on state hence use a function)
    @Delegate(excludes={ PoolDataSourcePropertiesSettersHikari.class, PoolDataSourcePropertiesGettersHikari.class, ToOverrideHikari.class })
    @Override
    protected SimplePoolDataSourceHikari getPoolDataSource() {
        return super.getPoolDataSource();
    }

    public void setUsername(String username) {
        try {
            getPoolDataSourceSetter().setUsername(username);
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    public void setPassword(String password) {
        try {
            getPoolDataSourceSetter().setPassword(password);        
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    /*
     * Connection
     */

    protected Connection getConnection(@NonNull final SimplePoolDataSourceHikari poolDataSource,
                                       @NonNull final String usernameSession1,
                                       @NonNull final String passwordSession1,
                                       @NonNull final String usernameSession2) throws SQLException {
        return getConnection2(poolDataSource,
                              usernameSession1,
                              passwordSession1,
                              usernameSession2,
                              getActiveChildren(),
                              null,
                              null);
    }
    
    protected Connection getConnection1(@NonNull final SimplePoolDataSourceHikari poolDataSource,
                                        @NonNull final String usernameSession1,
                                        @NonNull final String passwordSession1) throws SQLException {
        log.debug(">getConnection1(id={}, usernameSession1={})", getId(), usernameSession1);

        // String usernameOrig = null;

        try {
            assert poolDataSource.getUsername().equalsIgnoreCase(usernameSession1) || getActiveChildren() == 0
                : String.format("The pool data source username is '%s' but should be '%s'.",
                                poolDataSource.getUsername(),
                                usernameSession1);
            
            // There is only a need to switch from "bc_proxy[boauth]" to "bc_proxy" if there are active children.
            // Because when it is not a combined pool just connect to "bc_proxy[boauth]"
            // and do not use OracleConnection.openProxySession().
            /*
            if (!poolDataSource.getUsername().equalsIgnoreCase(usernameSession1) && getActiveChildren() > 0) {
                usernameOrig = poolDataSource.getUsername();
                poolDataSource.setUsername(usernameSession1);
                // password stays the same
            }
            */
                
            return poolDataSource.getConnection();
        } finally {
            /*
            if (usernameOrig != null) {
                poolDataSource.setUsername(usernameOrig);
                // password stays the same
            }
            */
            log.debug("<getConnection1(id={})", getId());
        }
    }

    @Override
    protected void updatePool(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfiguration,
                              @NonNull final SimplePoolDataSourceHikari poolDataSource,
                              final boolean initializing,
                              final boolean isParentPoolDataSource) {
        log.debug(">updatePool(id={}, isParentPoolDataSource={})", getId(), isParentPoolDataSource);

        try {
            final HikariConfig newConfig = new HikariConfig();

            poolDataSource.copyStateTo(newConfig);
            
            updatePoolDescription(poolDataSourceConfiguration,
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

    public String getPoolNamePrefix() {
        return "HikariPool";
    }

    private void updatePoolDescription(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfiguration,
                                       @NonNull final HikariConfig poolDataSource,
                                       final boolean initializing,
                                       final boolean isParentPoolDataSource) {
        try {
            log.debug(">updatePoolDescription(id={})", getId());

            log.debug("config pool data source; name: {}; address: {}",
                      poolDataSourceConfiguration.getPoolName(),
                      poolDataSourceConfiguration);

            log.debug("common pool data source; name: {}; address: {}",
                      poolDataSource.getPoolName(),
                      poolDataSource);

            final ArrayList<String> items = new ArrayList(Arrays.asList(poolDataSource.getPoolName().split("-")));
            final String schema = getPoolDataSourceConfiguration().getSchema();

            log.debug("items: {}; schema: {}", items, schema);

            if (initializing) {
                if (isParentPoolDataSource) {
                    items.clear();
                    items.add(getPoolNamePrefix());
                    items.add(schema);
                } else if (!isParentPoolDataSource && !items.contains(schema)) {
                    items.add(schema);
                }
            } else if (!isParentPoolDataSource && items.contains(schema)) {
                items.remove(schema);
            }

            if (items.size() >= 2) {
                poolDataSource.setPoolName(String.join("-", items));
            }

            // keep poolDataSource.getPoolName() and poolDataSourceConfiguration.getPoolName() in sync
            poolDataSourceConfiguration.setPoolName(getPoolNamePrefix() + "-" + schema); // own prefix
        } finally {
            log.debug("config pool data source; name: {}; address: {}",
                      poolDataSourceConfiguration.getPoolName(),
                      poolDataSourceConfiguration);

            log.debug("common pool data source; name: {}; address: {}",
                      poolDataSource.getPoolName(),
                      poolDataSource);

            log.debug("<updatePoolDescription(id={})", getId());
        }
    }

    private void updatePoolSizes(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfiguration,
                                 @NonNull final HikariConfig poolDataSource,
                                 final boolean initializing) {
        try {
            log.debug(">updatePoolSizes(id={})", getId());
            log.debug("config pool data source; name: {}; address: {}; pool sizes before: minimum/maximum: {}/{}",
                      poolDataSourceConfiguration.getPoolName(),
                      poolDataSourceConfiguration,
                      poolDataSourceConfiguration.getMinimumIdle(),
                      poolDataSourceConfiguration.getMaximumPoolSize());
            log.debug("common pool data source; name: {}; address: {}; pool sizes before: minimum/maximum: {}/{}",
                      poolDataSource.getPoolName(),
                      poolDataSource,
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

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize && pdsSize + thisSize > 0) {
                poolDataSource.setMaximumPoolSize(pdsSize + thisSize);
            }
        } finally {
            log.debug("config pool data source; name: {}; address: {}; pool sizes after: minimum/maximum: {}/{}",
                      poolDataSourceConfiguration.getPoolName(),
                      poolDataSourceConfiguration,
                      poolDataSourceConfiguration.getMinimumIdle(),
                      poolDataSourceConfiguration.getMaximumPoolSize());
            log.debug("common pool data source; name: {}; address: {}; pool sizes after: minimum/maximum: {}/{}",
                      poolDataSource.getPoolName(),
                      poolDataSource,
                      poolDataSource.getMinimumIdle(),
                      poolDataSource.getMaximumPoolSize());
            log.debug("<updatePoolSizes(id={})", getId());
        }
    }
}
