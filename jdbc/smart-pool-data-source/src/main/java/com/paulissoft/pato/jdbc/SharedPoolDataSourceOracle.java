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
    void initialize() {
        super.initialize();

        initializeIntProperty(PoolDataSourceImpl::getInitialPoolSize,
                              (ds, value) -> {
                                  try {
                                      ds.setInitialPoolSize(value);
                                  } catch (SQLException ex) {
                                      throw new RuntimeException(ex);
                                  }
                              },
                              "initial pool size",
                              true);

        initializeIntProperty(PoolDataSourceImpl::getMinPoolSize,
                              (ds, value) -> {
                                  try {
                                      ds.setMinPoolSize(value);
                                  } catch (SQLException ex) {
                                      throw new RuntimeException(ex);
                                  }
                              },
                              "min pool size",
                              true);

        initializeIntProperty(PoolDataSourceImpl::getMaxPoolSize,
                              (ds, value) -> {
                                  try {
                                      ds.setMaxPoolSize(value);
                                  } catch (SQLException ex) {
                                      throw new RuntimeException(ex);
                                  }
                              },
                              "max pool size",
                              true);

        // properties that may NOT differ, i.e. must be common

        // just a check: no need to invoke ds.setUser() since that has been done already via SmartPoolDataSourceOracle.setUser().
        determineStringProperty(PoolDataSourceImpl::getUser, "username");

        initializeStringProperty(PoolDataSourceImpl::getURL,
                                 (ds, value) -> {
                                     try {
                                         ds.setURL(value);
                                     } catch (SQLException ex) {
                                         throw new RuntimeException(ex);
                                     }
                                 },
                                 "URL");

        initializeStringProperty(PoolDataSourceImpl::getConnectionFactoryClassName,
                                 (ds, value) -> {
                                     try {
                                         ds.setConnectionFactoryClassName(value);
                                     } catch (SQLException ex) {
                                         throw new RuntimeException(ex);
                                     }
                                 },
                                 "connection factory class name");

        initializeBooleanProperty(PoolDataSourceImpl::getValidateConnectionOnBorrow,
                                  (ds, value) -> {
                                      try {
                                          ds.setValidateConnectionOnBorrow(value);
                                      } catch (SQLException ex) {
                                          throw new RuntimeException(ex);
                                      }
                                  },
                                  "validate connection on borrow");

        initializeIntProperty(PoolDataSourceImpl::getAbandonedConnectionTimeout,
                              (ds, value) -> {
                                  try {
                                      ds.setAbandonedConnectionTimeout(value);
                                  } catch (SQLException ex) {
                                      throw new RuntimeException(ex);
                                  }
                              },
                              "abandoned connection timeout");

        initializeIntProperty(PoolDataSourceImpl::getTimeToLiveConnectionTimeout,
                              (ds, value) -> {
                                  try {
                                      ds.setTimeToLiveConnectionTimeout(value);
                                  } catch (SQLException ex) {
                                      throw new RuntimeException(ex);
                                  }
                              },
                              "time to live connection timeout");

        initializeIntProperty(PoolDataSourceImpl::getInactiveConnectionTimeout,
                              (ds, value) -> {
                                  try {
                                      ds.setInactiveConnectionTimeout(value);
                                  } catch (SQLException ex) {
                                      throw new RuntimeException(ex);
                                  }
                              },
                              "inactive connection timeout");

        initializeIntProperty(PoolDataSourceImpl::getTimeoutCheckInterval,
                              (ds, value) -> {
                                  try {
                                      ds.setTimeoutCheckInterval(value);
                                  } catch (SQLException ex) {
                                      throw new RuntimeException(ex);
                                  }
                              },
                              "timeout check interval");

        initializeIntProperty(PoolDataSourceImpl::getMaxStatements,
                              (ds, value) -> {
                                  try {
                                      ds.setMaxStatements(value);
                                  } catch (SQLException ex) {
                                      throw new RuntimeException(ex);
                                  }
                              },
                              "max statements");

        /*
          initializeLongProperty(PoolDataSourceImpl::getConnectionWaitDurationInMillis,
          (ds, value) -> {
          try {
          ds.setConnectionWaitDurationInMillis(value);
          } catch (SQLException ex) {
          throw new RuntimeException(ex);
          }
          },
          "connection wait duration in millis");
        */

        initializeLongProperty(PoolDataSourceImpl::getMaxConnectionReuseTime,
                               (ds, value) -> {
                                   try {
                                       ds.setMaxConnectionReuseTime(value);
                                   } catch (SQLException ex) {
                                       throw new RuntimeException(ex);
                                   }
                               },
                               "max connection reuse time");

        initializeIntProperty(PoolDataSourceImpl::getSecondsToTrustIdleConnection,
                              (ds, value) -> {
                                  try {
                                      ds.setSecondsToTrustIdleConnection(value);
                                  } catch (SQLException ex) {
                                      throw new RuntimeException(ex);
                                  }
                              },
                              "seconds to trust idle connection");

        initializeIntProperty(PoolDataSourceImpl::getConnectionValidationTimeout,
                              (ds, value) -> {
                                  try {
                                      ds.setConnectionValidationTimeout(value);
                                  } catch (SQLException ex) {
                                      throw new RuntimeException(ex);
                                  }
                              },
                              "connection validation timeout");
        
        initializeBooleanProperty(PoolDataSourceImpl::getFastConnectionFailoverEnabled,
                                  (ds, value) -> {
                                      try {
                                          ds.setFastConnectionFailoverEnabled(value);
                                      } catch (SQLException ex) {
                                          throw new RuntimeException(ex);
                                      }
                                  },
                                  "fast connection failover enabled");

        initializeIntProperty(PoolDataSourceImpl::getMaxIdleTime,
                              (ds, value) -> {
                                  try {
                                      ds.setMaxIdleTime(value);
                                  } catch (SQLException ex) {
                                      throw new RuntimeException(ex);
                                  }
                              },
                              "max idle time");

        initializeStringProperty(PoolDataSourceImpl::getDataSourceName,
                                 (ds, value) -> {
                                     try {
                                         ds.setDataSourceName(value);
                                     } catch (SQLException ex) {
                                         throw new RuntimeException(ex);
                                     }
                                 },
                                 "data source name");

        initializeIntProperty(PoolDataSourceImpl::getQueryTimeout,
                              (ds, value) -> {
                                  try {
                                      ds.setQueryTimeout(value);
                                  } catch (SQLException ex) {
                                      throw new RuntimeException(ex);
                                  }
                              },
                              "query timeout");

        /*
          initializeBooleanProperty(PoolDataSourceImpl::getReadOnlyInstanceAllowed,
          (ds, value) -> {
          try {
          ds.setReadOnlyInstanceAllowed(value);
          } catch (SQLException ex) {
          throw new RuntimeException(ex);
          }
          },
          "read only instance allowed");
        */

        initializeStringProperty(PoolDataSourceImpl::getONSConfiguration,
                                 PoolDataSourceImpl::setONSConfiguration,
                                 "ONS configuration");

        initializeIntProperty(PoolDataSourceImpl::getMaxConnectionReuseCount,
                              (ds, value) -> {
                                  try {
                                      ds.setMaxConnectionReuseCount(value);
                                  } catch (SQLException ex) {
                                      throw new RuntimeException(ex);
                                  }
                              },
                              "max connection reuse count");
    }

    void close() {
        synchronized(this) {
            state = State.CLOSED;
        }
    }
}    
