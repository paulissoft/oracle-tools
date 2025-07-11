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

        configureIntProperty(PoolDataSourceImpl::getInitialPoolSize,
                             (ds, value) -> {
                                 try {
                                     ds.setInitialPoolSize(value);
                                 } catch (SQLException ex) {
                                     throw new RuntimeException(ex);
                                 }
                             },
                             "initial pool size",
                             true);

        configureIntProperty(PoolDataSourceImpl::getMinPoolSize,
                             (ds, value) -> {
                                 try {
                                     ds.setMinPoolSize(value);
                                 } catch (SQLException ex) {
                                     throw new RuntimeException(ex);
                                 }
                             },
                             "min pool size",
                             true);

        configureIntProperty(PoolDataSourceImpl::getMaxPoolSize,
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
        checkStringProperty(PoolDataSourceImpl::getUser, "username");

        configureStringProperty(PoolDataSourceImpl::getURL,
                                (ds, value) -> {
                                    try {
                                        ds.setURL(value);
                                    } catch (SQLException ex) {
                                        throw new RuntimeException(ex);
                                    }
                                },
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

        configureIntProperty(PoolDataSourceImpl::getAbandonedConnectionTimeout,
                             (ds, value) -> {
                                 try {
                                     ds.setAbandonedConnectionTimeout(value);
                                 } catch (SQLException ex) {
                                     throw new RuntimeException(ex);
                                 }
                             },
                             "abandoned connection timeout");

        configureIntProperty(PoolDataSourceImpl::getTimeToLiveConnectionTimeout,
                             (ds, value) -> {
                                 try {
                                     ds.setTimeToLiveConnectionTimeout(value);
                                 } catch (SQLException ex) {
                                     throw new RuntimeException(ex);
                                 }
                             },
                             "time to live connection timeout");

        configureIntProperty(PoolDataSourceImpl::getInactiveConnectionTimeout,
                             (ds, value) -> {
                                 try {
                                     ds.setInactiveConnectionTimeout(value);
                                 } catch (SQLException ex) {
                                     throw new RuntimeException(ex);
                                 }
                             },
                             "inactive connection timeout");

        configureIntProperty(PoolDataSourceImpl::getTimeoutCheckInterval,
                             (ds, value) -> {
                                 try {
                                     ds.setTimeoutCheckInterval(value);
                                 } catch (SQLException ex) {
                                     throw new RuntimeException(ex);
                                 }
                             },
                             "timeout check interval");

        configureIntProperty(PoolDataSourceImpl::getMaxStatements,
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

        configureIntProperty(PoolDataSourceImpl::getSecondsToTrustIdleConnection,
                             (ds, value) -> {
                                 try {
                                     ds.setSecondsToTrustIdleConnection(value);
                                 } catch (SQLException ex) {
                                     throw new RuntimeException(ex);
                                 }
                             },
                             "seconds to trust idle connection");

        configureIntProperty(PoolDataSourceImpl::getConnectionValidationTimeout,
                             (ds, value) -> {
                                 try {
                                     ds.setConnectionValidationTimeout(value);
                                 } catch (SQLException ex) {
                                     throw new RuntimeException(ex);
                                 }
                             },
                             "connection validation timeout");
        
        configureBooleanProperty(PoolDataSourceImpl::getFastConnectionFailoverEnabled,
                                 (ds, value) -> {
                                     try {
                                         ds.setFastConnectionFailoverEnabled(value);
                                     } catch (SQLException ex) {
                                         throw new RuntimeException(ex);
                                     }
                                 },
                                 "fast connection failover enabled");

        configureIntProperty(PoolDataSourceImpl::getMaxIdleTime,
                             (ds, value) -> {
                                 try {
                                     ds.setMaxIdleTime(value);
                                 } catch (SQLException ex) {
                                     throw new RuntimeException(ex);
                                 }
                             },
                             "max idle time");

        configureStringProperty(PoolDataSourceImpl::getDataSourceName,
                                (ds, value) -> {
                                    try {
                                        ds.setDataSourceName(value);
                                    } catch (SQLException ex) {
                                        throw new RuntimeException(ex);
                                    }
                                },
                                "data source name");

        configureIntProperty(PoolDataSourceImpl::getQueryTimeout,
                             (ds, value) -> {
                                 try {
                                     ds.setQueryTimeout(value);
                                 } catch (SQLException ex) {
                                     throw new RuntimeException(ex);
                                 }
                             },
                             "query timeout");

        /*
        configureBooleanProperty(PoolDataSourceImpl::getReadOnlyInstanceAllowed,
                                 (ds, value) -> {
                                     try {
                                         ds.setReadOnlyInstanceAllowed(value);
                                     } catch (SQLException ex) {
                                         throw new RuntimeException(ex);
                                     }
                                 },
                                 "read only instance allowed");
        */

        configureStringProperty(PoolDataSourceImpl::getONSConfiguration,
                                PoolDataSourceImpl::setONSConfiguration,
                                "ONS configuration");

        configureIntProperty(PoolDataSourceImpl::getMaxConnectionReuseCount,
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
