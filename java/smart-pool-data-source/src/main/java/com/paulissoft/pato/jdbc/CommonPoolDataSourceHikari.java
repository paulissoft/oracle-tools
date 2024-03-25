package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
//import com.zaxxer.hikari.HikariConfigMXBean;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;


@Slf4j
public class CommonPoolDataSourceHikari extends BasePoolDataSourceHikari {

    private static final String POOL_NAME_PREFIX = "HikariPool";

    // as long as there are data sources (still) joined we can not close
    private static final Set<HikariDataSource> dataSources;

    static {
        // see https://www.geeksforgeeks.org/how-to-create-a-thread-safe-concurrenthashset-in-java/
        final ConcurrentHashMap<HikariDataSource, Integer> dummy = new ConcurrentHashMap<>();
 
        dataSources = dummy.newKeySet();
    }

    public CommonPoolDataSourceHikari() {
    }
    
    public CommonPoolDataSourceHikari(String driverClassName,
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
        super(driverClassName,
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
              leakDetectionThreshold);
        
        if (poolName == null || poolName.isEmpty()) {
            setPoolName(POOL_NAME_PREFIX);
        }
        setPoolName(getPoolName() + "-" + getUsernameSession2());
    }

    public void join(final HikariDataSource pds) {
        try {
            update((PoolDataSourceHikari) pds, true);
        } finally {
            dataSources.add(pds);
        }
    }

    public void leave(final HikariDataSource pds) {
        try {
            update((PoolDataSourceHikari) pds, false);
        } finally {
            dataSources.remove(pds);
        }
    }

    public void close() {
        if (dataSources.isEmpty()) {
            super.close();
        }
    }

    private void update(final PoolDataSourceHikari pds, final boolean joinPoolDataSource) {
        log.debug(">update({}, {})", pds, joinPoolDataSource);

        final int sign = joinPoolDataSource ? +1 : -1;

        try {
            log.debug("pool sizes before: minimum/maximum: {}/{}",
                      getMinimumIdle(),
                      getMaximumPoolSize());

            int thisSize, pdsSize;

            pdsSize = pds.getMinimumIdle();
            thisSize = Integer.max(getMinimumIdle(), 0);

            log.debug("minimum pool sizes before changing it: this/pds: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {
                setMinimumIdle(sign * pdsSize + thisSize);
            }
                
            pdsSize = pds.getMaximumPoolSize();
            thisSize = Integer.max(getMaximumPoolSize(), 0);

            log.debug("maximum pool sizes before changing it: this/pds: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {
                setMaximumPoolSize(sign * pdsSize + thisSize);
            }

            setPoolName(getPoolName() + "-" + pds.getUsernameSession2());
        } finally {
            log.debug("pool sizes after: minimum/maximum: {}/{}",
                      getMinimumIdle(),
                      getMaximumPoolSize());
            
            log.debug("<update()");
        }
    }
}
