package com.paulissoft.pato.jdbc;

//import java.sql.Connection;
//import java.sql.SQLException;
//import java.time.Duration;
//import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
//import java.util.concurrent.atomic.AtomicBoolean;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;
import lombok.NonNull;

@Slf4j
public class OverflowPoolDataSourceHikari extends SimplePoolDataSourceHikari {

    private class CommonIdRefCountPair {
        public final String commonId;

        public int refCount = 1;

        public CommonIdRefCountPair(final String commonId) {
            this.commonId = commonId;
        }
    }

    // all static related

    // Store all objects of type SimplePoolDataSourceHikari in the hash table.
    // The key is the common id, i.e. the set of common properties
    private static final HashMap<SimplePoolDataSourceHikari,CommonIdRefCountPair> lookupSimplePoolDataSourceHikari = new HashMap();

    // all object related
    
    @Delegate(types=SimplePoolDataSourceHikari.class, excludes=AutoCloseable.class)
    private final SimplePoolDataSourceHikari poolDataSource;

    // constructor
    // @param poolDataSourceConfigurationHikari  The original configuration with maximumPoolSize > minimumIdle
    public OverflowPoolDataSourceHikari(final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari) {
        final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikariCopy = poolDataSourceConfigurationHikari.toBuilder().build();
        // now username will be the username to connect to, so bc_proxy[bodomain] becomes bc_proxy
        final PoolDataSourceConfigurationCommonId poolDataSourceConfigurationCommonId =
            new PoolDataSourceConfigurationCommonId(poolDataSourceConfigurationHikari);
        final String commonId = poolDataSourceConfigurationCommonId.toString();
        SimplePoolDataSourceHikari pds = null;

        synchronized (lookupSimplePoolDataSourceHikari) {
            for (var entry: lookupSimplePoolDataSourceHikari.entrySet()) {
                final SimplePoolDataSourceHikari key = entry.getKey();
                final CommonIdRefCountPair value = entry.getValue();
                
                if (value.commonId.equals(commonId) && key.isInitializing()) {
                    pds = key;
                    value.refCount++;
                    break;
                }
            }

            poolDataSourceConfigurationHikariCopy
                .builder()
                .maximumPoolSize(poolDataSourceConfigurationHikari.getMaximumPoolSize() - poolDataSourceConfigurationHikari.getMinimumIdle())
                .minimumIdle(0)
                .connectionTimeout(poolDataSourceConfigurationHikari.getConnectionTimeout() - getMinConnectionTimeout())
                .build();

	    final String proxyUsername = poolDataSourceConfigurationHikari.getProxyUsername();
	    final String schema = poolDataSourceConfigurationHikari.getSchema();

	    if (proxyUsername != null) {
                poolDataSourceConfigurationHikariCopy.setUsername(proxyUsername);
	    }

            if (pds == null) {
                poolDataSource = new SimplePoolDataSourceHikari(poolDataSourceConfigurationHikariCopy);
                lookupSimplePoolDataSourceHikari.put(poolDataSource, new CommonIdRefCountPair(commonId));
            } else {
                poolDataSource = pds;
            }
            updatePool(poolDataSourceConfigurationHikariCopy, pds == null, schema);
        }
    }

    private void updatePoolDescription(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfiguration,
				       final boolean isFirstPoolDataSource,
				       final String schema) {
        final ArrayList<String> items = new ArrayList(Arrays.asList(poolDataSource.getPoolName().split("-")));

        log.debug("items: {}; schema: {}", items, schema);

        if (isFirstPoolDataSource) {
            items.clear();
            items.add(poolDataSource.getPoolNamePrefix());
            items.add(schema);
        } else if (!items.contains(schema)) {
            items.add(schema);
        }
        
        if (items.size() >= 2) {
            poolDataSource.setPoolName(String.join("-", items));
        }
        
        // keep poolDataSource.getPoolName() and poolDataSourceConfiguration.getPoolName() in sync
	// GJP 2024-07-11 Not anymore
        // poolDataSourceConfiguration.setPoolName(poolDataSource.getPoolNamePrefix() + "-" + schema); // own prefix
    }

    private void updatePoolSizes(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfiguration) {
        int thisSize, pdsSize;

        pdsSize = poolDataSourceConfiguration.getMinimumIdle();
        thisSize = Integer.max(poolDataSource.getMinimumIdle(), 0);

        log.debug("minimum pool sizes before changing it: this/pds: {}/{}",
                  thisSize,
                  pdsSize);

        if (pdsSize >= 0 && pdsSize <= Integer.MAX_VALUE - thisSize) {                
            poolDataSource.setMinimumIdle(pdsSize + thisSize);
        }
                
        pdsSize = poolDataSourceConfiguration.getMaximumPoolSize();
        thisSize = Integer.max(poolDataSource.getMaximumPoolSize(), 0);

        log.debug("maximum pool sizes before changing it: this/pds: {}/{}",
                  thisSize,
                  pdsSize);

        if (pdsSize >= 0 && pdsSize <= Integer.MAX_VALUE - thisSize && pdsSize + thisSize > 0) {
            poolDataSource.setMaximumPoolSize(pdsSize + thisSize);
        }
    }

    private void updatePool(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfiguration,
			    final boolean isFirstPoolDataSource,
			    final String schema) {
        updatePoolDescription(poolDataSourceConfiguration, isFirstPoolDataSource, schema);
        if (!isFirstPoolDataSource) {
            updatePoolSizes(poolDataSourceConfiguration);
        }
    }

    @Override
    public void close() {       
        synchronized (lookupSimplePoolDataSourceHikari) {
            final SimplePoolDataSourceHikari key = poolDataSource;
            final CommonIdRefCountPair value = lookupSimplePoolDataSourceHikari.get(key);

            if (value != null) {
                value.refCount--;
                if (value.refCount <= 0) {
                    poolDataSource.close();
                    lookupSimplePoolDataSourceHikari.remove(key);
                }
            }
        }
    }
}
