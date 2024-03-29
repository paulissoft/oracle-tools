package com.paulissoft.pato.jdbc;

import java.io.Closeable;
import java.lang.reflect.Method;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.util.Properties;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import javax.sql.DataSource;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;
import oracle.jdbc.OracleConnection;


@Slf4j
public abstract class CombiPoolDataSource<T extends DataSource> implements DataSource, Closeable {

    // We need to know the active parents in order to assign a value to an active parent so that a data source can use a common data source.
    // syntax error on: private static final ConcurrentHashMap<PoolDataSourceConfigurationCommonId, CombiPoolDataSource<T>> so use DataSource instead of T
    private static final ConcurrentHashMap<PoolDataSourceConfigurationCommonId, DataSource> activeParents = new ConcurrentHashMap<>();

    static void clear() {
        activeParents.clear();
    }    

    /*
     * The first two instance fields (poolDataSource and passwordSession1) are passed in the array fields in the constructor.
     * The password is needed to later con switch to another user while connecting.
     */
    
    @NonNull
    private final T poolDataSource; // set in constructor

    /**
     * Since getPassword() is a deprecated method (in Oracle UCP) we need another way of getting it.
     * The idea is to pass it via the constructor.
     */

    @Getter(AccessLevel.PROTECTED)
    private final String passwordSession1;

    @NonNull
    private final AtomicInteger activeChildren = new AtomicInteger(0); // safe in threads

    private final PoolDataSourceConfiguration poolDataSourceConfiguration;

    private final PoolDataSourceConfigurationCommonId commonId;

    private final CombiPoolDataSource<T> activeParent;

    @Getter
    private final String usernameSession1;

    @Getter
    private final String usernameSession2;

    protected enum State {
        INITIALIZING, // next state: OPEN
        OPEN,         // next possible states: CLOSING (a parent that has active children) or CLOSED (otherwise)
        CLOSING,      // can not close yet since there are active children: next possible states: CLOSED
        CLOSED
    }

    @NonNull
    private volatile State state = State.INITIALIZING; // changed in a synchronized method close()

    protected CombiPoolDataSource(@NonNull final Object[] fields) {
        assert(fields.length == 2);
        
        poolDataSource = (T) fields[0];
        passwordSession1 = (String) fields[1];        
        poolDataSourceConfiguration = getPoolDataSourceConfiguration();

        log.debug("poolDataSourceConfiguration: {}", poolDataSourceConfiguration);
        
        poolDataSourceConfiguration.determineConnectInfo();
        usernameSession1 = poolDataSourceConfiguration.getUsernameToConnectTo();
        usernameSession2 = poolDataSourceConfiguration.getSchema();
        commonId = new PoolDataSourceConfigurationCommonId(poolDataSourceConfiguration);
        activeParent = determineActiveParent();        
        updateCombiPoolAdministration();
        updatePool(poolDataSource, determineCommonPoolDataSource(), true, activeParent == null);
        state = State.OPEN;
        log.info("CombiCommonPoolDataSource({})", poolDataSource);
    }

    protected State getState() {
        return state;
    }

    public abstract PoolDataSourceConfiguration getPoolDataSourceConfiguration();

    private CombiPoolDataSource<T> determineActiveParent() {
        log.debug("determineActiveParent()");
        
        // Since the configuration is fixed now we can do lookups for an active parent.
        // The first pool data source (for same properties) will have activeParent == null

        CombiPoolDataSource<T> activeParent = (CombiPoolDataSource<T>) activeParents.get(commonId); 

        if (activeParent != null && activeParent.state != State.OPEN) {
            activeParent = null;
        }

        if (activeParent == null) {
            // The next with the same properties will get this one as activeParent
            activeParents.computeIfAbsent(commonId, k -> this);
        }

        return activeParent;
    }

    private void updateCombiPoolAdministration() {
        if (activeParent != null) {
            switch (state) {
            case INITIALIZING:
                activeParent.activeChildren.incrementAndGet();
                break;
            case OPEN:
                if (activeParent.activeChildren.decrementAndGet() == 0 && activeParent.state == State.CLOSING) {
                    activeParent.close(); // try to close() again
                }
                break;
            default:
                break;
            }
        }
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
            updateCombiPoolAdministration();
            updatePool(poolDataSource, determineCommonPoolDataSource(), false, activeParent == null);
            state = this.state = State.CLOSED;
            break;
            
        case CLOSED:
            break;
        }
        
        log.debug("state while leaving tearDown(): {}", state);
    }

    protected void updatePoolName(@NonNull final T configPoolDataSource,
                                  @NonNull final T commonPoolDataSource,
                                  final boolean initializing,
                                  final boolean isParentPoolDataSource) {
    }

    protected void updatePoolSizes(@NonNull final T configPoolDataSource,
                                   @NonNull final T commonPoolDataSource,
                                   final boolean initializing) {

    }

    protected void updatePool(@NonNull final T configPoolDataSource,
                              @NonNull final T commonPoolDataSource,
                              final boolean initializing,
                              final boolean isParentPoolDataSource) {
        updatePoolName(configPoolDataSource,
                       commonPoolDataSource,
                       initializing,
                       isParentPoolDataSource);
        if (!isParentPoolDataSource) { // do not double the pool size when it is a activeParent
            updatePoolSizes(configPoolDataSource,
                            commonPoolDataSource,
                            initializing);
        }
    }

    protected interface ToOverride {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;

        public void setUsername(String password) throws SQLException;

        // to prevent this error in Hikari: overridden method does not throw java.sql.SQLException
        public void setPassword(String password) throws SQLException;

        public String getPassword(); /* deprecated in oracle.ucp.jdbc.PoolDataSourceImpl */

        public void close();
    }

    // @Delegate(types=PoolDataSourcePropertiesSetters<T>.class, excludes=ToOverride.class)
    protected T determinePoolDataSourceSetter() {
        switch (state) {
        case INITIALIZING:
            return poolDataSource;
        case CLOSED:
            throw new IllegalStateException("You can not use the pool once it is closed().");
        default:
            throw new IllegalStateException("The configuration of the pool is sealed once started.");
        }
    }

    // @Delegate(types=PoolDataSourcePropertiesGetters<T>.class, excludes=ToOverride.class)
    protected T determinePoolDataSourceGetter() {
        switch (state) {
        case INITIALIZING:
            return poolDataSource;
        case CLOSED:
            throw new IllegalStateException("You can not use the pool once it is closed().");
        default:
            return activeParent != null ? activeParent.poolDataSource : poolDataSource;
        }
    }

    // @Delegate(types=<T>.class, excludes={ PoolDataSourcePropertiesSetters<T>.class, PoolDataSourcePropertiesGetters<T>.class, ToOverride.class })
    protected T determineCommonPoolDataSource() {
        switch (state) {
        case CLOSED:
            throw new IllegalStateException("You can not use the pool once it is closed().");
        default:
            return activeParent != null ? activeParent.poolDataSource : poolDataSource;
        }
    }

    protected boolean isSingleSessionProxyModel() {
        return PoolDataSourceConfiguration.SINGLE_SESSION_PROXY_MODEL;
    }

    protected boolean isFixedUsernamePassword() {
        return PoolDataSourceConfiguration.FIXED_USERNAME_PASSWORD;
    }

    // public abstract String getUsername();

    public abstract void setUsername(String username) throws SQLException;

    @Deprecated
    public final String getPassword() {
        return passwordSession1;
    }

    public final void setPassword(String password) {
        try {
            final Method setPasswordMethod = poolDataSource.getClass().getMethod("setPassword", String.class);
            
            setPasswordMethod.invoke(poolDataSource, password);
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }
    
    public final Connection getConnection() throws SQLException {
        switch (state) {
        case OPEN:
        case CLOSING:
            break;
        default:
            throw new IllegalStateException(String.format("You can only get a connection when the pool state is OPEN or CLOSING but it is %s.",
                                                          state.toString()));
        }

        // minimize accessing volatile variables by shadowing them
        final String usernameSession1 = this.usernameSession1;
        final String passwordSession1 = this.passwordSession1;
        final String usernameSession2 = this.usernameSession2;

        final Connection conn = getConnection(determineCommonPoolDataSource(),
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
