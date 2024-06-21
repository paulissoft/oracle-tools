package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Supplier;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public abstract class SmartPoolDataSource<T extends SimplePoolDataSource>
    implements SimplePoolDataSource {

    private final StringBuffer id = new StringBuffer();

    private final T poolDataSource;

    final Supplier<T> supplierT; // needed to set poolDataSourceOverflow later on
        
    private volatile T poolDataSourceOverflow; // can only be set in open()

    protected enum State {
        INITIALIZING, // next possible states: ERROR, OPEN or CLOSED
        ERROR,        // INITIALIZATING error: next possible states: CLOSED
        OPEN,         // next possible states: CLOSED
        CLOSED
    }

    @NonNull
    private volatile State state = State.INITIALIZING; // changed in a synchronized methods open()/close()

    // for both the pool data source and its overflow
    private final AtomicBoolean[] hasShownConfig = new AtomicBoolean[] { new AtomicBoolean(false), new AtomicBoolean(false) };

    /*
     * Constructor(s)
     */

    protected SmartPoolDataSource(@NonNull final Supplier<T> supplierT) {
        this(supplierT, null);
    }

    protected SmartPoolDataSource(@NonNull final Supplier<T> supplierT, final PoolDataSourceConfiguration poolDataSourceConfiguration) {
        this.supplierT = supplierT;
        this.poolDataSource = supplierT.get();
        this.poolDataSourceOverflow = null;

        if (poolDataSourceConfiguration == null) {
            setId(this.getClass().getSimpleName()); // must invoke setId() after this.poolDataSource is set
        } else {
            set(poolDataSourceConfiguration);        
            setId(this.getUsername()); // must invoke setId() after this.poolDataSource is set
            setUp();
            state = State.OPEN;
        }

        assert getPoolDataSource() != null : "The pool data source should not be null.";
    }
    
    protected static PoolDataSourceStatistics determinePoolDataSourceStatistics(final SimplePoolDataSource pds,
                                                                                final PoolDataSourceStatistics parentPoolDataSourceStatistics) {
        log.debug(">determinePoolDataSourceStatistics(parentPoolDataSourceStatistics == null: {})", parentPoolDataSourceStatistics == null);

        try {
            if (parentPoolDataSourceStatistics == null) {
                return null;
            } else {
                return new PoolDataSourceStatistics(null,
                                                    parentPoolDataSourceStatistics, 
                                                    pds::isClosed,
                                                    pds::getWithPoolName);
            }
        } finally {
            log.debug("<determinePoolDataSourceStatistics");
        }
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
                final PoolDataSourceConfiguration pdsConfig = poolDataSource.get();
                    
                setUp();

                state = this.state = State.OPEN;
                
                assert hasOverflow() == (poolDataSourceOverflow != null) : "Only when there is an overflow (max pool size > min pool size)" +
                    " the dynamic pool data source should NOT be null.";

                // now getMaxPoolSize() returns the combined totals
                    
                assert pdsConfig.getInitialPoolSize() == getInitialPoolSize() :
                String.format("The new initial pool size (%d) must be the same as before (%d).",
                              getInitialPoolSize(),
                              pdsConfig.getInitialPoolSize());
                assert pdsConfig.getMinPoolSize() == getMinPoolSize() :
                String.format("The new min pool size (%d) must be the same as before (%d).",
                              getMinPoolSize(),
                              pdsConfig.getMinPoolSize());
                assert pdsConfig.getMaxPoolSize() == getMaxPoolSize() :
                String.format("The new max pool size (%d) must be the same as before (%d).",
                              getMaxPoolSize(),
                              pdsConfig.getMaxPoolSize());
                assert pdsConfig.getConnectionTimeout() == getConnectionTimeout() :
                String.format("The new connection timeout (%d) must be the same as before (%d).",
                              getConnectionTimeout(),
                              pdsConfig.getConnectionTimeout());

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

            if (hasOverflow()) {
                poolDataSourceOverflow = supplierT.get();
            }

            // updatePool must be called before the state is open
            updatePool(poolDataSource, poolDataSourceOverflow);
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
                    if (getPoolDataSourceStatistics() != null) {
                        log.info("About to close pool statistics.");
                        getPoolDataSourceStatistics().close();
                    } else {
                        log.info("There are no pool statistics.");
                    }
                    if (getPoolDataSourceStatisticsOverflow() != null) {
                        log.info("About to close dynamic pool statistics.");
                        getPoolDataSourceStatisticsOverflow().close();
                    } else {
                        log.info("There are no dynamic pool statistics.");
                    }

                    poolDataSource.close();
                    if (poolDataSourceOverflow != null) {
                        poolDataSourceOverflow.close();
                    }
                } catch(Exception ex) {
                    log.error("Exception on tearDown(): {}", ex);
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

    protected abstract PoolDataSourceStatistics getPoolDataSourceStatistics();

    protected abstract PoolDataSourceStatistics getPoolDataSourceStatisticsOverflow();

    protected abstract long getMinConnectionTimeout();
    
    protected void updatePool(@NonNull final T poolDataSource,
                              final T poolDataSourceOverflow) {
        try {
            final PoolDataSourceConfiguration pdsConfig = poolDataSource.get();
            
            // is there an overflow?
            if (poolDataSourceOverflow != null) {
                final int maxPoolSizeOverflow = poolDataSource.getMaxPoolSize() - poolDataSource.getMinPoolSize();

                // copy values
                poolDataSourceOverflow.set(pdsConfig); 
                // need to set password explicitly since combination get()/set() does not set it
                poolDataSourceOverflow.setPassword(poolDataSource.getPassword());
                // need to set pool name explicitly since combination get()/set() does not set it
                poolDataSourceOverflow.setPoolName(poolDataSource.getPoolName());

                // settings to let the pool data source fail fast so it can use the overflow
                poolDataSource.setMaxPoolSize(pdsConfig.getMinPoolSize());
                poolDataSource.setConnectionTimeout(getMinConnectionTimeout());

                // settings to keep the dynamic/overflow pool data source as empty as possible
                poolDataSourceOverflow.setInitialPoolSize(0);                
                poolDataSourceOverflow.setMinPoolSize(0);
                poolDataSourceOverflow.setMaxPoolSize(maxPoolSizeOverflow);
                poolDataSourceOverflow.setConnectionTimeout(poolDataSourceOverflow.getConnectionTimeout() - getMinConnectionTimeout());
            }        

            // set pool name
            if (pdsConfig.getPoolName() == null || pdsConfig.getPoolName().isEmpty()) {
                poolDataSource.setPoolName(poolDataSource.getClass().getSimpleName() + "-" + pdsConfig.getSchema());
            }
            // use a different name for the overflow to solve UCP-0
            if (poolDataSourceOverflow != null) {
                poolDataSourceOverflow.setPoolName(poolDataSourceOverflow.getPoolName() + " (dynamic)");
            }
        } catch (SQLException ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
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
    
    public final Connection getConnection() throws SQLException {
        log.trace(">getConnection()");

        final boolean useOverflow = false;

        try {
            switch (state) {
            case INITIALIZING:
                open(); // will change state to OPEN
                assert state == State.OPEN : "After the pool data source is opened explicitly the state must be OPEN: " +
                    "did you override setUp() correctly by invoking super.setUp()?";
                // For the first connection use the overflow so both pools are initialized after the first two connections.
                // GJP 2024-06-21 Not now
                /*
                if (hasOverflow()) {
                    useOverflow = true; 
                }
                */
                // fall through
            case OPEN:
                break;
            default:
                throw new IllegalStateException(String.format("You can only get a connection when the pool state is OPEN but it is %s.",
                                                              state.toString()));
            }

            Connection conn;

            try {
                conn = getConnection(useOverflow);
            } catch (Exception ex) {
                // switch pools (just once) when the connection fails due to no idle connections 
                if ((useOverflow || hasOverflow()) && getConnectionFailsDueToNoIdleConnections(ex)) { 
                    conn = getConnection(!useOverflow);
                } else {
                    throw ex;
                }
            }

            return conn;
        } finally {
            log.trace("<getConnection()");
        }
    }

    protected Connection getConnection(final boolean useOverflow) throws SQLException {
        log.trace(">getConnection({})", useOverflow);

        final T pds = useOverflow ? getPoolDataSourceOverflow() : getPoolDataSource();
        final PoolDataSourceStatistics pdsStatistics = useOverflow ? getPoolDataSourceStatisticsOverflow() : getPoolDataSourceStatistics();

        try {
            return getConnection(pds, pdsStatistics, hasShownConfig[useOverflow ? 1 : 0]);
        } finally {
            log.trace("<getConnection({})", useOverflow);
        }
    }

    private static Connection getConnection(final SimplePoolDataSource pds,
                                            final PoolDataSourceStatistics poolDataSourceStatistics,
                                            final AtomicBoolean hasShownConfig) throws SQLException {
        Connection conn = null;

        if (poolDataSourceStatistics != null && SimplePoolDataSource.isStatisticsEnabled()) {
            final Instant tm = Instant.now();
            
            try {
                conn = pds.getConnection();
            } catch (SQLException se) {
                poolDataSourceStatistics.signalSQLException(pds, se);
                throw se;
            } catch (Exception ex) {
                poolDataSourceStatistics.signalException(pds, ex);
                throw ex;
            }

            poolDataSourceStatistics.updateStatistics(pds,
                                                      conn,
                                                      Duration.between(tm, Instant.now()).toMillis(),
                                                      true);
        } else {
            conn = pds.getConnection();
        }

        if (!hasShownConfig.getAndSet(true)) {
            // Only show the first time a pool has gotten a connection.
            // Not earlier because these (fixed) values may change before and after the first connection.
            pds.show(pds.get());
        }

        return conn;
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
