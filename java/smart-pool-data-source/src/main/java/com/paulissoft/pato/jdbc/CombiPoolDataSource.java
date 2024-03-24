package com.paulissoft.pato.jdbc;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
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
import javax.sql.DataSource;
import oracle.jdbc.OracleConnection;


public abstract class CombiPoolDataSource<T extends DataSource> implements DataSource, Closeable {

    // syntax error on: private static final ConcurrentHashMap<PoolDataSourceConfigurationCommonId, T> so use DataSource instead of T
    private static final ConcurrentHashMap<PoolDataSourceConfigurationCommonId, DataSource> commonPoolDataSources = new ConcurrentHashMap<>();

    // a matrix of (active) configPoolDataSource instances per commonPoolDataSource: needed for canClose()
    private static final ConcurrentHashMap<DataSource, Set<DataSource>> activeConfigPoolDataSources = new ConcurrentHashMap<>();
    
    @NonNull
    private final T configPoolDataSource;

    private T commonPoolDataSource = null;

    private boolean initializing = true;

    @Getter
    private String usernameSession1;

    /**
     * Since getPassword() is a deprecated method (in Oracle UCP) we need another way of getting it.
     * The idea is to implement setPassword() here and store it in passwordSession1.
     * We need also override it in classes that extend this one like this:
     *
     * <code>
     * @Override
     * public void setPassword(String password) throws SQLException {
     *   super.setPassword(password); // sets passwordSession1
     *   getConfigPoolDataSource().setPassword(password);
     * }
     * </code>
     */

    @Getter(AccessLevel.PROTECTED)
    private String passwordSession1;

    @Getter
    private String usernameSession2;

    protected CombiPoolDataSource(@NonNull final T configPoolDataSource) {
        this(configPoolDataSource, null);
    }
    
    protected CombiPoolDataSource(@NonNull final T configPoolDataSource, final CombiPoolDataSource<T> combiPoolDataSource) {
        this.configPoolDataSource = configPoolDataSource;
        this.commonPoolDataSource = combiPoolDataSource != null ? combiPoolDataSource.commonPoolDataSource : null;
    }

    @PostConstruct
    public void init() {
        if (initializing) {
            determineConnectInfo();
            updateCombiPoolAdministration();
            updatePool(configPoolDataSource, commonPoolDataSource, initializing);
            initializing = false;
        }
    }

    @PreDestroy
    public void done(){
        if (!initializing) {
            updateCombiPoolAdministration();
            updatePool(configPoolDataSource, commonPoolDataSource, initializing);
            initializing = true;
        }
    }
    
    @Override
    public boolean equals(Object obj) {
        if (obj == null) {
            return false;
        }

        try {
            final T other = (T) obj;
        
            return other.toString().equals(this.toString());
        } catch (Exception ex) {
            return false;
        }
    }

    @Override
    public int hashCode() {
        return this.getPoolDataSourceConfiguration().hashCode();
    }

    @Override
    public String toString() {
        return this.getPoolDataSourceConfiguration().toString();
    }

    public abstract PoolDataSourceConfiguration getPoolDataSourceConfiguration();

    private void updateCombiPoolAdministration() {            
        if (initializing && this.commonPoolDataSource == null) {
            final PoolDataSourceConfigurationCommonId commonId = new PoolDataSourceConfigurationCommonId(getPoolDataSourceConfiguration());
            final T commonPoolDataSource = (T) commonPoolDataSources.get(commonId);

            if (commonPoolDataSource == null) {
                this.commonPoolDataSource = this.configPoolDataSource;
                commonPoolDataSources.computeIfAbsent(commonId, k -> this.commonPoolDataSource);
            } else {
                this.commonPoolDataSource = commonPoolDataSource;
            }
        }

        assert this.commonPoolDataSource != null;
        
        if (this.configPoolDataSource != this.commonPoolDataSource) {
            if (initializing) {
                activeConfigPoolDataSources.computeIfAbsent(this.commonPoolDataSource, k -> new HashSet<>()).add(this.configPoolDataSource);
            } else {
                activeConfigPoolDataSources.computeIfPresent(this.commonPoolDataSource, (k, v) -> { v.remove(this.configPoolDataSource); return v; });
            }
        }
    }

    protected boolean canClose() {
        final Set configurations = activeConfigPoolDataSources.get(this.commonPoolDataSource);

        return configurations == null || configurations.isEmpty();
    }

    protected abstract void updatePool(@NonNull final T configPoolDataSource, @NonNull final T commonPoolDataSource, final boolean initializing);

    protected void determineConnectInfo() {
        final PoolDataSourceConfiguration configPoolDataSourceuration = getPoolDataSourceConfiguration();

        configPoolDataSourceuration.determineConnectInfo();
        usernameSession1 = configPoolDataSourceuration.getUsernameToConnectTo();
        usernameSession2 = configPoolDataSourceuration.getSchema();        
    }

    // only setters and getters
    // @Delegate(types=P.class)
    protected T getConfigPoolDataSource() {
        return configPoolDataSource;
    }

    protected interface ToOverride {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;

        public void setPassword(String password) throws SQLException;
    }

    // the rest
    // @Delegate(excludes=ToOverride.class)
    protected T getCommonPoolDataSource() {        
        return initializing ? null : commonPoolDataSource;
    }

    protected abstract boolean isSingleSessionProxyModel();

    protected abstract boolean isFixedUsernamePassword();

    public abstract String getUsername();

    public abstract void setUsername(String username) throws SQLException;

    public void setPassword(String password) throws SQLException {
        if (initializing) {
            passwordSession1 = password;
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
    protected Connection getConnection1(@NonNull final String usernameSession1,
                                        @NonNull final String passwordSession1) throws SQLException {
        if (isFixedUsernamePassword()) {
            if (!getUsername().equalsIgnoreCase(usernameSession1)) {
                setUsername(usernameSession1);
                setPassword(passwordSession1);
            }
            return getConnection();
        } else {
            return getConnection(usernameSession1, passwordSession1);
        }
    }

    // get a connection for the multi-session proxy model (session 2)
    protected Connection getConnection2(@NonNull final Connection conn,
                                        @NonNull final String usernameSession1,
                                        @NonNull final String passwordSession1,
                                        @NonNull final String usernameSession2) throws SQLException {
        // if the current schema is not the requested schema try to open/close the proxy session
        if (!conn.getSchema().equalsIgnoreCase(usernameSession2)) {
            assert(!isSingleSessionProxyModel());

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

        assert(conn.getSchema().equalsIgnoreCase(usernameSession2));
        
        return conn;
    }
}
