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
public abstract class CombiPoolDataSource<T extends DataSource, P extends PoolDataSourceConfiguration>
    implements DataSource, Closeable {

    // We need to know the active parents in order to assign a value to an active parent so that a data source can use a common data source.
    // Syntax error on: private static final ConcurrentHashMap<PoolDataSourceConfigurationCommonId, CombiPoolDataSource<T, P, S, G>>,
    // so use DataSource instead of T.
    private static final ConcurrentHashMap<PoolDataSourceConfigurationCommonId, DataSource> activeParents = new ConcurrentHashMap<>();

    static void clear() {
        activeParents.clear();
    }    

    private final Supplier<T> supplierT;
    
    private final Supplier<P> supplierP;
    
    @Getter(AccessLevel.PACKAGE)
    @NonNull
    private final P poolDataSourceConfiguration;

    /* either poolDataSource or activeParent is null */
    
    private final T poolDataSource;

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

    /* 1: everything null, INITIALIZING */
    protected CombiPoolDataSource(final Supplier<T> supplierT,
                                  final Supplier<P> supplierP) {
        this(supplierT, supplierP, null, null, null);
    }

    /* 2: poolDataSourceConfiguration != null (fixed), OPEN */
    protected CombiPoolDataSource(final Supplier<T> supplierT,
                                  final Supplier<P> supplierP,
                                  @NonNull final P poolDataSourceConfiguration) {
        this(supplierT, supplierP, poolDataSourceConfiguration, null, null);
    }

    /* 3: activeParent != null, INITIALIZING */
    protected CombiPoolDataSource(Supplier<T> supplierT,
                                  Supplier<P> supplierP,
                                  @NonNull final CombiPoolDataSource<T, P> activeParent) {
        this(supplierT, supplierP, null, null, activeParent);
    }

    private CombiPoolDataSource(final Supplier<T> supplierT,
                                final Supplier<P> supplierP,
                                final P poolDataSourceConfiguration,
                                final T poolDataSource,
                                final CombiPoolDataSource<T, P> activeParent) {
        try {
            log.debug(">CombiPoolDataSource(poolDataSourceConfiguration={}, poolDataSource={}, activeParent={})",
                      poolDataSourceConfiguration,
                      poolDataSource,
                      activeParent);
            
            // https://stackoverflow.com/questions/75175/create-instance-of-generic-type-in-java
            this.supplierT = supplierT;
            this.supplierP = supplierP;
        
            if (poolDataSourceConfiguration == null && poolDataSource == null && activeParent == null) {
                this.poolDataSourceConfiguration = supplierP.get();
                this.poolDataSource = supplierT.get();
                this.activeParent = null;
            } else if (poolDataSourceConfiguration != null && poolDataSource == null && activeParent == null) {
                this.poolDataSourceConfiguration = poolDataSourceConfiguration;
                this.activeParent = determineActiveParent();
                this.poolDataSource = this.activeParent == null ? supplierT.get() : null;
                setUp();
            } else if (poolDataSourceConfiguration == null && poolDataSource == null && activeParent != null) {
                this.poolDataSourceConfiguration = supplierP.get();
                this.poolDataSource = null;
                this.activeParent = activeParent;
            } else {
                throw new IllegalStateException("Illegal combination of poolDataSourceConfiguration, poolDataSource and activeParent");
            }

            assert this.poolDataSourceConfiguration != null;
            assert (this.poolDataSource == null) != (this.activeParent == null);
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        } finally {
            log.debug("<CombiPoolDataSource()");
        }
    }

    protected State getState() {
        return state;
    }

    @jakarta.annotation.PostConstruct
    @javax.annotation.PostConstruct
    public final synchronized void open() {
        log.debug("open()");
        
        setUp();
    }

    private void setUp() {
        // minimize accessing volatile variables by shadowing them
        State state = this.state;

        log.debug(">setUp(state={})", state);

        if (state == State.INITIALIZING) {
            try {
                poolDataSourceConfiguration.determineConnectInfo();
                updateCombiPoolAdministration();
                updatePool(poolDataSourceConfiguration, getCommonPoolDataSource(), true, activeParent == null);
                state = this.state = State.OPEN;
            } catch (Exception ex) {
                state = this.state = State.ERROR;
                throw ex;
            }
        }

        log.debug("<setUp(state={})", state);
    }

    public final boolean isParentPoolDataSource() {
        return activeParent == null;
    }
        
    private CombiPoolDataSource<T, P> determineActiveParent() {
        log.debug(">determineActiveParent()");
        
        // Since the configuration is fixed now we can do lookups for an active parent.
        // The first pool data source (for same properties) will have activeParent == null
        final PoolDataSourceConfigurationCommonId commonId =
            new PoolDataSourceConfigurationCommonId(poolDataSourceConfiguration);

        CombiPoolDataSource<T, P> activeParent = (CombiPoolDataSource<T, P>) activeParents.get(commonId); 

        if (activeParent != null && activeParent.state != State.OPEN) {
            activeParent = null;
        }

        log.debug("<determineActiveParent() = {}", activeParent);

        return activeParent;
    }

    private void updateCombiPoolAdministration() {
        log.debug(">updateCombiPoolAdministration()");
        
        final PoolDataSourceConfigurationCommonId commonId =
            new PoolDataSourceConfigurationCommonId(poolDataSourceConfiguration);
            
        switch (state) {
        case INITIALIZING:
            if (activeParent == null) {
                // The next with the same properties will get this one as activeParent
                activeParents.computeIfAbsent(commonId, k -> this);
            } else {
                final PoolDataSourceConfigurationCommonId parentCommonId =
                    new PoolDataSourceConfigurationCommonId(activeParent.poolDataSourceConfiguration);

                if (!parentCommonId.equals(commonId)) {
                    throw new IllegalArgumentException("The parent and this common configuration should be the same.");
                }
                
                activeParent.activeChildren.incrementAndGet();
            }

            poolDataSourceConfiguration.copyTo(getCommonPoolDataSource());            
            break;
            
        case OPEN:
            if (activeParent != null && activeParent.activeChildren.decrementAndGet() == 0 && activeParent.state == State.CLOSING) {
                activeParent.close(); // try to close() again
            }
            // fall thru        
        default:
            if (activeParent == null) {
                // remove the active parent
                activeParents.computeIfPresent(commonId, (k, v) -> null);
            }            
            break;
        }

        log.debug("<updateCombiPoolAdministration()");
    }

    @jakarta.annotation.PreDestroy
    @javax.annotation.PreDestroy
    public final synchronized void close() {
        log.debug("close()");
        
        tearDown();
    }

    // you may override this one
    // already called in an synchronized context
    protected void tearDown(){
        // minimize accessing volatile variables by shadowing them
        State state = this.state;
        
        log.debug("state while entering tearDown(): {}", state);

        switch(state) {
        case OPEN:
        case CLOSING:
            if (activeParent == null && activeChildren.get() != 0) {
                // parent having active children can not get CLOSED now but mark it as CLOSING (or keep it like that)
                if (state != State.CLOSING) {
                    state = this.state = State.CLOSING;
                }
                break;
            }
            // fall thru
        case INITIALIZING: /* can not have active children since an INITIALIZING parent can never be assigned to activeParent */
        case ERROR:
            updateCombiPoolAdministration();
            updatePool(poolDataSourceConfiguration, getCommonPoolDataSource(), false, activeParent == null);
            state = this.state = State.CLOSED;
            break;
            
        case CLOSED:
            break;
        }
        
        log.debug("state while leaving tearDown(): {}", state);
    }

    protected void updatePoolName(@NonNull final P poolDataSourceConfiguration,
                                  @NonNull final T commonPoolDataSource,
                                  final boolean initializing,
                                  final boolean isParentPoolDataSource) {
    }

    protected void updatePoolSizes(@NonNull final P poolDataSourceConfiguration,
                                   @NonNull final T commonPoolDataSource,
                                   final boolean initializing) {

    }

    protected void updatePool(@NonNull final P poolDataSourceConfiguration,
                              @NonNull final T commonPoolDataSource,
                              final boolean initializing,
                              final boolean isParentPoolDataSource) {
        updatePoolName(poolDataSourceConfiguration,
                       commonPoolDataSource,
                       initializing,
                       isParentPoolDataSource);
        if (!isParentPoolDataSource) { // do not double the pool size when it is a activeParent
            updatePoolSizes(poolDataSourceConfiguration,
                            commonPoolDataSource,
                            initializing);
        }
    }

    protected interface ToOverride {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;

        public void close();
    }

    // @Delegate(types=<T>.class, excludes={ PoolDataSourcePropertiesSetters<T>.class, PoolDataSourcePropertiesGetters<T>.class, ToOverride.class })
    protected T getCommonPoolDataSource() {
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

    public final Connection getConnection() throws SQLException {
        switch (state) {
        case INITIALIZING:
            open(); // will change state to OPEN
            assert(state == State.OPEN);
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
        
        final Connection conn = getConnection(getCommonPoolDataSource(),
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
    protected Connection getConnection(@NonNull final T commonPoolDataSource,
                                       @NonNull final String usernameSession1,
                                       @NonNull final String passwordSession1,
                                       @NonNull final String usernameSession2) throws SQLException {
        return getConnection2(getConnection1(commonPoolDataSource, usernameSession1, passwordSession1),
                              usernameSession1,
                              passwordSession1,
                              usernameSession2);
    }

    // get a standard connection (session 1) but maybe with a different username/password than the default
    protected abstract Connection getConnection1(@NonNull final T commonPoolDataSource,
                                                 @NonNull final String usernameSession1,
                                                 @NonNull final String passwordSession1) throws SQLException;

    // get a connection for the multi-session proxy model (session 2)
    protected Connection getConnection2(@NonNull final Connection conn,
                                        @NonNull final String usernameSession1,
                                        @NonNull final String passwordSession1,
                                        @NonNull final String usernameSession2) throws SQLException {
        log.debug("getConnection2(usernameSession1={}, usernameSession2={})",
                  usernameSession1,
                  usernameSession2);

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
                    
                do {
                    switch(nr) {
                    case 0:
                        if (oraConn.isProxySession()) {
                            // go back to the session with the first username
                            oraConn.close(OracleConnection.PROXY_SESSION);
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
                } while (!conn.getSchema().equalsIgnoreCase(usernameSession2) && nr++ < 3);
            }                
        }
        
        return conn;
    }
}
