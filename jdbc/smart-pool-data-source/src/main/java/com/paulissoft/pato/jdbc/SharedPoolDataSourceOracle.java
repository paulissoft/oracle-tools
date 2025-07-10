package com.paulissoft.pato.jdbc;

import java.sql.SQLException;
import oracle.ucp.jdbc.PoolDataSourceImpl;


// a package accessible class
class SharedPoolDataSourceOracle extends SharedPoolDataSource<PoolDataSourceImpl> {
    private static final String USERNAMES_ERROR = "Not all usernames are the same and not null: %s.";

    private static final String DATA_SOURCE_CLASS_NAMES_ERROR = "Not all data source class names are the same: %s.";

    // constructor
    SharedPoolDataSourceOracle() {
        super(new PoolDataSourceImpl());
    }

    void setPassword(String password) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setPassword() while initializing.");
        }
        try {
            ds.setPassword(password);
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
    
    void setUsername(String username) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setUser() while initializing.");
        }
        try {
            ds.setUser(username);
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    void configure() {
        super.configure();

        try {
            ds.setInitialPoolSize(members.stream().mapToInt(PoolDataSourceImpl::getInitialPoolSize).sum());
            ds.setMinPoolSize(members.stream().mapToInt(PoolDataSourceImpl::getMinPoolSize).sum());
            ds.setMaxPoolSize(members.stream().mapToInt(PoolDataSourceImpl::getMaxPoolSize).sum());

	    /*
	    //  String getURL();
	    //
	    //  String getUser();
	    //
	    //  String getConnectionPoolName();
	    //
	    //  String getConnectionFactoryClassName();
	    //
	    //  boolean getValidateConnectionOnBorrow();
	    //
	    //  int getAbandonedConnectionTimeout();
	    //
	    //  int getTimeToLiveConnectionTimeout();
	    //
	    //  int getInactiveConnectionTimeout();
	    //
	    //  int getTimeoutCheckInterval();
	    //
	    //  int getMaxStatements();
	    //
	    //  long getConnectionWaitDurationInMillis();
	    //
	    //  long getMaxConnectionReuseTime();
	    //
	    //  int getSecondsToTrustIdleConnection();
	    //
	    //  int getConnectionValidationTimeout();
	    //
	    */  
            // properties that may NOT differ, i.e. must be common
	    configureStringProperty(PoolDataSourceImpl::getURL,
				    (ds, value) -> { try { ds.setURL(value); } catch (SQLException ex) { throw new RuntimeException(ex); } },
				    "JDBC URL");

        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    void close() {
        synchronized(this) {
            state = State.CLOSED;
        }
    }
}    
