package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import java.util.Hashtable;
import java.util.Vector;
import java.util.concurrent.atomic.AtomicBoolean;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class OverflowPoolDataSourceHikari extends SimplePoolDataSourceHikari {

    // all static related

    // Store all objects of type SimplePoolDataSourceHikari in the hash table.
    // The key is the common id, i.e. the set of common properties
    private static final Hashtable<PoolDataSourceConfigurationCommonId,Vector<SimplePoolDataSourceHikari>> lookupSimplePoolDataSourceHikariSet = new Hashtable();

    // all object related
    
    @Delegate(types=SimplePoolDataSourceHikari.class)
    private final SimplePoolDataSourceHikari delegate;

    // constructor
    public OverflowPoolDataSourceHikari(final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari) {
	final PoolDataSourceConfigurationCommonId poolDataSourceConfigurationCommonId =
	    new PoolDataSourceConfigurationCommonId(poolDataSourceConfigurationHikari);
	Vector<SimplePoolDataSourceHikari> setOfSimplePoolDataSourceHikari = lookupSimplePoolDataSourceHikariSet.get(poolDataSourceConfigurationCommonId);
	SimplePoolDataSourceHikari pds = null;

	if (setOfSimplePoolDataSourceHikari != null) {
	    for (int i = 0; i < setOfSimplePoolDataSourceHikari.size(); i++) {
		pds = setOfSimplePoolDataSourceHikari.get(i);
		if (pds.isInitializing()) {
		    break;
		} else {
		    pds = null;
		}
	    }
	}

	if (pds == null) {
	    delegate = new SimplePoolDataSourceHikari();	    
	    delegate.set(poolDataSourceConfigurationHikari);
	    if (setOfSimplePoolDataSourceHikari == null) {
		setOfSimplePoolDataSourceHikari = new Vector();
		setOfSimplePoolDataSourceHikari.add(delegate);
		lookupSimplePoolDataSourceHikariSet.put(poolDataSourceConfigurationCommonId, setOfSimplePoolDataSourceHikari);
	    }
	} else {
	    delegate = pds;
	}
    }
}
