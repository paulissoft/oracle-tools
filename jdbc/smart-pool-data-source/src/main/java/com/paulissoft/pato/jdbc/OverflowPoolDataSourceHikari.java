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
    private final SimplePoolDataSourceHikari delegate;

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


            if (pds == null) {
                delegate = new SimplePoolDataSourceHikari();
                delegate.set(poolDataSourceConfigurationHikariCopy);
                lookupSimplePoolDataSourceHikari.put(delegate, new CommonIdRefCountPair(commonId));
            } else {
                delegate = pds;
            }
            updatePool(poolDataSourceConfigurationHikariCopy, pds == null);
        }
    }

    private void updatePoolDescription(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfiguration, final boolean isFirstPoolDataSource) {
        final ArrayList<String> items = new ArrayList(Arrays.asList(delegate.getPoolName().split("-")));
        final String schema = delegate.get().getSchema();

        log.debug("items: {}; schema: {}", items, schema);

        if (isFirstPoolDataSource) {
            items.clear();
            items.add(delegate.getPoolNamePrefix());
            items.add(schema);
        } else if (!items.contains(schema)) {
            items.add(schema);
        }
        
        if (items.size() >= 2) {
            delegate.setPoolName(String.join("-", items));
        }
        
        // keep poolDataSource.getPoolName() and poolDataSourceConfiguration.getPoolName() in sync
        poolDataSourceConfiguration.setPoolName(delegate.getPoolNamePrefix() + "-" + schema); // own prefix
    }

    private void updatePoolSizes(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfiguration) {
        int thisSize, pdsSize;

        pdsSize = poolDataSourceConfiguration.getMinimumIdle();
        thisSize = Integer.max(delegate.getMinimumIdle(), 0);

        log.debug("minimum pool sizes before changing it: this/pds: {}/{}",
                  thisSize,
                  pdsSize);

        if (pdsSize >= 0 && pdsSize <= Integer.MAX_VALUE - thisSize) {                
            delegate.setMinimumIdle(pdsSize + thisSize);
        }
                
        pdsSize = poolDataSourceConfiguration.getMaximumPoolSize();
        thisSize = Integer.max(delegate.getMaximumPoolSize(), 0);

        log.debug("maximum pool sizes before changing it: this/pds: {}/{}",
                  thisSize,
                  pdsSize);

        if (pdsSize >= 0 && pdsSize <= Integer.MAX_VALUE - thisSize && pdsSize + thisSize > 0) {
            delegate.setMaximumPoolSize(pdsSize + thisSize);
        }
    }

    private void updatePool(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfiguration, final boolean isFirstPoolDataSource) {
        updatePoolDescription(poolDataSourceConfiguration, isFirstPoolDataSource);
        if (!isFirstPoolDataSource) {
            updatePoolSizes(poolDataSourceConfiguration);
        }
    }

    @Override
    public void close() {       
        synchronized (lookupSimplePoolDataSourceHikari) {
            final SimplePoolDataSourceHikari key = delegate;
            final CommonIdRefCountPair value = lookupSimplePoolDataSourceHikari.get(key);

            if (value != null) {
                value.refCount--;
                if (value.refCount <= 0) {
                    delegate.close();
                    lookupSimplePoolDataSourceHikari.remove(key);
                }
            }
        }
    }
}
