package com.paulissoft.pato.jdbc;

//import java.time.Duration;
//import java.time.Instant;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.function.Supplier;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public abstract class OverflowPoolDataSource<T extends SimplePoolDataSource>
    implements SimplePoolDataSource {

    private final StringBuffer id = new StringBuffer();

    private final T poolDataSource;

    private volatile T poolDataSourceOverflow;

    protected enum State {
        INITIALIZING, // next possible states: ERROR, OPEN or CLOSED
        ERROR,        // INITIALIZATING error: next possible states: CLOSED
        OPEN,         // next possible states: CLOSED
        CLOSED
    }

    @NonNull
    private volatile State state = State.INITIALIZING; // changed in a synchronized methods open()/close()

    /*
     * Constructor
     */

    protected OverflowPoolDataSource(@NonNull final Supplier<T> supplierT) {
        this.poolDataSource = supplierT.get();
        this.poolDataSourceOverflow = supplierT.get();
        
        setId(this.getClass().getSimpleName()); // must invoke setId() after this.poolDataSource is set
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
        log.info("Open initiated");

        setUp();
        assert hasOverflow() == (poolDataSourceOverflow != null) : "Only when there is an overflow (max pool size > min pool size)" +
            " the overflow pool data source should NOT be null.";

        log.info("Open completed ({})", getPoolName());
    }

    protected void setUp() {
        // minimize accessing volatile variables by shadowing them
        State state = this.state;

        try {
            log.debug(">setUp(id={}, state={})", getId(), state);

            if (state == State.INITIALIZING) {
                try {
                    if (!hasOverflow()) {
                        poolDataSourceOverflow = null;
                    }

                    final PoolDataSourceConfiguration pdsConfig = poolDataSource.get();

                    // updatePool must be called before the state is open
                    updatePool(pdsConfig, poolDataSource, poolDataSourceOverflow);
                    
                    state = this.state = State.OPEN;

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
                } catch (Exception ex) {
                    state = this.state = State.ERROR;
                    throw ex;
                }
            }
        } finally {
            log.debug("<setUp(id={}, state={})", getId(), state);
        }
    }

    /*
     * Close / tearDown
     */

    public final synchronized void close() {
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
    protected void tearDown(){
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

    protected abstract long getMinConnectionTimeout();
    
    protected void updatePool(@NonNull final PoolDataSourceConfiguration pdsConfig,
                              @NonNull final T poolDataSource,
                              final T poolDataSourceOverflow) {
        try {
            // is there an overflow?
            if (poolDataSourceOverflow != null) {
                final int maxPoolSizeOverflow = poolDataSource.getMaxPoolSize() - poolDataSource.getMinPoolSize();

                // copy values
                poolDataSourceOverflow.set(pdsConfig); 
                // need to set password explicitly since combination get()/set() does not set the password
                poolDataSourceOverflow.setPassword(poolDataSource.getPassword());

                // settings to let the pool data source fail fast so it can use the overflow
                poolDataSource.setMaxPoolSize(pdsConfig.getMinPoolSize());
                poolDataSource.setConnectionTimeout(getMinConnectionTimeout());

                // settings to keep the overflow pool data source as empty as possible
                poolDataSourceOverflow.setInitialPoolSize(0);                
                poolDataSourceOverflow.setMinPoolSize(0);
                poolDataSourceOverflow.setMaxPoolSize(maxPoolSizeOverflow);
                poolDataSourceOverflow.setConnectionTimeout(poolDataSourceOverflow.getConnectionTimeout() - getMinConnectionTimeout());
            }        

            // set pool name
            if (pdsConfig.getPoolName() == null || pdsConfig.getPoolName().isEmpty()) {
                pdsConfig.determineConnectInfo();
                poolDataSource.setPoolName(getClass().getSimpleName() + "-" + pdsConfig.getSchema());
                // use a different name to solve UCP-0
                if (poolDataSourceOverflow != null) {
                    poolDataSourceOverflow.setPoolName(poolDataSourceOverflow.getClass().getSimpleName() + "-" + pdsConfig.getSchema());
                }
            }
            if (poolDataSourceOverflow != null) {
                poolDataSourceOverflow.setPoolName(poolDataSourceOverflow.getPoolName() + "-overflow");
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

        public int getMaxPoolSize(); // must be combined: normal + overflow

        public long getConnectionTimeout(); // idem
        
        public int getActiveConnections();

        public int getIdleConnections();

        public int getTotalConnections();        
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
        // final Instant t1 = Instant.now();
        
        log.trace(">getConnection()");        

        try {
            switch (state) {
            case INITIALIZING:
                open(); // will change state to OPEN
                assert state == State.OPEN : "After the pool data source is opened explicitly the state must be OPEN: " +
                    "did you override setUp() correctly by invoking super.setUp()?";
                // fall through
            case OPEN:
                break;
            default:
                throw new IllegalStateException(String.format("You can only get a connection when the pool state is OPEN but it is %s.",
                                                              state.toString()));
            }

            Connection conn;

            try {
                conn = getConnection(false);
            } catch (SQLException se) {
                if (hasOverflow()) {
                    conn = getConnection(true);
                } else {
                    throw se;
                }
            }

            return conn;
        } finally {
            // final Instant t2 = Instant.now();

            // log.debug("elapsed (ms): {}", Duration.between(t1, t2).toMillis());
            log.trace("<getConnection()");
        }
    }

    protected Connection getConnection(final boolean useOverflow) throws SQLException {
        log.trace(">getConnection({})", useOverflow);

        final T pds = useOverflow ? poolDataSourceOverflow : poolDataSource;

        try {
            return pds.getConnection();
        } catch (Exception ex) {
            throw ex;
        } finally {
            log.trace("<getConnection({})", useOverflow);
        }
    }

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
        return getMaxPoolSize() > getMinPoolSize();
    }
}
