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
public class OverflowPoolDataSourceHikari extends SimplePoolDataSourceHikari implements OverflowPoolDataSource {

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

    // get a connection for the multi-session proxy model
    //
    // @param schema  provided by pool data source that needs the overflow pool data source to connect to schema via a proxy session
    public Connection getConnection(@NonNull final String schema) throws SQLException {
        log.debug(">getConnection(id={}, schema={})",
                  getId(), schema);

	final int maxProxyLogicalConnectionCount = 0;
	final Instant tm0 = Instant.now();
	Instant tm1 = null;
	int proxyLogicalConnectionCount = 0;
	int proxyOpenSessionCount = 0;
	int proxyCloseSessionCount = 0;
	final String proxyUsername = getUsername(); // see constructor
        final Connection[] connectionsWithWrongSchema =
            maxProxyLogicalConnectionCount > 0 ? new Connection[maxProxyLogicalConnectionCount] : null;
        int nrProxyLogicalConnectionCount = 0;
        Connection conn = null;
        boolean found;

        try {
            while (true) {
                conn = getConnection();

                found = conn.getSchema().equalsIgnoreCase(schema);

                if (found || nrProxyLogicalConnectionCount >= maxProxyLogicalConnectionCount || getIdleConnections() == 0) {
                    break;
                } else {
                    // !found && nrProxyLogicalConnectionCount < maxProxyLogicalConnectionCount && getIdleConnections() > 0

                    connectionsWithWrongSchema[nrProxyLogicalConnectionCount++] = conn;
                
                    proxyLogicalConnectionCount++;
                }
            }

            log.debug("before proxy session - current schema: {}",
                      conn.getSchema());

            // if the current schema is not the requested schema try to open/close the proxy session
            if (!found) {
                tm1 = Instant.now();
                
                OracleConnection oraConn = null;

                try {
                    if (conn.isWrapperFor(OracleConnection.class)) {
                        oraConn = conn.unwrap(OracleConnection.class);
                    }
                } catch (SQLException ex) {
                    oraConn = null;
                }

                if (oraConn != null) {
                    int nr = 0;

                    log.debug("before open proxy session - current schema: {}; is proxy session: {}",
                              conn.getSchema(),
                              oraConn.isProxySession());
                    
                    do {                    
                        switch(nr) {
                        case 0:
                            if (!conn.getSchema().equalsIgnoreCase(proxyUsername) /*oraConn.isProxySession()*/) {
                                // go back to the session with the first username
                                try {
                                    oraConn.close(OracleConnection.PROXY_SESSION);
                                    
                                    proxyOpenSessionCount++;
                                } catch (SQLException ex) {
                                    log.warn("SQL warning: {}", ex.getMessage());
                                }
                                oraConn.setSchema(proxyUsername);
                            }
                            break;
                            
                        case 1:
                            if (!proxyUsername.equals(schema)) {
                                // open a proxy session with the second username
                                final Properties proxyProperties = new Properties();

                                proxyProperties.setProperty(OracleConnection.PROXY_USER_NAME, schema);
                                oraConn.openProxySession(OracleConnection.PROXYTYPE_USER_NAME, proxyProperties);
                                oraConn.setSchema(schema);
                                
                                proxyCloseSessionCount++;
                            }
                            break;
                            
                        case 2:
                            oraConn.setSchema(schema);
                            break;
                            
                        default:
                            throw new IllegalArgumentException(String.format("Wrong value for nr (%d): must be between 0 and 2", nr));
                        }

                        log.debug("after open proxy session (#{}) - current schema: {}; is proxy session: {}",
                                  nr,
                                  conn.getSchema(),
                                  oraConn.isProxySession());
                    } while (!conn.getSchema().equalsIgnoreCase(schema) && nr++ < 3);
                }
            }

            log.debug("after proxy session - current schema: {}",
                      conn.getSchema());
        } finally {
            while (nrProxyLogicalConnectionCount > 0) {
                try {
                    connectionsWithWrongSchema[--nrProxyLogicalConnectionCount].close();
                } catch (SQLException ex) {
                    log.error("SQL exception on close(): {}", ex);
                }
            }
            log.debug("<getConnection(id={})", getId());
        }
        
        if (statisticsEnabled.get()) {
            if (tm1 == null) {
                poolDataSourceStatistics.updateStatistics(this,
							  conn,
							  Duration.between(tm0, Instant.now()).toMillis(),
							  true);
            } else {
                poolDataSourceStatistics.updateStatistics(this,
							  conn,
							  Duration.between(tm0, tm1).toMillis(),
							  Duration.between(tm1, Instant.now()).toMillis(),
							  true,
							  proxyLogicalConnectionCount,
							  proxyOpenSessionCount,
							  proxyCloseSessionCount);
            }
        }

        return conn;
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
