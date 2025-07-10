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
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }

        // properties that may NOT differ, i.e. must be common

        // just a check: no need to invoke ds.setUser() since that has been done already via SmartPoolDataSourceOracle.setUser().
        checkStringProperty(PoolDataSourceImpl::getUser, "username");

        configureStringProperty(PoolDataSourceImpl::getURL,
                                (ds, value) -> { try { ds.setURL(value); } catch (SQLException ex) { throw new RuntimeException(ex); } },
                                "URL");

        configureStringProperty(PoolDataSourceImpl::getConnectionFactoryClassName,
                                (ds, value) -> {
                                    try {
                                        ds.setConnectionFactoryClassName(value);
                                    } catch (SQLException ex) {
                                        throw new RuntimeException(ex);
                                    }
                                },
                                "connection factory class name");

        configureBooleanProperty(PoolDataSourceImpl::getValidateConnectionOnBorrow,
                                 (ds, value) -> {
                                     try {
                                         ds.setValidateConnectionOnBorrow(value);
                                     } catch (SQLException ex) {
                                         throw new RuntimeException(ex);
                                     }
                                 },
                                 "validate connection on borrow");

        configureIntegerProperty(PoolDataSourceImpl::getAbandonedConnectionTimeout,
                                 (ds, value) -> {
                                     try {
                                         ds.setAbandonedConnectionTimeout(value);
                                     } catch (SQLException ex) {
                                         throw new RuntimeException(ex);
                                     }
                                 },
                                 "abandoned connection timeout");

        configureIntegerProperty(PoolDataSourceImpl::getTimeToLiveConnectionTimeout,
                                 (ds, value) -> {
                                     try {
                                         ds.setTimeToLiveConnectionTimeout(value);
                                     } catch (SQLException ex) {
                                         throw new RuntimeException(ex);
                                     }
                                 },
                                 "time to live connection timeout");

        configureIntegerProperty(PoolDataSourceImpl::getInactiveConnectionTimeout,
                                 (ds, value) -> {
                                     try {
                                         ds.setInactiveConnectionTimeout(value);
                                     } catch (SQLException ex) {
                                         throw new RuntimeException(ex);
                                     }
                                 },
                                 "inactive connection timeout");

        configureIntegerProperty(PoolDataSourceImpl::getTimeoutCheckInterval,
                                 (ds, value) -> {
                                     try {
                                         ds.setTimeoutCheckInterval(value);
                                     } catch (SQLException ex) {
                                         throw new RuntimeException(ex);
                                     }
                                 },
                                 "timeout check interval");

        configureIntegerProperty(PoolDataSourceImpl::getMaxStatements,
                                 (ds, value) -> {
                                     try {
                                         ds.setMaxStatements(value);
                                     } catch (SQLException ex) {
                                         throw new RuntimeException(ex);
                                     }
                                 },
                                 "max statements");

        /*
          configureLongProperty(PoolDataSourceImpl::getConnectionWaitDurationInMillis,
          (ds, value) -> {
          try {
          ds.setConnectionWaitDurationInMillis(value);
          } catch (SQLException ex) {
          throw new RuntimeException(ex);
          }
          },
          "connection wait duration in millis");
        */

        configureLongProperty(PoolDataSourceImpl::getMaxConnectionReuseTime,
                              (ds, value) -> {
                                  try {
                                      ds.setMaxConnectionReuseTime(value);
                                  } catch (SQLException ex) {
                                      throw new RuntimeException(ex);
                                  }
                              },
                              "max connection reuse time");

        configureIntegerProperty(PoolDataSourceImpl::getSecondsToTrustIdleConnection,
                                 (ds, value) -> {
                                     try {
                                         ds.setSecondsToTrustIdleConnection(value);
                                     } catch (SQLException ex) {
                                         throw new RuntimeException(ex);
                                     }
                                 },
                                 "seconds to trust idle connection");

        configureIntegerProperty(PoolDataSourceImpl::getConnectionValidationTimeout,
                                 (ds, value) -> {
                                     try {
                                         ds.setConnectionValidationTimeout(value);
                                     } catch (SQLException ex) {
                                         throw new RuntimeException(ex);
                                     }
                                 },
                                 "connection validation timeout");
    }

    void close() {
        synchronized(this) {
            state = State.CLOSED;
        }
    }
}    
