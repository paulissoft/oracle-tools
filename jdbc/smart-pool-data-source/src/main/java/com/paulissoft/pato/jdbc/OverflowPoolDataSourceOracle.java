package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Properties;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;
import lombok.NonNull;
import oracle.jdbc.OracleConnection;


@Slf4j
public class OverflowPoolDataSourceOracle extends SimplePoolDataSourceOracle implements OverflowPoolDataSource {

    private class CommonIdRefCountPair {
        public final String commonId;

        public int refCount = 1;

        public CommonIdRefCountPair(final String commonId) {
            this.commonId = commonId;
        }
    }

    // all static related

    // Store all objects of type SimplePoolDataSourceOracle in the hash table.
    // The key is the common id, i.e. the set of common properties
    private static final HashMap<SimplePoolDataSourceOracle,CommonIdRefCountPair> lookupSimplePoolDataSourceOracle = new HashMap();

    // all object related
    
    @Delegate(types=SimplePoolDataSourceOracle.class, excludes=AutoCloseable.class)
    private final SimplePoolDataSourceOracle poolDataSource;

    // constructor
    // @param poolDataSourceConfigurationOracle  The original configuration with maximumPoolSize > minimumIdle
    public OverflowPoolDataSourceOracle(final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracle) {
        final PoolDataSourceConfigurationOracle poolDataSourceConfigurationOracleCopy = poolDataSourceConfigurationOracle.toBuilder().build();
        final PoolDataSourceConfigurationCommonId poolDataSourceConfigurationCommonId =
            new PoolDataSourceConfigurationCommonId(poolDataSourceConfigurationOracle);
        final String commonId = poolDataSourceConfigurationCommonId.toString();
        SimplePoolDataSourceOracle pds = null;

        synchronized (lookupSimplePoolDataSourceOracle) {
            for (var entry: lookupSimplePoolDataSourceOracle.entrySet()) {
                final SimplePoolDataSourceOracle key = entry.getKey();
                final CommonIdRefCountPair value = entry.getValue();
                
                if (value.commonId.equals(commonId) && key.isInitializing()) {
                    pds = key;
                    value.refCount++;
                    break;
                }
            }

            poolDataSourceConfigurationOracleCopy
                .builder()
                .maxPoolSize(poolDataSourceConfigurationOracle.getMaxPoolSize() - poolDataSourceConfigurationOracle.getMinPoolSize())
                .minPoolSize(0)
                .connectionTimeout(poolDataSourceConfigurationOracle.getConnectionTimeout() - getMinConnectionTimeout())
                .build();

	    final String proxyUsername = poolDataSourceConfigurationOracle.getProxyUsername();
	    final String schema = poolDataSourceConfigurationOracle.getSchema();

	    if (proxyUsername != null) {
                poolDataSourceConfigurationOracleCopy.setUsername(proxyUsername);
	    }

            if (pds == null) {
                poolDataSource = new SimplePoolDataSourceOracle(poolDataSourceConfigurationOracleCopy);
                lookupSimplePoolDataSourceOracle.put(poolDataSource, new CommonIdRefCountPair(commonId));
            } else {
                poolDataSource = pds;
            }
            updatePool(poolDataSourceConfigurationOracleCopy, pds == null, schema);
        }
    }

    // get a connection for the multi-session proxy model
    //
    // @param username  provided by pool data source that needs the overflow pool data source to connect to schema via a proxy session through username (e.g. bc_proxy[bodomain])
    // @param password  provided by pool data source that needs the overflow pool data source to connect to schema via a proxy session through with this password
    // @param schema    provided by pool data source that needs the overflow pool data source to connect to schema via a proxy session (e.g. bodomain)
    public Connection getConnection(@NonNull final String username, @NonNull final String password, @NonNull final String schema) throws SQLException {
        log.debug(">getConnection(id={}, schema={})",
                  getId(), schema);

	final Instant tm0 = Instant.now();
        Connection conn = null;

	try {
	    conn = getConnection(username, password);
        } finally {
            log.debug("<getConnection(id={})", getId());
        }
        
        if (statisticsEnabled.get()) {
	    poolDataSourceStatistics.updateStatistics(this,
						      conn,
						      Duration.between(tm0, Instant.now()).toMillis(),
						      true);
        }

        return conn;
    }

    private void updatePoolDescription(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfiguration,
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

    private void updatePoolSizes(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfiguration) {
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

    private void updatePool(@NonNull final PoolDataSourceConfigurationOracle poolDataSourceConfiguration,
			    final boolean isFirstPoolDataSource,
			    final String schema) {
        updatePoolDescription(poolDataSourceConfiguration, isFirstPoolDataSource, schema);
        if (!isFirstPoolDataSource) {
            updatePoolSizes(poolDataSourceConfiguration);
        }
    }

    @Override
    public void close() {       
        synchronized (lookupSimplePoolDataSourceOracle) {
            final SimplePoolDataSourceOracle key = poolDataSource;
            final CommonIdRefCountPair value = lookupSimplePoolDataSourceOracle.get(key);

            if (value != null) {
                value.refCount--;
                if (value.refCount <= 0) {
                    poolDataSource.close();
                    lookupSimplePoolDataSourceOracle.remove(key);
                }
            }
        }
    }
}
