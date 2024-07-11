package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
//import javafx.util.Pair;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;
import lombok.NonNull;

@Slf4j
public class OverflowPoolDataSourceHikari extends SimplePoolDataSourceHikari {

    private class CommonIdRefCountPair {
	public final PoolDataSourceConfigurationCommonId commonId;

	public final AtomicInteger refCount = new AtomicInteger(1);

	public CommonIdRefCountPair(final PoolDataSourceConfigurationCommonId commonId) {
	    this.commonId = commonId;
	}
    }

    // all static related

    // Store all objects of type SimplePoolDataSourceHikari in the hash table.
    // The key is the common id, i.e. the set of common properties
    private static final HashMap<SimplePoolDataSourceHikari,CommonIdRefCountPair> lookupSimplePoolDataSourceHikari = new HashMap();

    // all object related
    
    @Delegate(types=SimplePoolDataSourceHikari.class)
    private final SimplePoolDataSourceHikari delegate;

    // constructor
    public OverflowPoolDataSourceHikari(final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari) {
	final PoolDataSourceConfigurationCommonId commonId =
	    new PoolDataSourceConfigurationCommonId(poolDataSourceConfigurationHikari);
	SimplePoolDataSourceHikari pds = null;

	synchronized (lookupSimplePoolDataSourceHikari) {
	    for (var entry: lookupSimplePoolDataSourceHikari.entrySet()) {
		if (entry.getValue().commonId.equals(commonId) && entry.getKey().isInitializing()) {
		    pds = entry.getKey();
		    break;
		}
	    }
	    if (pds == null) {
		delegate = new SimplePoolDataSourceHikari();	    
		delegate.set(poolDataSourceConfigurationHikari);
		lookupSimplePoolDataSourceHikari.put(delegate, new CommonIdRefCountPair(commonId));
		updatePool(poolDataSourceConfigurationHikari, true);
	    } else {
		delegate = pds;
		updatePool(poolDataSourceConfigurationHikari, false);
	    }
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

    private void updatePoolSizes(@NonNull final PoolDataSourceConfigurationHikari poolDataSourceConfiguration, final boolean isFirstPoolDataSource) {
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
	updatePoolSizes(poolDataSourceConfiguration, isFirstPoolDataSource);
    }
}
