package com.paulissoft.pato.jdbc;

import java.io.Closeable;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.util.Properties;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Supplier;
import javax.sql.DataSource;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;
import oracle.jdbc.OracleConnection;

@Slf4j
public abstract class CombiPoolDataSource<T extends SimplePoolDataSource, P extends PoolDataSourceConfiguration>
    implements SimplePoolDataSource, Closeable {

    // We need to know the active parents in order to assign a value to an active parent so that a data source can use a common data source.
    // Syntax error on: private static final ConcurrentHashMap<PoolDataSourceConfigurationCommonId, CombiPoolDataSource<T, P>>,
    // so use DataSource instead of T.
    private static final ConcurrentHashMap<PoolDataSourceConfigurationCommonId, DataSource> activeParents = new ConcurrentHashMap<>();

    static void clear() {
        activeParents.clear();
    }    

    private final StringBuffer id = new StringBuffer();

    @Getter(AccessLevel.PACKAGE)
    @NonNull
    private final P poolDataSourceConfiguration;

    /* either poolDataSource or activeParent is null */
    
    private final T poolDataSource;

    @Getter(AccessLevel.PACKAGE)
    private final CombiPoolDataSource<T, P> activeParent;

    @NonNull
    private final AtomicInteger activeChildren = new AtomicInteger(0); // safe in threads

    protected enum State {
        INITIALIZING, // next possible states: ERROR, OPEN or CLOSED
        ERROR,        // INITIALIZATING error: next possible states: CLOSED
        OPEN,         // next possible states: CLOSING (a parent that has active children) or CLOSED (otherwise)
        CLOSING,      // can not close yet since there are active children: next possible states: CLOSED
        CLOSED
    }

    @NonNull
    private volatile State state = State.INITIALIZING; // changed in a synchronized methods open()/close()

    /*
     * Constructors
     */

    /* 1: everything null, INITIALIZING */
    protected CombiPoolDataSource(@NonNull final T poolDataSource,
                                  @NonNull final P poolDataSourceConfiguration) {
        log.debug("constructor 1: everything null, INITIALIZING");
        
        this.poolDataSourceConfiguration = poolDataSourceConfiguration;
        this.poolDataSource = poolDataSource;
        this.activeParent = null;
        
        setId(this.poolDataSourceConfiguration.getUsername()); // must invoke setId() after this.poolDataSource is set

        log.debug("id: {}; active parent id: null; pool data source: {}",
                  getId(),
                  getPoolDataSource());

        assert getPoolDataSource() != null : "The pool data source should not be null.";
    }

    /* 2: poolDataSourceConfiguration != null (fixed), OPEN */
    protected CombiPoolDataSource(@NonNull final Supplier<T> supplierT,
                                  @NonNull final P poolDataSourceConfiguration) {
        log.debug("constructor 2: poolDataSourceConfiguration != null (fixed), OPEN");

        this.poolDataSourceConfiguration = poolDataSourceConfiguration;
        this.activeParent = determineActiveParent(); // can not use getId() yet
        this.poolDataSource = this.activeParent == null ? supplierT.get() : null;

        setId(this.poolDataSourceConfiguration.getUsername()); // must invoke setId() after this.poolDataSource is set
        setUp();

        log.debug("id: {}; active parent id: {}; pool data source: {}",
                  getId(),
                  this.activeParent != null ? this.activeParent.getId() : null,
                  getPoolDataSource());

        assert state == State.OPEN : "After setting up the state must be OPEN.";
        assert getPoolDataSource() != null : "The pool data source should not be null.";
    }

    /* 3: activeParent != null, INITIALIZING */
    protected CombiPoolDataSource(@NonNull final P poolDataSourceConfiguration,
                                  @NonNull final CombiPoolDataSource<T, P> activeParent) {
        log.debug("constructor 3: activeParent != null, INITIALIZING");

        this.poolDataSourceConfiguration = poolDataSourceConfiguration;
        this.poolDataSource = null;
        this.activeParent = activeParent;

        setId(this.poolDataSourceConfiguration.getUsername()); // must invoke setId() after this.poolDataSource is set

        log.debug("id: {}; active parent id: {}; pool data source: {}",
                  getId(),
                  this.activeParent.getId(),
                  getPoolDataSource());

        assert activeParent.activeParent == null : "A parent can not have a parent itself.";
        assert activeParent.state == State.OPEN : "A parent status must be OPEN.";
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
        case CLOSING:
            return true;
        default:
            return false;
        }
    }

    /*
     * Open / setUp
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
                    poolDataSourceConfiguration.determineConnectInfo();
                    setId(poolDataSourceConfiguration.getSchema());
                    updateCombiPoolAdministration();
                    updatePool(poolDataSourceConfiguration, getPoolDataSource(), true, activeParent == null);
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

    public final boolean isParentPoolDataSource() {
        return activeParent == null;
    }
        
    private CombiPoolDataSource<T, P> determineActiveParent() {
        // can not use getId()
        log.debug(">determineActiveParent()");
        
        // Since the configuration is fixed now we can do lookups for an active parent.
        // The first pool data source (for same properties) will have activeParent == null
        final PoolDataSourceConfigurationCommonId commonId =
            new PoolDataSourceConfigurationCommonId(poolDataSourceConfiguration);

        log.debug("commonId: {}", commonId);
        
        @SuppressWarnings("unchecked")
        CombiPoolDataSource<T, P> activeParent = (CombiPoolDataSource<T, P>) activeParents.get(commonId); 

        if (activeParent != null && activeParent.state != State.OPEN) {
            activeParent = null;
        }

        log.debug("activeParent: {}", activeParent);

        log.debug("<determineActiveParent() = {}", activeParent);

        return activeParent;
    }

    private void updateCombiPoolAdministration() {
        log.debug(">updateCombiPoolAdministration(id={})", getId());
        
        final PoolDataSourceConfigurationCommonId commonId =
            new PoolDataSourceConfigurationCommonId(poolDataSourceConfiguration);

        log.debug("commonId: {}", commonId);

        switch (state) {
        case INITIALIZING:
            if (activeParent == null) {
                // The next with the same properties will get this one as activeParent
                activeParents.computeIfAbsent(commonId, k -> this);
                // only copy when there is no active parent
                poolDataSource.set(poolDataSourceConfiguration);

                log.debug("(parent) copied configuration to the pool data source: {}", poolDataSource);
            } else {
                final PoolDataSourceConfigurationCommonId parentCommonId =
                    new PoolDataSourceConfigurationCommonId(activeParent.poolDataSourceConfiguration);

                log.debug("parentCommonId: {}", parentCommonId);

                if (!parentCommonId.equals(commonId)) {
                    throw new IllegalArgumentException(String.format("The parent and this common configuration should be the same.\nParent: %s\nCommon: %s",
                                                                     parentCommonId,
                                                                     commonId));
                }
                
                activeParent.activeChildren.incrementAndGet();
                
                log.debug("(child) # active children for this parent: {}", activeParent.activeChildren.get());
            }
            break;
            
        case OPEN:
            if (activeParent != null) {
                if (activeParent.activeChildren.decrementAndGet() == 0 && activeParent.state == State.CLOSING) {
                    log.info("Trying to close the parent again since there are no more active children and the parent state is CLOSING.");
                    activeParent.close(); // try to close() again
                }

                log.debug("(child) # active children for this parent: {}", activeParent.activeChildren.get());
            }
            // fall thru        
        default:
            if (activeParent == null) {
                // remove the active parent (if any)
                activeParents.remove(commonId);

                log.debug("(parent) removed default parent");
            }            
            break;
        }

        log.debug("<updateCombiPoolAdministration(id={})", getId());
    }

    /*
     * Close / tearDown
     */

    //@jakarta.annotation.PreDestroy
    @javax.annotation.PreDestroy
    public final synchronized void close() {
        log.debug("close(id={})", getId());

        // why did we get here?
        if (log.isDebugEnabled()) {
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
            case CLOSING:
                if (activeParent == null && activeChildren.get() != 0) {
                    // parent having active children can not get CLOSED now but mark it as CLOSING (or keep it like that)
                    if (state != State.CLOSING) {
                        log.info("Can not close this parent since there are active children ({}), hence setting its state to CLOSING.",
                                 activeChildren.get());
                        state = this.state = State.CLOSING;
                    }
                    break;
                }
                // fall thru
            case INITIALIZING: /* can not have active children since an INITIALIZING parent can never be assigned to activeParent */
            case ERROR:
                updateCombiPoolAdministration();
                updatePool(poolDataSourceConfiguration, getPoolDataSource(), false, activeParent == null);
                state = this.state = State.CLOSED;
                break;
            
            case CLOSED:
                break;
            }
        } finally {
            log.debug("<tearDown(id={}, state={})", getId(), state);
        }
    }

    protected void updatePoolName(@NonNull final P poolDataSourceConfiguration,
                                  @NonNull final T poolDataSource,
                                  final boolean initializing,
                                  final boolean isParentPoolDataSource) {
        throw new UnsupportedOperationException("Operation updatePoolName() not implemented.");
    }

    protected void updatePoolSizes(@NonNull final P poolDataSourceConfiguration,
                                   @NonNull final T poolDataSource,
                                   final boolean initializing) {
        throw new UnsupportedOperationException("Operation updatePoolSizes() not implemented.");
    }

    protected void updatePool(@NonNull final P poolDataSourceConfiguration,
                              @NonNull final T poolDataSource,
                              final boolean initializing,
                              final boolean isParentPoolDataSource) {
        log.debug(">updatePool(id={}, initializing={}, isParentPoolDataSource={})",
                  getId(),
                  initializing,
                  isParentPoolDataSource);
        try {
            updatePoolName(poolDataSourceConfiguration,
                           poolDataSource,
                           initializing,
                           isParentPoolDataSource);
            if (!isParentPoolDataSource) { // do not double the pool size when it is an active parent
                updatePoolSizes(poolDataSourceConfiguration,
                                poolDataSource,
                                initializing);
            }
        } finally {
            log.debug("<updatePool(id={})", getId());
        }
    }

    protected interface ToOverride {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;

        public void close();

        public String getId();
        
        public void setId(final String srcId);
    }

    // @Delegate(types=<T>.class, excludes={ PoolDataSourcePropertiesSetters<T>.class, PoolDataSourcePropertiesGetters<T>.class, ToOverride.class })
    protected T getPoolDataSource() {
        switch (state) {
        case CLOSED:
            throw new IllegalStateException("You can not use the pool once it is closed().");
        default:
            return activeParent != null ? activeParent.poolDataSource : poolDataSource;
        }
    }

    protected final boolean isSingleSessionProxyModel() {
        return poolDataSourceConfiguration.isSingleSessionProxyModel();
    }

    protected final boolean isFixedUsernamePassword() {
        return poolDataSourceConfiguration.isFixedUsernamePassword();
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
        case CLOSING:
            break;
        default:
            throw new IllegalStateException(String.format("You can only get a connection when the pool state is OPEN or CLOSING but it is %s.",
                                                          state.toString()));
        }

        final String usernameSession1 = poolDataSourceConfiguration.getUsernameToConnectTo();
        final String passwordSession1 = poolDataSourceConfiguration.getPassword();
        final String usernameSession2 = poolDataSourceConfiguration.getSchema();        
        final Connection conn = getConnection(getPoolDataSource(),
                                              usernameSession1,
                                              passwordSession1,
                                              usernameSession2);

        // check check double check
        assert conn.getSchema().equalsIgnoreCase(usernameSession2)
            : String.format("Current schema name (%s) should be the same as the requested name (%s)",
                            conn.getSchema(),
                            usernameSession2);

        return conn;
    }

    @Deprecated
    public final Connection getConnection(String username, String password) throws SQLException {
        throw new SQLFeatureNotSupportedException();
    }

    // two purposes:
    // 1) get a standard connection (session 1) but maybe with a different username/password than the default
    // 2) get a connection for the multi-session proxy model (session 2)
    protected Connection getConnection(@NonNull final T poolDataSource,
                                       @NonNull final String usernameSession1,
                                       @NonNull final String passwordSession1,
                                       @NonNull final String usernameSession2) throws SQLException {
        return getConnection2(getConnection1(poolDataSource, usernameSession1, passwordSession1),
                              usernameSession1,
                              passwordSession1,
                              usernameSession2);
    }

    // get a standard connection (session 1) but maybe with a different username/password than the default
    protected abstract Connection getConnection1(@NonNull final T poolDataSource,
                                                 @NonNull final String usernameSession1,
                                                 @NonNull final String passwordSession1) throws SQLException;

    // get a connection for the multi-session proxy model (session 2)
    protected Connection getConnection2(@NonNull final Connection conn,
                                        @NonNull final String usernameSession1,
                                        @NonNull final String passwordSession1,
                                        @NonNull final String usernameSession2) throws SQLException {
        log.debug(">getConnection2(id={}, usernameSession1={}, usernameSession2={})",
                  getId(),
                  usernameSession1,
                  usernameSession2);

        try {
            log.debug("before proxy session - current schema: {}",
                      conn.getSchema());

            // if the current schema is not the requested schema try to open/close the proxy session
            if (!conn.getSchema().equalsIgnoreCase(usernameSession2)) {
                assert !isSingleSessionProxyModel()
                    : "Requested schema name should be the same as the current schema name in the single-session proxy model";

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
                            if (!conn.getSchema().equalsIgnoreCase(usernameSession1) /*oraConn.isProxySession()*/) {
                                // go back to the session with the first username
                                try {
                                    oraConn.close(OracleConnection.PROXY_SESSION);
                                } catch (SQLException ex) {
                                    log.warn("SQL warning: {}", ex.getMessage());
                                }
                                oraConn.setSchema(usernameSession1);
                            }
                            break;
                            
                        case 1:
                            if (!usernameSession1.equals(usernameSession2)) {
                                // open a proxy session with the second username
                                final Properties proxyProperties = new Properties();

                                proxyProperties.setProperty(OracleConnection.PROXY_USER_NAME, usernameSession2);
                                oraConn.openProxySession(OracleConnection.PROXYTYPE_USER_NAME, proxyProperties);
                                oraConn.setSchema(usernameSession2);
                            }
                            break;
                            
                        case 2:
                            oraConn.setSchema(usernameSession2);
                            break;
                            
                        default:
                            throw new IllegalArgumentException(String.format("Wrong value for nr (%d): must be between 0 and 2", nr));
                        }

                        log.debug("after open proxy session (#{}) - current schema: {}; is proxy session: {}",
                                  nr,
                                  conn.getSchema(),
                                  oraConn.isProxySession());
                    } while (!conn.getSchema().equalsIgnoreCase(usernameSession2) && nr++ < 3);

                }                
            }

            log.debug("after proxy session - current schema: {}",
                      conn.getSchema());
        } catch (SQLException ex) {
            log.debug("SQL error: {}", ex.getMessage());
            throw ex;
        } finally {
            log.debug("<getConnection2(id={})", getId());
        }
        
        return conn;
    }

    public String getId() {
        return id.toString();
    }
    
    public void setId(final String srcId) {
        SimplePoolDataSource.setId(id, String.format("0x%08x", hashCode()), srcId);
    }
}
