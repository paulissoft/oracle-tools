package com.paulissoft.pato.jdbc;

import java.io.Closeable;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;
import javax.sql.DataSource;
import lombok.NonNull;
import oracle.jdbc.OracleConnection;


public interface BasePoolDataSource<T extends DataSource> extends DataSource, Closeable {

    void join(final T ds);
    
    void leave(final T ds);
    
    boolean isSingleSessionProxyModel();

    boolean isFixedUsernamePassword();

    String getUsername();

    void setUsername(String username);

    void setPassword(String password);

    default Connection getConnection1(@NonNull final String usernameSession1,
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

    // get a connection for the multi-session proxy model
    default Connection getConnection2(@NonNull final String usernameSession1,
                                      @NonNull final String passwordSession1,
                                      @NonNull final String usernameSession2) throws SQLException {
        assert(!isSingleSessionProxyModel());

        final Connection conn = getConnection1(usernameSession1, passwordSession1);                                      
                
        // if the current schema is not the requested schema try to open/close the proxy session
        if (!conn.getSchema().equalsIgnoreCase(usernameSession2)) {

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
