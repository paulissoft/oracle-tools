package com.paulissoft.pato.jdbc;

import java.lang.reflect.Method;
import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import java.io.Closeable;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.HashSet;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;
import javax.sql.DataSource;
import oracle.jdbc.OracleConnection;


@Slf4j
public abstract class CombiPoolDataSource<T extends DataSource> implements DataSource, Closeable {

    // syntax error on: private static final ConcurrentHashMap<PoolDataSourceConfigurationCommonId, T> so use DataSource instead of T
    private static final ConcurrentHashMap<PoolDataSourceConfigurationCommonId, DataSource> commonPoolDataSources = new ConcurrentHashMap<>();

    // a matrix of (active) configPoolDataSource instances per commonPoolDataSource: needed for canClose()
    private static final ConcurrentHashMap<DataSource, Set<DataSource>> activeConfigPoolDataSources = new ConcurrentHashMap<>();

    static void clear() {
        commonPoolDataSources.clear();
        activeConfigPoolDataSources.clear();
    }    

    @NonNull
    private final T configPoolDataSource; // set in constructor

    private final CombiPoolDataSource<T> commonCombiPoolDataSource;
        
    private T commonPoolDataSource = null; // commonCombiPoolDataSource.commonPoolDataSource

    enum State {
        INITIALIZING,
        READY,
        CLOSING, // can not close due to children not closed yet
        CLOSED
    }

    @NonNull
    private State state = State.INITIALIZING;

    @Getter
    private String usernameSession1;

    /**
     * Since getPassword() is a deprecated method (in Oracle UCP) we need another way of getting it.
     * The idea is to implement setPassword() here and store it in passwordSession1.
     * We need also to invoke configPoolDataSource.setPassword(password) via reflection.
     */

    @Getter(AccessLevel.PROTECTED)
    private String passwordSession1;

    @Getter
    private String usernameSession2;

    protected CombiPoolDataSource(@NonNull final T configPoolDataSource) {
        this(configPoolDataSource, null);
        
        log.info("CombiCommonPoolDataSource({})", configPoolDataSource);
    }
    
    protected CombiPoolDataSource(@NonNull final T configPoolDataSource, final CombiPoolDataSource<T> commonCombiPoolDataSource) {
        this.configPoolDataSource = configPoolDataSource;
        this.commonCombiPoolDataSource = commonCombiPoolDataSource;
        
        log.info("CombiCommonPoolDataSource({}, {})", configPoolDataSource, commonCombiPoolDataSource);
    }

    @PostConstruct
    public void init() {
        log.debug("init(state={})", state);
        
        if (state == State.INITIALIZING) {
            determineConnectInfo();
            updateCombiPoolAdministration();
            updatePool(configPoolDataSource, commonPoolDataSource, true);
            state = State.READY;
        }
    }

    @PreDestroy
    public void done(){
        log.debug("done(state={})", state);
        
        if (state != State.CLOSED) {
            updateCombiPoolAdministration();
            updatePool(configPoolDataSource, commonPoolDataSource, false);
            state = State.CLOSED;
        }
    }

    public abstract PoolDataSourceConfiguration getPoolDataSourceConfiguration();

    private void updateCombiPoolAdministration() {
        log.debug("updateCombiPoolAdministration(state={})", state);
        
        final PoolDataSourceConfigurationCommonId thisCommonId =
            new PoolDataSourceConfigurationCommonId(getPoolDataSourceConfiguration());
            
        if (state == State.INITIALIZING) {
            if (this.commonCombiPoolDataSource == null) {
                final T commonPoolDataSource = (T) commonPoolDataSources.get(thisCommonId);

                if (commonPoolDataSource == null) {
                    this.commonPoolDataSource = this.configPoolDataSource;
                } else {
                    this.commonPoolDataSource = commonPoolDataSource;
                }
            } else {
                final PoolDataSourceConfigurationCommonId thatCommonId =
                    new PoolDataSourceConfigurationCommonId(this.commonCombiPoolDataSource.getPoolDataSourceConfiguration());

                log.debug("thisCommonId: {}; thatCommonId: {}", thisCommonId, thatCommonId);
                
                assert thisCommonId.equals(thatCommonId) : "The config and common pool data source should have the same common id";
                
                this.commonPoolDataSource = this.commonCombiPoolDataSource.commonPoolDataSource;
            }

            commonPoolDataSources.computeIfAbsent(thisCommonId, k -> this.commonPoolDataSource);
        }

        assert this.commonPoolDataSource != null : "The common pool data source must NOT be null";

        // isParentPoolDataSource() == true || isParentPoolDataSource() == false, due to this.commonPoolDataSource != null
        if (isParentPoolDataSource()) {
            switch (state) {
            case READY: // close()
                final Set configurations = activeConfigPoolDataSources.get(this.commonPoolDataSource);
                
                if (configurations == null || configurations.isEmpty()) {
                    // no children waiting for their parent
                    activeConfigPoolDataSources.remove(this.commonPoolDataSource);
                    commonPoolDataSources.remove(thisCommonId);
                }
                break;
            default:
                break;
            }
        } else {
            switch (state) {
            case INITIALIZING:
                activeConfigPoolDataSources.computeIfAbsent(this.commonPoolDataSource, k -> new HashSet<>()).add(this.configPoolDataSource);
                break;
            case READY:
                activeConfigPoolDataSources.computeIfPresent(this.commonPoolDataSource, (k, v) -> { v.remove(this.configPoolDataSource); return v; });
                break;
            default:
                break;
            }
        }
    }

    public Boolean isParentPoolDataSource() {
        if (this.configPoolDataSource != null && this.commonPoolDataSource != null) {
            return this.configPoolDataSource == this.commonPoolDataSource;
        } else {
            return null; // we don't know yet
        }
    }

    protected boolean canClose() {
        boolean result = false;
        
        if (state != State.CLOSED) {
            final Set configurations = activeConfigPoolDataSources.get(this.commonPoolDataSource);

            result = configurations == null || configurations.isEmpty();
        }

        log.debug("canClose() = {}", result);

        return result;
    }

    public void close() {
        log.debug("close()");
        
        if (canClose()) {
            done();
        }
    }

    protected abstract void updatePool(@NonNull final T configPoolDataSource,
                                       @NonNull final T commonPoolDataSource,
                                       final boolean initializing);

    protected void determineConnectInfo() {
        log.debug("determineConnectInfo()");
        
        final PoolDataSourceConfiguration configPoolDataSourceuration = getPoolDataSourceConfiguration();

        configPoolDataSourceuration.determineConnectInfo();
        usernameSession1 = configPoolDataSourceuration.getUsernameToConnectTo();
        usernameSession2 = configPoolDataSourceuration.getSchema();        
    }

    protected interface ToOverride {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;

        public void setUsername(String password) throws SQLException;

        public void setPassword(String password) throws SQLException;

        public String getPassword(); /* deprecated in oracle.ucp.jdbc.PoolDataSourceImpl */

        public void close();
    }

    // @Delegate(types=PoolDataSourcePropertiesSettersX.class, excludes=PoolDataSourcePropertiesGettersX.class)
    protected T poolDataSourceSetter() {
        switch (state) {
        case INITIALIZING:
            return configPoolDataSource;
        default:
            throw new IllegalStateException("The configuration of the pool is sealed once started.");
        }
    }

    // @Delegate(types=PoolDataSourcePropertiesGettersX.class, excludes=ToOverride.class)
    protected T poolDataSourceGetter() {
        switch (state) {
        case INITIALIZING:
            return configPoolDataSource;
        default:
            return commonPoolDataSource;
        }
    }

    // @Delegate(types=DataSource.class, excludes=ToOverride.class)
    protected T getCommonPoolDataSource() {
        switch (state) {
        case CLOSED:
            throw new IllegalStateException("You can not use the pool once it is closed().");
        default:
            return commonPoolDataSource;
        }
    }

    protected boolean isSingleSessionProxyModel() {
        return PoolDataSourceConfiguration.SINGLE_SESSION_PROXY_MODEL;
    }

    protected boolean isFixedUsernamePassword() {
        return PoolDataSourceConfiguration.FIXED_USERNAME_PASSWORD;
    }
    
    public abstract String getUsername();

    public abstract void setUsername(String username) throws SQLException;

    public final String getPassword() {
        return passwordSession1;
    }

    public final void setPassword(String password) {
        passwordSession1 = password;

        try {
            final Method setPasswordMethod = configPoolDataSource.getClass().getMethod("setPassword", String.class);
            
            setPasswordMethod.invoke(configPoolDataSource, password);
        } catch (Exception ex) {
            throw new RuntimeException(SimplePoolDataSource.exceptionToString(ex));
        }
    }

    // two purposes:
    // 1) get a standard connection (session 1) but maybe with a different username/password than the default
    // 2) get a connection for the multi-session proxy model (session 2)
    protected Connection getConnection(@NonNull final String usernameSession1,
                                       @NonNull final String passwordSession1,
                                       @NonNull final String usernameSession2) throws SQLException {
        return getConnection2(getConnection1(usernameSession1, passwordSession1),
                              usernameSession1,
                              passwordSession1,
                              usernameSession2);
    }

    // get a standard connection (session 1) but maybe with a different username/password than the default
    protected abstract Connection getConnection1(@NonNull final String usernameSession1,
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

            assert conn.getSchema().equalsIgnoreCase(usernameSession2)
                : String.format("Current schema name (%s) should be the same as the requested name (%s)",
                                conn.getSchema(),
                                usernameSession2);
        }
        
        return conn;
    }
}
