package com.paulissoft.pato.jdbc;

import oracle.ucp.jdbc.PoolDataSourceImpl;
import java.sql.Connection;
import java.util.Objects;
import java.util.stream.Collectors;


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
            throw new RuntimeException(String.format("%s: %s", ex.getClass().getName(), ex.getMessage()));
        }
    }
    
    void setUsername(String username) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setUsername() while initializing.");
        }
	try {
	    ds.setUser(username);
        } catch (Exception ex) {
            throw new RuntimeException(String.format("%s: %s", ex.getClass().getName(), ex.getMessage()));
        }
    }

    @Override
    void configure() {
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
        super.configure();

	try {
	    ds.setInitialPoolSize(members.stream().mapToInt(PoolDataSourceImpl::getInitialPoolSize).sum());
	    ds.setMinPoolSize(members.stream().mapToInt(PoolDataSourceImpl::getMinPoolSize).sum());
	    ds.setMaxPoolSize(members.stream().mapToInt(PoolDataSourceImpl::getMaxPoolSize).sum());

	    // properties that may NOT differ, i.e. must be common

        } catch (Exception ex) {
            throw new RuntimeException(String.format("%s: %s", ex.getClass().getName(), ex.getMessage()));
        }
    }

    void close() {
        synchronized(this) {
            state = State.CLOSED;
        }
    }
}    
