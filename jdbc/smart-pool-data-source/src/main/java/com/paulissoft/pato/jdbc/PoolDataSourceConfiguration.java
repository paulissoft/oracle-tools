package com.paulissoft.pato.jdbc;

import javax.sql.DataSource;
import lombok.AccessLevel;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.NonNull;
import lombok.Setter;
import lombok.ToString;
import lombok.experimental.SuperBuilder;
import lombok.extern.slf4j.Slf4j;


@Slf4j
// @Data: A shortcut for @ToString, @EqualsAndHashCode, @Getter on all fields, @Setter on all non-final fields, and @RequiredArgsConstructor!
@Data
@NoArgsConstructor
@SuperBuilder(toBuilder = true)
public abstract class PoolDataSourceConfiguration implements ConnectInfo, PoolDataSourcePropertiesSetters, PoolDataSourcePropertiesGetters {

    public static final boolean SINGLE_SESSION_PROXY_MODEL = true;
    
    public static final boolean FIXED_USERNAME_PASSWORD = false;

    private String driverClassName;

    private String url;

    private String username;

    private String password;

    private String type;

    // username like:
    // * bc_proxy[bodomain] => proxyUsername = bc_proxy, schema = bodomain
    // * bodomain => proxyUsername = null, schema = bodomain
    // user defined getter below
    @Getter(AccessLevel.NONE)
    @Setter(AccessLevel.NONE)
    @ToString.Exclude
    private String proxyUsername;

    // user defined getter below
    @Getter(AccessLevel.NONE)
    @Setter(AccessLevel.NONE)
    @ToString.Exclude
    private String schema; // needed to build the PoolName

    public PoolDataSourceConfiguration(final String driverClassName,
                                       @NonNull final String url,
                                       @NonNull final String username,
                                       @NonNull final String password) {
        // do not show password
        log.debug("PoolDataSourceConfiguration(driverClassName={}, url={}, username={})",
                  driverClassName,
                  url,
                  username);
        
        this.driverClassName = driverClassName;
        this.url = url;
        this.username = username;
        this.password = password;
    }

    public void setUsername(String username) {
        this.username = username;
        proxyUsername = schema = null; // must be recalculated
    }
    
    public String getPoolName() {
        return null;
    }

    public int getInitialPoolSize() {
        return -1;
    }

    public int getMinPoolSize() {
        return -1;
    }

    public int getMaxPoolSize() {
        return -1;
    }

    public abstract long getConnectionTimeout(); // in milliseconds
    
    // see https://docs.oracle.com/en/database/oracle/oracle-database/19/jajdb/oracle/jdbc/OracleConnection.html
    // true - do not use openProxySession() but use proxyUsername[schema]
    // false - use openProxySession() (two sessions will appear in v$session)
    public boolean isSingleSessionProxyModel() {
        return SINGLE_SESSION_PROXY_MODEL;
    }

    public boolean isFixedUsernamePassword() {
        return FIXED_USERNAME_PASSWORD;
    }
        
    @SuppressWarnings("rawtypes")
    public Class getType() {
        try {
            final Class cls = type != null ? Class.forName(type) : null;

            return cls != null && DataSource.class.isAssignableFrom(cls) ? cls : null;
        } catch (ClassNotFoundException ex) {
            return null;
        }
    }

    public void setType(@NonNull final String type) {
        log.debug("setType(type={})", type);
        
        try {
            if (DataSource.class.isAssignableFrom(Class.forName(type))) {
                this.type = type;
            }
        } catch (ClassNotFoundException ex) {
            this.type = null;
        }
    }

    public String getProxyUsername() {
        determineConnectInfo(); // this sets proxyUsername when username is known
        
        return proxyUsername;
    }
    
    public String getSchema() {
        determineConnectInfo(); // this sets schema when username is known
        
        return schema;
    }

    // copy parent fields
    public void copyFrom(final PoolDataSourceConfiguration poolDataSourceConfiguration) {
        this.driverClassName = poolDataSourceConfiguration.driverClassName;
        this.url = poolDataSourceConfiguration.url;    
        setUsername(poolDataSourceConfiguration.username);
        this.password = poolDataSourceConfiguration.password;

        // GJP 2024-02-20 Type can not change
        // this.type = poolDataSourceConfiguration.type;
    }

    void keepCommonIdConfiguration() {
        if (!isFixedUsernamePassword()) {
            setUsername(null);
        }
        this.password = null;
        this.type = null; // GJP 2024-07-13 type is not important for the common id
    }

    void keepIdConfiguration() {
        this.password = null;
    }

    /**
     * Turn a proxy connection username (bc_proxy[bodomain] or bodomain) into
     * schema (bodomain) and proxy username (bc_proxy respectively empty).
     */    
    void determineConnectInfo(final String username, final String password) {
        setUsername(username);
        this.password = password;
        determineConnectInfo();
    }
    
    private void determineConnectInfo() {
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
     * <p>
     * Some observations:
     * 1 - when username does NOT contain proxy info (like "bodomain", not "bc_proxy[bodomain]")
     *     the username to connect must be username (e.g. "bodomain", proxyUsername is null)
     * 2 - else, when singleSessionProxyModel is true,
     *     the username to connect to MUST be username (e.g. "bc_proxy[bodomain]") and
     *     never proxyUsername ("bc_proxy")
     * 3 - else, when singleSessionProxyModel is false,
     *     the username to connect to must be proxyUsername ("bc_proxy") and
     *     then later on OracleConnection.openProxySession() will be invoked to connect to schema.
     * <p>
     * So you use proxyUsername only if not null and when singleSessionProxyModel is false (case 3).
     * <p>
     * A - when useUsernamePassword is true,
     *     every data source having the same common data source MUST use the same username/password to connect to.
     *     Meaning that these properties MUST be part of the commonDataSourceProperties!
     *
     */
    String getUsernameToConnectTo() {
        assert username != null : "Username should not be empty.";

        determineConnectInfo(); // determine proxyUsername if necessary
        
        return !isSingleSessionProxyModel() && proxyUsername != null ?
            /* see observations in constructor of SmartPoolDataSource for the case numbers */
            proxyUsername /* case 3 */ :
            username /* case 1 & 2 */;
    }

    // https://stackoverflow.com/questions/61633821/using-lombok-superbuilder-annotation-with-tobuilder-on-an-abstract-class/61633890#61633890
    public abstract PoolDataSourceConfigurationBuilder<?, ?> toBuilder();
}
