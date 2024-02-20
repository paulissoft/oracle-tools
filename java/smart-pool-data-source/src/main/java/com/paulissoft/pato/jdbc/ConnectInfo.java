package com.paulissoft.pato.jdbc;

import lombok.Getter;
import lombok.AccessLevel;
import lombok.extern.slf4j.Slf4j;


@Slf4j
@Getter(AccessLevel.PACKAGE)
class ConnectInfo {

    private String username;

    private String password;
    
    // username like:
    // * bc_proxy[bodomain] => proxyUsername = bc_proxy, schema = bodomain
    // * bodomain => proxyUsername = null, schema = bodomain
    private String proxyUsername;
    
    private String schema; // needed to build the PoolName

    /**
     * Turn a proxy connection username (bc_proxy[bodomain] or bodomain) into
     * schema (bodomain) and proxy username (bc_proxy respectively empty).
     *
     * @param username  The username to connect to.
     * @param password  The pasword.
     *
     */    
    ConnectInfo(final String username) {
        this(username, null);
    }
    
    ConnectInfo(final String username, final String password) {
        this.username = username;
        this.password = password;

        if (username == null) {
            this.proxyUsername = null;
            this.schema = null;
        } else {
            final int pos1 = username.indexOf("[");
            final int pos2 = ( username.endsWith("]") ? username.length() - 1 : -1 );
      
            if (pos1 >= 0 && pos2 >= pos1) {
                // a username like bc_proxy[bodomain]
                this.proxyUsername = username.substring(0, pos1);
                this.schema = username.substring(pos1+1, pos2);
            } else {
                // a username like bodomain
                this.proxyUsername = null;
                this.schema = username;
            }
        }
        
        log.debug("ConnectInfo(username={}) = (this.username={}, this.proxyUsername={}, this.schema={})",
                  username,
                  this.username,
                  this.proxyUsername,
                  this.schema);
    }

    String getUsernameToConnectTo(final boolean singleSessionProxyModel) {
        return !singleSessionProxyModel && proxyUsername != null ?
            /* see observations in constructor of SmartPoolDataSource for the case numbers */
            proxyUsername /* case 3 */ :
            username /* case 1 & 2 */;
    }
}    
