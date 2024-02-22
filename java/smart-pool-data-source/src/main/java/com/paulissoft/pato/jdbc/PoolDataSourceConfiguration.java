package com.paulissoft.pato.jdbc;

import javax.sql.DataSource;
import lombok.AccessLevel;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.SuperBuilder;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;


@Data
@NoArgsConstructor
@SuperBuilder(toBuilder = true)
@ConfigurationProperties
@Slf4j
public class PoolDataSourceConfiguration {

    private String driverClassName;

    private String url;
    
    private String username;

    private String password;

    private String type;

    // the rest of the fields will not be set by Spring Boot properties
    @Setter(AccessLevel.NONE)
    private boolean singleSessionProxyModel;

    @Setter(AccessLevel.NONE)
    private boolean useFixedUsernamePassword;

    // username like:
    // * bc_proxy[bodomain] => proxyUsername = bc_proxy, schema = bodomain
    // * bodomain => proxyUsername = null, schema = bodomain
    @Setter(AccessLevel.NONE)
    private String proxyUsername;

    @Setter(AccessLevel.NONE)
    private String schema; // needed to build the PoolName

    public Class getType() {
        try {
            final Class cls = type != null ? Class.forName(type) : null;

            return cls != null && DataSource.class.isAssignableFrom(cls) ? cls : null;
        } catch (ClassNotFoundException ex) {
            return null;
        }
    }

    public void setType(final String type) {
        try {
            if (DataSource.class.isAssignableFrom(Class.forName(type))) {
                this.type = type;
            }
        } catch (ClassNotFoundException ex) {
            this.type = null;
        }
    }

    // copy parent fields
    public void copy(final PoolDataSourceConfiguration poolDataSourceConfiguration) {
        this.driverClassName = poolDataSourceConfiguration.driverClassName;
        this.url = poolDataSourceConfiguration.url;    
        this.username = poolDataSourceConfiguration.username;
        this.password = poolDataSourceConfiguration.password;

        // GJP 2024-02-20 Type can not change
        // this.type = poolDataSourceConfiguration.type;
    }

    void clearCommonDataSourceConfiguration() {
        this.username = null;
        this.password = null;
    }

    void clearNonIdConfiguration() {
        this.password = null;
    }

    /**
     * Turn a proxy connection username (bc_proxy[bodomain] or bodomain) into
     * schema (bodomain) and proxy username (bc_proxy respectively empty).
     *
     * @param username  The username to connect to.
     * @param password  The pasword.
     *
     */    
    void determineConnectInfo() {
        if (username == null) {
            proxyUsername = null;
            schema = null;
        } else {
            final int pos1 = username.indexOf("[");
            final int pos2 = ( username.endsWith("]") ? username.length() - 1 : -1 );
      
            if (pos1 >= 0 && pos2 >= pos1) {
                // a username like bc_proxy[bodomain]
                proxyUsername = username.substring(0, pos1);
                schema = username.substring(pos1+1, pos2);
            } else {
                // a username like bodomain
                proxyUsername = null;
                schema = username;
            }
        }
        
        log.debug("determineConnectInfo(username={}) = (username={}, proxyUsername={}, schema={})",
                  username,
                  username,
                  proxyUsername,
                  schema);
    }

    String getUsernameToConnectTo() {
        return !singleSessionProxyModel && proxyUsername != null ?
            /* see observations in constructor of SmartPoolDataSource for the case numbers */
            proxyUsername /* case 3 */ :
            username /* case 1 & 2 */;
    }
}
