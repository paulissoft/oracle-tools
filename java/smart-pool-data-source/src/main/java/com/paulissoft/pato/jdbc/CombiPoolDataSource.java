package com.paulissoft.pato.jdbc;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.io.Closeable;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NonNull;
import javax.sql.DataSource;
import oracle.jdbc.OracleConnection;


public abstract class CombiPoolDataSource<T extends DataSource> implements DataSource, Closeable {

    // for join(), value: pool data source open (true) or not (false)
    private final ConcurrentHashMap<String, Set<T>> configurationsPerExec = new ConcurrentHashMap<>();
    
    @NonNull
    private final T poolDataSourceConfig;

    @NonNull
    private final T poolDataSourceExec;

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
     *   getPoolDataSourceConfig().setPassword(password);
     * }
     * </code>
     */

    @Getter(AccessLevel.PROTECTED)
    private String passwordSession1;

    @Getter
    private String usernameSession2;

    protected CombiPoolDataSource(@NonNull final T poolDataSourceConfig) {
        this(poolDataSourceConfig, null);
    }
    
    protected CombiPoolDataSource(@NonNull final T poolDataSourceConfig, final CombiPoolDataSource<T> poolDataSourceExec) {
        this.poolDataSourceConfig = poolDataSourceConfig;
        this.poolDataSourceExec = poolDataSourceExec != null ? poolDataSourceExec.poolDataSourceExec : poolDataSourceConfig;
    }

    @PostConstruct
    public void init() {
        if (initializing) {
            determineConnectInfo();
            updateConfigurationsPerExec();
            updatePool();
            initializing = false;
        }
    }

    @PreDestroy
    public void done(){
        if (!initializing) {
            updateConfigurationsPerExec();
            updatePool();
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

    private void updateConfigurationsPerExec() {
        if (this.poolDataSourceConfig != this.poolDataSourceExec) {
            // this is a Combi where the executing data source is not the same as the configuration data source
            if (initializing) {
                configurationsPerExec.computeIfAbsent(this.poolDataSourceExec.toString(), k -> new HashSet<T>()).add(this.poolDataSourceConfig);
            } else {
                configurationsPerExec.computeIfPresent(this.poolDataSourceExec.toString(), (k, v) -> { v.remove(this.poolDataSourceConfig); return v; });
            }
        }
    }

    protected boolean canClose() {
        final Set configurations = configurationsPerExec.get(this.poolDataSourceExec.toString());

        return configurations == null || configurations.isEmpty();
    }

    protected abstract void updatePool();

    private void determineConnectInfo() {
        final PoolDataSourceConfiguration poolDataSourceConfiguration = getPoolDataSourceConfiguration();

        poolDataSourceConfiguration.determineConnectInfo();
        usernameSession1 = poolDataSourceConfiguration.getUsernameToConnectTo();
        usernameSession2 = poolDataSourceConfiguration.getSchema();        
    }

    // only setters and getters
    // @Delegate(types=P.class)
    protected T getPoolDataSourceConfig() {
        return poolDataSourceConfig;
    }

    protected interface ToOverride {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;

        public void setPassword(String password) throws SQLException;
    }

    // the rest
    // @Delegate(excludes=ToOverride.class)
    protected T getPoolDataSourceExec() {        
        return initializing ? null : poolDataSourceExec;
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
