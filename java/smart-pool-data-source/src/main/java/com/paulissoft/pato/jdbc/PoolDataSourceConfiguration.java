package com.paulissoft.pato.jdbc;

import javax.sql.DataSource;
import lombok.AccessLevel;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;
import lombok.experimental.SuperBuilder;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;


@Data
@NoArgsConstructor
@SuperBuilder(toBuilder = true)
@ConfigurationProperties
@Slf4j
public class PoolDataSourceConfiguration implements ConnectInfo {

    private String driverClassName;

    private String url;
    
    private String username;

    private String password;

    private String type;

    // username like:
    // * bc_proxy[bodomain] => proxyUsername = bc_proxy, schema = bodomain
    // * bodomain => proxyUsername = null, schema = bodomain
    @Getter(AccessLevel.PACKAGE)
    @Setter(AccessLevel.NONE)
    @ToString.Exclude
    private String proxyUsername;

    @Getter(AccessLevel.PACKAGE)
    @Setter(AccessLevel.NONE)
    @ToString.Exclude
    private String schema; // needed to build the PoolName

    // see https://docs.oracle.com/en/database/oracle/oracle-database/19/jajdb/oracle/jdbc/OracleConnection.html
    // true - do not use openProxySession() but use proxyUsername[schema]
    // false - use openProxySession() (two sessions will appear in v$session)
    public boolean isSingleSessionProxyModel() {
        return true;
    }

    public boolean isUseFixedUsernamePassword() {
        return false;
    }
        
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
        if (!isUseFixedUsernamePassword()) {
            this.username = null;
        }
        this.password = null;
    }

    void clearNonIdConfiguration() {
        this.password = null;
    }

    /**
     * Turn a proxy connection username (bc_proxy[bodomain] or bodomain) into
     * schema (bodomain) and proxy username (bc_proxy respectively empty).
     */    
    void determineConnectInfo(final String username, final String password) {
        this.username = username;
        this.password = password;
        determineConnectInfo();
    }
    
    void determineConnectInfo() {
        if (username == null) {
            proxyUsername = schema = null;
        } else if (schema == null) { /* determine only when necessary */
            log.debug(">determineConnectInfo(username={})", username);
            
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

            log.debug("<determineConnectInfo(username={}, proxyUsername={}, schema={})",
                      username,
                      proxyUsername,
                      schema);
        }
    }

    /**
     *
     * Get the username to connect to.
     *
     * Some observations:
     * 1 - when username does NOT contain proxy info (like "bodomain", not "bc_proxy[bodomain]")
     *     the username to connect must be username (e.g. "bodomain", proxyUsername is null)
     * 2 - else, when singleSessionProxyModel is true,
     *     the username to connect to MUST be username (e.g. "bc_proxy[bodomain]") and
     *     never proxyUsername ("bc_proxy")
     * 3 - else, when singleSessionProxyModel is false,
     *     the username to connect to must be proxyUsername ("bc_proxy") and
     *     then later on OracleConnection.openProxySession() will be invoked to connect to schema.
     *
     * So you use proxyUsername only if not null and when singleSessionProxyModel is false (case 3).
     *
     * A - when useFixedUsernamePassword is true,
     *     every data source having the same common data source MUST use the same username/password to connect to.
     *     Meaning that these properties MUST be part of the commonDataSourceProperties!
     *
     * @param singleSessionProxyModel  Do we use a single session proxy model?
     */
    String getUsernameToConnectTo() {
        assert(username != null);
        
        return !isSingleSessionProxyModel() && proxyUsername != null ?
            /* see observations in constructor of SmartPoolDataSource for the case numbers */
            proxyUsername /* case 3 */ :
            username /* case 1 & 2 */;
    }
}
