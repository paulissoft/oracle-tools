package com.paulissoft.pato.jdbc;

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

    private final T poolDataSourceOverflow;

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
     * Open / setUp (javax.annotation.PostConstruct is used by Spring)
     */

    //@jakarta.annotation.PostConstruct
    @javax.annotation.PostConstruct
    public final synchronized void open() {
        log.debug("open(id={})", getId());

        setUp();
    }

    protected void setUp() {
        // minimize accessing volatile variables by shadowing them
        State state = this.state;

        try {
            log.debug(">setUp(id={}, state={})", getId(), state);

            if (state == State.INITIALIZING) {
                try {
                    updatePool(poolDataSource, poolDataSourceOverflow);
                    state = this.state = State.OPEN;
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
     * Close / tearDown (javax.annotation.PreDestroy is used by Spring)
     */

    //@jakarta.annotation.PreDestroy
    @javax.annotation.PreDestroy
    public final synchronized void close() {
        log.debug("close(id={})", getId());

        // why did we get here?
        if (log.isTraceEnabled()) {
            Thread.dumpStack();
        }
        
        tearDown();
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
                state = this.state = State.CLOSED;
                break;
            
            case CLOSED:
                break;
            }
        } finally {
            log.debug("<tearDown(id={}, state={})", getId(), state);
        }
    }

    protected abstract void updatePool(@NonNull final T poolDataSource,
                                       @NonNull final T poolDataSourceOverflow);
    
    protected interface ToOverride {
        public Connection getConnection() throws SQLException;

        public void close();

        public String getId();
        
        public void setId(final String srcId);

        public int getMaxPoolSize(); // must be combined: normal + overflow
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

        final Connection conn =
            poolDataSourceOverflow.getMaxPoolSize() > 0 && poolDataSource.getIdleConnections() == 0 ?
            getConnectionOverflow() :
            poolDataSource.getConnection();

        return conn;
    }

    protected Connection getConnectionOverflow() throws SQLException {
        return poolDataSourceOverflow.getConnection();
    }

    public String getId() {
        return id.toString();
    }
    
    public void setId(final String srcId) {
        SimplePoolDataSource.setId(id, String.format("0x%08x", hashCode()), srcId);
    }

    public final int getMaxPoolSize() {
        if (poolDataSource.getMaxPoolSize() < 0 && poolDataSourceOverflow.getMaxPoolSize() < 0) {
            return poolDataSource.getMaxPoolSize();
        } else {
            return
                (poolDataSource.getMaxPoolSize() > 0 ? poolDataSource.getMaxPoolSize() : 0) +
                (poolDataSourceOverflow.getMaxPoolSize() > 0 ? poolDataSourceOverflow.getMaxPoolSize() : 0);
        }
    }
}
