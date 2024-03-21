package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import java.sql.SQLException;
import lombok.extern.slf4j.Slf4j;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;


@Slf4j
public class CommonPoolDataSourceHikari extends HikariDataSource {

    private static final String POOL_NAME_PREFIX = "HikariPool";

    // Only at the first PoolDataSourceHikari.getConnection() time we need to join a PoolDataSourceHikari to a CommonPoolDataSourceHikari.
    // Before it is not reliable since properties may not have been set yet.
    private static final Set<CommonPoolDataSourceHikari> commonPoolDataSources;

    static {
        // see https://www.geeksforgeeks.org/how-to-create-a-thread-safe-concurrenthashset-in-java/
        final ConcurrentHashMap<CommonPoolDataSourceHikari, Integer> dummy = new ConcurrentHashMap<>();
 
        commonPoolDataSources = dummy.newKeySet();
    }

    // join a PoolDataSourceHikari to a CommonPoolDataSourceHikari.
    public void join(final PoolDataSourceHikari pds) {
        log.debug(">join({})", pds);

        try {
            log.debug("pool sizes before: minimum/maximum: {}/{}",
                      getMinimumIdle(),
                      getMaximumPoolSize());

            int oldSize, newSize;

            newSize = pds.getMinimumIdle();
            oldSize = getMinimumIdle();

            log.debug("minimum pool sizes before setting it: old/new: {}/{}",
                      oldSize,
                      newSize);

            if (newSize >= 0) {                
                setMinimumIdle(newSize + Integer.max(oldSize, 0));
            }
                
            newSize = pds.getMaximumPoolSize();
            oldSize = getMaximumPoolSize();

            log.debug("maximum pool sizes before setting it: old/new: {}/{}",
                      oldSize,
                      newSize);

            if (newSize >= 0) {
                setMaximumPoolSize(newSize + Integer.max(oldSize, 0));
            }
        } finally {
            log.debug("pool sizes after: minimum/maximum: {}/{}",
                      getMinimumIdle(),
                      getMaximumPoolSize());
            
            log.debug("<join()");
        }
    }
}
