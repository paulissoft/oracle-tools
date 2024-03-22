package com.paulissoft.pato.jdbc;

import oracle.ucp.jdbc.PoolDataSourceImpl;
import java.sql.SQLException;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;


@Slf4j
public class CommonPoolDataSourceOracle extends BasePoolDataSourceOracle {

    private static final String POOL_NAME_PREFIX = "OraclePool";

    private static final Set<PoolDataSourceImpl> dataSources;

    static {
        // see https://www.geeksforgeeks.org/how-to-create-a-thread-safe-concurrenthashset-in-java/
        final ConcurrentHashMap<PoolDataSourceImpl, Integer> dummy = new ConcurrentHashMap<>();
 
        dataSources = dummy.newKeySet();
    }

    public CommonPoolDataSourceOracle(@NonNull String url,
                                      @NonNull String username,
                                      @NonNull String password,
                                      String connectionPoolName,
                                      int initialPoolSize,
                                      int minPoolSize,
                                      int maxPoolSize,
                                      @NonNull String connectionFactoryClassName,
                                      boolean validateConnectionOnBorrow,
                                      int abandonedConnectionTimeout,
                                      int timeToLiveConnectionTimeout,
                                      int inactiveConnectionTimeout,
                                      int timeoutCheckInterval,
                                      int maxStatements,
                                      int connectionWaitTimeout,
                                      long maxConnectionReuseTime,
                                      int secondsToTrustIdleConnection,
                                      int connectionValidationTimeout) {
        super(url,
              username,
              password,
              connectionPoolName,
              initialPoolSize,
              minPoolSize,
              maxPoolSize,
              connectionFactoryClassName,
              validateConnectionOnBorrow,
              abandonedConnectionTimeout,
              timeToLiveConnectionTimeout,
              inactiveConnectionTimeout,
              timeoutCheckInterval,
              maxStatements,
              connectionWaitTimeout,
              maxConnectionReuseTime,
              secondsToTrustIdleConnection,
              connectionValidationTimeout);

        try {
            if (connectionPoolName == null || connectionPoolName.isEmpty()) {
                setConnectionPoolName(POOL_NAME_PREFIX);
            }
            setConnectionPoolName(getConnectionPoolName() + "-" + getUsernameSession2());
        } catch (SQLException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    public void join(final PoolDataSourceImpl pds) {
        try {
            update((BasePoolDataSourceOracle)pds, true);
        } finally {
            dataSources.add(pds);
        }
    }

    public void leave(final PoolDataSourceImpl pds) {
        try {
            update((BasePoolDataSourceOracle)pds, false);
        } finally {
            dataSources.remove(pds);
        }
    }

    public void close() {
        // there is no super.close()
    }

    private void update(final BasePoolDataSourceOracle pds, final boolean joinPoolDataSource) {
        log.debug(">update({}, {})", pds, joinPoolDataSource);

        final int sign = joinPoolDataSource ? +1 : -1;

        try {
            log.debug("pool sizes before: initial/minimum/maximum: {}/{}/{}",
                      getInitialPoolSize(),
                      getMinPoolSize(),
                      getMaxPoolSize());

            int thisSize, pdsSize;

            pdsSize = pds.getInitialPoolSize();
            thisSize = Integer.max(getInitialPoolSize(), 0);

            log.debug("initial pool sizes before setting it: old/new: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {
                setInitialPoolSize(pdsSize + Integer.max(thisSize, 0));
            }

            pdsSize = pds.getMinPoolSize();
            thisSize = Integer.max(getMinPoolSize(), 0);

            log.debug("minimum pool sizes before setting it: old/new: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {                
                setMinPoolSize(pdsSize + Integer.max(thisSize, 0));
            }
                
            pdsSize = pds.getMaxPoolSize();
            thisSize = Integer.max(getMaxPoolSize(), 0);

            log.debug("maximum pool sizes before setting it: old/new: {}/{}",
                      thisSize,
                      pdsSize);

            if (pdsSize >= 0 && sign * pdsSize <= Integer.MAX_VALUE - thisSize) {
                setMaxPoolSize(pdsSize + thisSize);
            }

            setConnectionPoolName(getConnectionPoolName() + "-" + pds.getUsernameSession2());
        } catch (SQLException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        } finally {
            log.debug("pool sizes after: initial/minimum/maximum: {}/{}/{}",
                      getInitialPoolSize(),
                      getMinPoolSize(),
                      getMaxPoolSize());

            log.debug("<updatePoolSizes()");
        }
    }
}
