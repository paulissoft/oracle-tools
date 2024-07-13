package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.function.Supplier;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public abstract class SmartPoolDataSource<T extends SimplePoolDataSource>
    implements SimplePoolDataSource {

    private static class CommonIdRefCountPair {
        public final String commonId;

        public int refCount = 1;

        public CommonIdRefCountPair(final String commonId) {
            this.commonId = commonId;
        }
    }

    // all static related

    // Store all objects of type SimplePoolDataSourceHikari in the hash table.
    // The key is the common id, i.e. the set of common properties
    private static final HashMap<SimplePoolDataSource,CommonIdRefCountPair> lookupSimplePoolDataSource = new HashMap<>(); // null for regression testing

    // object members
    private final StringBuffer id = new StringBuffer();

    private final StringBuffer usernameToConnectTo = new StringBuffer();

    private final StringBuffer schema = new StringBuffer();

    private final T poolDataSource;

    private volatile T poolDataSourceOverflow; // can only be set in open()

    protected enum State {
        INITIALIZING, // next possible states: ERROR, OPEN or CLOSED
        ERROR,        // INITIALIZATING error: next possible states: CLOSED
        OPEN,         // next possible states: CLOSED
        CLOSED
    }

    @NonNull
    private volatile State state = State.INITIALIZING; // changed in a synchronized methods open()/close()

    /*
     * Constructor(s)
     */

    protected SmartPoolDataSource(@NonNull final Supplier<T> supplierT,
                                  @NonNull final PoolDataSourceConfiguration poolDataSourceConfiguration,
                                  final boolean fixed) {
        this.poolDataSource = supplierT.get();
        this.poolDataSourceOverflow = supplierT.get();

        if (!fixed) {
            setId(this.getClass().getSimpleName()); // must invoke setId() after this.poolDataSource is set
        } else {
            set(poolDataSourceConfiguration);
            setId(this.getUsername()); // must invoke setId() after this.poolDataSource is set
            setUp();
            state = State.OPEN;
        }

        assert getPoolDataSource() != null : "The pool data source should not be null.";
    }
    
    /*
     * State
     */
    
    protected State getState() {
        return state;
    }

    public final boolean isOpen() {
        switch(state) {
        case OPEN:
            return true;
        default:
            return false;
        }
    }

    /*
     * Open / setUp
     */

    public final synchronized void open() {
        // minimize accessing volatile variables by shadowing them
        State state = this.state;

        if (state == State.INITIALIZING) {
            log.info("Open initiated");

            try {
                final PoolDataSourceConfiguration poolDataSourceConfigurationBefore = poolDataSource.get();
                
                setUp();

                state = this.state = State.OPEN;
                
                assert hasOverflow() == (poolDataSourceOverflow != null) : "Only when there is an overflow (max pool size > min pool size)" +
                    " the dynamic pool data source should NOT be null.";

                // now getMaxPoolSize() returns the combined totals

                assert poolDataSourceConfigurationBefore.getInitialPoolSize() == getInitialPoolSize() :
                String.format("The new initial pool size (%d) must be the same as before (%d).",
                              getInitialPoolSize(),
                              poolDataSourceConfigurationBefore.getInitialPoolSize());
                assert poolDataSourceConfigurationBefore.getMinPoolSize() == getMinPoolSize() :
                String.format("The new min pool size (%d) must be the same as before (%d).",
                              getMinPoolSize(),
                              poolDataSourceConfigurationBefore.getMinPoolSize());
                if (lookupSimplePoolDataSource == null) {
                    assert poolDataSourceConfigurationBefore.getMaxPoolSize() == getMaxPoolSize() :
                    String.format("The new max pool size (%d) must be the same as before (%d).",
                                  getMaxPoolSize(),
                                  poolDataSourceConfigurationBefore.getMaxPoolSize());
                } else {
                    // pool data sources can be shared hence the new total can be greater
                    assert poolDataSourceConfigurationBefore.getMaxPoolSize() <= getMaxPoolSize() :
                    String.format("The new max pool size (%d) must be at least the same as before (%d).",
                                  getMaxPoolSize(),
                                  poolDataSourceConfigurationBefore.getMaxPoolSize());
                }                    
                assert poolDataSourceConfigurationBefore.getConnectionTimeout() == getConnectionTimeout() :
                String.format("The new connection timeout (%d) must be the same as before (%d).",
                              getConnectionTimeout(),
                              poolDataSourceConfigurationBefore.getConnectionTimeout());
                
                log.info("Open completed ({})", getPoolName());
            } catch (Exception ex) {
                state = this.state = State.ERROR;
                log.info("Open failed ({})", getPoolName());
                throw ex;
            }
        }
    }

    protected void setUp() {
        // minimize accessing volatile variables by shadowing them
        final State state = this.state;
        
        if (state != State.INITIALIZING) {
            return;
        }

        try {
            log.debug(">setUp(id={}, state={})", getId(), state);

            if (!hasOverflow()) {
                poolDataSourceOverflow = null;
            }

            // updatePool must be called before the state is open
            updatePool();
        } finally {
            log.debug("<setUp(id={}, state={})", getId(), state);
        }
    }
         
    /*
     * Close / tearDown
     */

    public final synchronized void close() {
        // minimize accessing volatile variables by shadowing them
        final State state = this.state;
        
        if (state == State.CLOSED) {
            return;
        }
        
        // define it once here otherwise: java.lang.IllegalStateException: You can not use the pool once it is closed.
        final String poolName = getPoolName();
        
        log.info("Close initiated ({})", poolName);

        // why did we get here?
        if (log.isTraceEnabled()) {
            Thread.dumpStack();
        }
        
        tearDown();

        log.info("Close completed ({})", poolName);
    }

    // you may override this one
    // already called in an synchronized context
    protected void tearDown() {
        // minimize accessing volatile variables by shadowing them
        State state = this.state;

        try {
            log.debug(">tearDown(id={}, state={})", getId(), state);

            switch(state) {
            case OPEN:
            case INITIALIZING:
            case ERROR:
                try {
                    poolDataSource.close();

                    if (poolDataSourceOverflow != null) {
                        if (lookupSimplePoolDataSource != null) {
                            synchronized (lookupSimplePoolDataSource) {
                                final SimplePoolDataSource key = poolDataSourceOverflow;
                                final CommonIdRefCountPair value = lookupSimplePoolDataSource.get(key);

                                if (value != null) {
                                    value.refCount--;
                                    if (value.refCount <= 0) {
                                        poolDataSourceOverflow.close();
                                        lookupSimplePoolDataSource.remove(key);
                                    }
                                }
                            }
                        } else {
                            poolDataSourceOverflow.close();
                        }
                    }
                } catch(Exception ex) {
                    log.error("Exception in tearDown():", ex);
                } finally {
                    state = this.state = State.CLOSED;
                }
                break;
            
            case CLOSED:
                break;
            }
        } finally {
            log.debug("<tearDown(id={}, state={})", getId(), state);
        }
    }

    @SuppressWarnings("unchecked")
    protected void updatePool() {
        try {
            log.debug(">updatePool(id={})", getId());

            final PoolDataSourceConfiguration poolDataSourceConfiguration = get();
            final String schema = poolDataSourceConfiguration.getSchema();                
            int maxPoolSize = poolDataSource.getMaxPoolSize();

            this.usernameToConnectTo.delete(0, this.usernameToConnectTo.length());
            this.usernameToConnectTo.append(poolDataSourceConfiguration.getUsernameToConnectTo());
            this.schema.delete(0, this.schema.length());
            this.schema.append(schema);

            // is there an overflow?
            if (poolDataSourceOverflow != null) {
                // determine the maxPoolSizeOverflow before using poolDataSource.setMaxPoolSize()
                int maxPoolSizeOverflow = poolDataSource.getMaxPoolSize() - poolDataSource.getMinPoolSize();

                // settings to let the pool data source fail fast so it can use the overflow
                maxPoolSize = poolDataSource.getMinPoolSize();
                poolDataSource.setConnectionTimeout(getMinConnectionTimeout());

                // First try to get a poolDataSourceOverflow from the lookup: sharing is better!
                // Now username will be the username to connect to, so bc_proxy[bodomain] may become bc_proxy
                final PoolDataSourceConfigurationCommonId poolDataSourceConfigurationCommonId =
                    new PoolDataSourceConfigurationCommonId(poolDataSourceConfiguration);
                final String commonId = poolDataSourceConfigurationCommonId.toString();
                T pds = null;

                log.debug("commonId: {}", commonId);
                
                // synchronize access to lookupSimplePoolDataSource and do it fast
                if (lookupSimplePoolDataSource != null) {
                    synchronized (lookupSimplePoolDataSource) {
                        for (var entry: lookupSimplePoolDataSource.entrySet()) {
                            final SimplePoolDataSource key = entry.getKey();
                            final CommonIdRefCountPair value = entry.getValue();

                            if (value.commonId.equals(commonId) && key.isInitializing()) {
                                pds = (T) key;
                                value.refCount++;
                                log.debug("found shared pool with new refCount {}", value.refCount);
                                break;
                            } else {
                                log.debug("this shared pool does not match; key.isInitializing(): {}; value.refCount: {}; value.commonId: {}",
                                          key.isInitializing(),
                                          value.refCount,
                                          value.commonId);
                            }
                        }

                        if (pds == null) {
                            // we have already a new poolDataSourceOverflow and that will become the shared one
                            lookupSimplePoolDataSource.put(poolDataSourceOverflow, new CommonIdRefCountPair(commonId));
                        } else {
                            // must update pool name and sizes, that's all
                            poolDataSourceOverflow = pds;
                        }
                    }
                }

                if (pds == null) {
                    // copy values from the fixed pool
                    poolDataSourceOverflow.set(poolDataSourceConfiguration); 
                    // need to set password explicitly since combination get()/set() does not set it
                    poolDataSourceOverflow.setPassword(poolDataSource.getPassword());

                    // settings to keep the dynamic/overflow pool data source as empty as possible
                    poolDataSourceOverflow.setInitialPoolSize(0);                
                    poolDataSourceOverflow.setMinPoolSize(0);
                    poolDataSourceOverflow.setConnectionTimeout(poolDataSourceOverflow.getConnectionTimeout() - getMinConnectionTimeout());

                    if (lookupSimplePoolDataSource != null) {
                        final String proxyUsername = poolDataSourceConfiguration.getProxyUsername();

                        if (proxyUsername != null) {
                            poolDataSourceOverflow.setUsername(proxyUsername);
                        }
                    }
                } else {
                    // add the new maxPoolSizeOverflow
                    maxPoolSizeOverflow += poolDataSourceOverflow.getMaxPoolSize();
                }

                updatePool(poolDataSourceOverflow, " (dynamic)", pds == null, schema, maxPoolSizeOverflow);
            } // if (poolDataSourceOverflow != null) {

            updatePool(poolDataSource, " (fixed)", true, schema, maxPoolSize);
        } catch (SQLException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        } finally {
            log.debug("<updatePool(id={})", getId());
        }
    }

    private void updatePool(final T poolDataSource,
                            final String suffix,
                            final boolean isFirstPoolDataSource,
                            final String schema,
                            final int maxPoolSize) throws SQLException {
        try {
            log.debug(">updatePool(id={}, suffix={}, isFirstPoolDataSource={}, schema={}, maxPoolSize={})",
                      getId(),
                      suffix,
                      isFirstPoolDataSource,
                      schema,
                      maxPoolSize);

            final String oldPoolName = poolDataSource.getPoolName();
            String oldPoolNameWithoutSuffix;

            // strip suffix
            if (oldPoolName != null && !suffix.isEmpty() && oldPoolName.endsWith(suffix)) {
                oldPoolNameWithoutSuffix = oldPoolName.substring(0, oldPoolName.length() - suffix.length());
            } else {
                oldPoolNameWithoutSuffix = oldPoolName;
            }
            
            final ArrayList<String> items =
                isFirstPoolDataSource ?
                new ArrayList<>() :
                new ArrayList<>(Arrays.asList(oldPoolNameWithoutSuffix.split("-")));

            log.debug("items: {}; schema: {}", items, schema);

            if (isFirstPoolDataSource) {
                items.clear(); // not really necessary...
                items.add(poolDataSource.getPoolNamePrefix());
                items.add(schema);
            } else if (!items.contains(schema)) {
                items.add(schema);
            }
        
            if (items.size() >= 2) {
                poolDataSource.setPoolName(String.join("-", items));
            }
            
            // use a different name for the overflow to solve UCP-0
            poolDataSource.setPoolName(poolDataSource.getPoolName() + suffix);
            log.debug("pool name{}: {} => {}", suffix, oldPoolName, poolDataSource.getPoolName());

            final int oldMaxPoolSize = poolDataSource.getMaxPoolSize();
            
            poolDataSource.setMaxPoolSize(maxPoolSize);
            log.debug("maximum pool size{}: {} => {}", suffix, oldMaxPoolSize, poolDataSource.getMaxPoolSize());
        } finally {
            log.debug("<updatePool(id={})", getId());
        }
    }

    protected interface ToOverride {
        public Connection getConnection() throws SQLException;

        public void close();

        public String getId();
        
        public void setId(final String srcId);

        public PoolDataSourceConfiguration get(); // must be combined: normal + overflow
        
        public int getMaxPoolSize(); // idem

        public long getConnectionTimeout(); // idem
        
        public int getActiveConnections(); // idem

        public int getIdleConnections(); // idem

        public int getTotalConnections(); // idem
    }

    // @Delegate(types=<T>.class, excludes={ PoolDataSourcePropertiesSetters<T>.class, PoolDataSourcePropertiesGetters<T>.class, ToOverride.class })
    protected T getPoolDataSource() {
        switch (state) {
        case CLOSED:
            throw new IllegalStateException("You can not use the pool once it is closed.");
        default:
            return poolDataSource;
        }
    }

    protected final T getPoolDataSourceOverflow() {
        switch (state) {
        case CLOSED:
            throw new IllegalStateException("You can not use the pool once it is closed.");
        default:
            return poolDataSourceOverflow;
        }
    }

    /*
     * Connection
     */

    @SuppressWarnings("fallthrough")
    public final Connection getConnection() throws SQLException {
        log.trace(">getConnection()");

        boolean useOverflow = false;

        try {
            switch (state) {
            case INITIALIZING:
                open(); // will change state to OPEN
                assert state == State.OPEN : "After the pool data source is opened explicitly the state must be OPEN: " +
                    "did you override setUp() correctly by invoking super.setUp()?";
                // For the first connection use the overflow so both pools are initialized after the first two connections.
                // GJP 2024-06-21 Not now since Oracle raises UCP-0
                /*
                if (hasOverflow()) {
                    useOverflow = true; 
                }
                */
                /* FALLTHROUGH */
            case OPEN:
                break;
            default:
                throw new IllegalStateException(String.format("You can only get a connection when the pool state is OPEN but it is %s.",
                                                              state.toString()));
            }

            // minimize accessing volatile variables by shadowing them
            final T poolDataSourceOverflow = this.poolDataSourceOverflow;
            
            Connection conn;

            // Try to avoid connection timeout errors.
            // When the fixed pool data source is full with idle connections,
            // use immediately the dynamic pool (and try the fixed one later on).
            if (poolDataSourceOverflow != null &&
                poolDataSource.getIdleConnections() == 0 &&
                poolDataSource.getTotalConnections() == poolDataSource.getMaxPoolSize()) {
                useOverflow = true;
            }
            
            try {
                conn = getConnection(useOverflow, poolDataSource, poolDataSourceOverflow);
            } catch (Exception ex) {
                // switch pools (just once) when the connection fails due to no idle connections 
                if ((useOverflow || poolDataSourceOverflow != null) &&
                    getConnectionFailsDueToNoIdleConnections(ex)) {
                    conn = getConnection(!useOverflow, poolDataSource, poolDataSourceOverflow);
                } else {
                    throw ex;
                }
            }

            return conn;
        } finally {
            log.trace("<getConnection()");
        }
    }

    protected Connection getConnection(final boolean useOverflow,
                                       final T poolDataSource,
                                       final T poolDataSourceOverflow) throws SQLException {
        log.trace(">getConnection({}, ...)", useOverflow);

        try {
            if (!useOverflow) {
                return poolDataSource.getConnection();
            } else if (lookupSimplePoolDataSource != null) {
                return poolDataSourceOverflow.getConnection(usernameToConnectTo.toString(),
                                                            getPassword(),
                                                            schema.toString(),
                                                            ( lookupSimplePoolDataSource != null ?
                                                              lookupSimplePoolDataSource.get(poolDataSourceOverflow).refCount :
                                                              1 ));
            } else {
                return poolDataSourceOverflow.getConnection();
            }
        } finally {
            log.trace("<getConnection({}, ...)", useOverflow);
        }
    }

    protected abstract boolean getConnectionFailsDueToNoIdleConnections(final Exception ex);

    public final String getId() {
        return id.toString();
    }
    
    public final void setId(final String srcId) {
        SimplePoolDataSource.setId(id, String.format("0x%08x", hashCode()), srcId);
    }

    public final int getMaxPoolSize() {
        final int maxPoolSize = poolDataSource.getMaxPoolSize();
        T poolDataSourceOverflow; // to speed up access to volatile attribute
        
        if (state == State.INITIALIZING || (poolDataSourceOverflow = this.poolDataSourceOverflow) == null) {
            return maxPoolSize;
        }

        final int maxPoolSizeOverflow = poolDataSourceOverflow.getMaxPoolSize();
            
        if (maxPoolSize < 0 && maxPoolSizeOverflow < 0) {
            return maxPoolSize;
        } else {
            return Integer.max(maxPoolSize, 0) + Integer.max(maxPoolSizeOverflow, 0);
        }
    }

    public final long getConnectionTimeout() {
        final long connectionTimeout = poolDataSource.getConnectionTimeout();
        T poolDataSourceOverflow;

        if (state == State.INITIALIZING || (poolDataSourceOverflow = this.poolDataSourceOverflow) == null) {            
            return connectionTimeout;
        }

        final long connectionTimeoutOverflow = poolDataSourceOverflow.getConnectionTimeout();

        if (connectionTimeout < 0L && connectionTimeoutOverflow < 0L) {
            return connectionTimeout;
        } else {
            return Long.max(connectionTimeout, 0L) + Long.max(connectionTimeoutOverflow, 0L);
        }
    }
    
    // connection statistics    
    public final int getActiveConnections() {
        T poolDataSourceOverflow; // to speed up access to volatile attribute
        final int activeConnections = poolDataSource.getActiveConnections();

        if (state == State.INITIALIZING || (poolDataSourceOverflow = this.poolDataSourceOverflow) == null) {
            return activeConnections;
        }

        final int activeConnectionsOverflow = poolDataSourceOverflow.getActiveConnections();
        
        if (activeConnections < 0 && activeConnectionsOverflow < 0) {
            return activeConnections;
        } else {
            return Integer.max(activeConnections, 0) + Integer.max(activeConnectionsOverflow, 0);
        }
    }

    public final int getIdleConnections() {
        T poolDataSourceOverflow; // to speed up access to volatile attribute
        final int idleConnections = poolDataSource.getIdleConnections();

        if (state == State.INITIALIZING || (poolDataSourceOverflow = this.poolDataSourceOverflow) == null) {
            return idleConnections;
        }

        final int idleConnectionsOverflow = poolDataSourceOverflow.getIdleConnections();

        if (idleConnections < 0 && idleConnectionsOverflow < 0) {
            return idleConnections;
        } else {
            return Integer.max(idleConnections, 0) + Integer.max(idleConnectionsOverflow, 0);
        }
    }

    public final int getTotalConnections() {
        T poolDataSourceOverflow; // to speed up access to volatile attribute
        final int totalConnections = poolDataSource.getTotalConnections();

        if (state == State.INITIALIZING || (poolDataSourceOverflow = this.poolDataSourceOverflow) == null) {
            return totalConnections;
        }

        final int totalConnectionsOverflow = poolDataSourceOverflow.getTotalConnections();

        if (totalConnections < 0 && totalConnectionsOverflow < 0) {
            return totalConnections;
        } else {
            return Integer.max(totalConnections, 0) + Integer.max(totalConnectionsOverflow, 0);
        }
    }

    public final boolean hasOverflow() {
        switch (state) {
        case INITIALIZING:
            return poolDataSource.getMaxPoolSize() > poolDataSource.getMinPoolSize();
        default:
            return poolDataSourceOverflow != null;
        }
    }
}
