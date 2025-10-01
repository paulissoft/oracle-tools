package com.paulissoft.pato.jdbc;


// a package accessible interface class
interface ConnectInfo  {
    String getCurrentSchema();

    default String getSQLAlterSessionSetCurrentSchema() {
        return "alter session set current_schema = " + getCurrentSchema();
    }
    
    default String[] determineProxyUsernameAndCurrentDSchema(String username) {
        String proxyUsername = null;
        String currentSchema = null;
        
        if (username != null) {
            final int pos1 = username.indexOf("[");
            final int pos2 = ( username.endsWith("]") ? username.length() - 1 : -1 );
      
            if (pos1 >= 0 && pos2 >= pos1) {
                // a username like bc_proxy[bodomain]
                proxyUsername = username.substring(0, pos1);
                currentSchema = username.substring(pos1+1, pos2);
            } else {
                // a username like bodomain
                proxyUsername = null;
                currentSchema = username;
            }
        }
        
        return new String[] { proxyUsername, currentSchema };
    }
}
