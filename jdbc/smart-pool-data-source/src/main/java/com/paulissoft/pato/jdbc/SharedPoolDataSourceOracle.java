package com.paulissoft.pato.jdbc;

import java.sql.SQLException;
import oracle.ucp.jdbc.PoolDataSourceImpl;


// a package accessible class
class SharedPoolDataSourceOracle extends SharedPoolDataSource<PoolDataSourceImpl> {
    private static final String USERNAMES_ERROR = "Not all usernames are the same and not null: %s.";

    private static final String DATA_SOURCE_CLASS_NAMES_ERROR = "Not all data source class names are the same: %s.";

    static final boolean useConnectionLabelingCallback = Boolean.valueOf(System.getProperty("SmartConnectionLabelingCallbackOracle", "false"));    

    // constructor
    SharedPoolDataSourceOracle() {
        super(new PoolDataSourceImpl());
    }

    @Override
    void initialize() {
        super.initialize();

        // Can not use initialize<type>Property since the UCP setter raises an SQLException.
        
        try {
            var valueInitialPoolSize = determineIntProperty(PoolDataSourceImpl::getInitialPoolSize,
                                                            "initial pool size",
                                                            true);

            if (valueInitialPoolSize != null) {
                ds.setInitialPoolSize(valueInitialPoolSize.get());
            }

            var valueMinPoolSize = determineIntProperty(PoolDataSourceImpl::getMinPoolSize,
                                                        "min pool size",
                                                        true);

            if (valueMinPoolSize != null) {
                ds.setMinPoolSize(valueMinPoolSize.get());
            }

            var valueMaxPoolSize = determineIntProperty(PoolDataSourceImpl::getMaxPoolSize,
                                                        "max pool size",
                                                        true);

            if (valueMaxPoolSize != null) {
                ds.setMaxPoolSize(valueMaxPoolSize.get());
            }
            
            // properties that may NOT differ, i.e. must be common

            // just a check: no need to invoke ds.setUser() since that has been done already via SmartPoolDataSourceOracle.setUser().
            checkStringProperty(PoolDataSourceImpl::getUser, "username");

            var valueURL = determineStringProperty(PoolDataSourceImpl::getURL,
                                                   "URL");

            if (valueURL != null) {
                ds.setURL(valueURL.isPresent() ? valueURL.get() : null);
            }

            var valueConnectionFactoryClassName = determineStringProperty(PoolDataSourceImpl::getConnectionFactoryClassName,
                                                                          "connection factory class name");

            if (valueConnectionFactoryClassName != null) {
                ds.setConnectionFactoryClassName(valueConnectionFactoryClassName.isPresent() ? valueConnectionFactoryClassName.get() : null);
            }

            var valueValidateConnectionOnBorrow = determineBooleanProperty(PoolDataSourceImpl::getValidateConnectionOnBorrow,
                                                                           "validate connection on borrow");

            if (valueValidateConnectionOnBorrow != null) {
                ds.setValidateConnectionOnBorrow(valueValidateConnectionOnBorrow.isPresent() ? valueValidateConnectionOnBorrow.get() : null);
            }

            if (SharedPoolDataSourceOracle.useConnectionLabelingCallback) {
                var valueSQLForValidateConnection = determineStringProperty(PoolDataSourceImpl::getSQLForValidateConnection,
                                                                            "SQL for validate connection");
                
                if (valueSQLForValidateConnection != null) {
                    ds.setSQLForValidateConnection(valueSQLForValidateConnection.isPresent() ? valueSQLForValidateConnection.get() : null);
                }
            }

            var valueAbandonedConnectionTimeout = determineIntProperty(PoolDataSourceImpl::getAbandonedConnectionTimeout,
                                                                       "abandoned connection timeout");

            if (valueAbandonedConnectionTimeout != null) {
                ds.setAbandonedConnectionTimeout(valueAbandonedConnectionTimeout.isPresent() ? valueAbandonedConnectionTimeout.get() : null);
            }

            var valueTimeToLiveConnectionTimeout = determineIntProperty(PoolDataSourceImpl::getTimeToLiveConnectionTimeout,
                                                                        "time to live connection timeout");

            if (valueTimeToLiveConnectionTimeout != null) {
                ds.setTimeToLiveConnectionTimeout(valueTimeToLiveConnectionTimeout.isPresent() ? valueTimeToLiveConnectionTimeout.get() : null);
            }

            var valueInactiveConnectionTimeout = determineIntProperty(PoolDataSourceImpl::getInactiveConnectionTimeout,
                                                                      "inactive connection timeout");

            if (valueInactiveConnectionTimeout != null) {
                ds.setInactiveConnectionTimeout(valueInactiveConnectionTimeout.isPresent() ? valueInactiveConnectionTimeout.get() : null);
            }

            var valueTimeoutCheckInterval = determineIntProperty(PoolDataSourceImpl::getTimeoutCheckInterval,
                                                                 "timeout check interval");

            if (valueTimeoutCheckInterval != null) {
                ds.setTimeoutCheckInterval(valueTimeoutCheckInterval.isPresent() ? valueTimeoutCheckInterval.get() : null);
            }

            var valueMaxStatements = determineIntProperty(PoolDataSourceImpl::getMaxStatements,
                                                          "max statements");

            if (valueMaxStatements != null) {
                ds.setMaxStatements(valueMaxStatements.isPresent() ? valueMaxStatements.get() : null);
            }

            var valueMaxConnectionReuseTime = determineLongProperty(PoolDataSourceImpl::getMaxConnectionReuseTime,
                                                                    "max connection reuse time");

            if (valueMaxConnectionReuseTime != null) {
                ds.setMaxConnectionReuseTime(valueMaxConnectionReuseTime.isPresent() ? valueMaxConnectionReuseTime.get() : null);
            }

            var valueSecondsToTrustIdleConnection = determineIntProperty(PoolDataSourceImpl::getSecondsToTrustIdleConnection,
                                                                         "seconds to trust idle connection");

            if (valueSecondsToTrustIdleConnection != null) {
                ds.setSecondsToTrustIdleConnection(valueSecondsToTrustIdleConnection.isPresent() ? valueSecondsToTrustIdleConnection.get() : null);
            }

            var valueConnectionValidationTimeout = determineIntProperty(PoolDataSourceImpl::getConnectionValidationTimeout,
                                                                        "connection validation timeout");

            if (valueConnectionValidationTimeout != null) {
                ds.setConnectionValidationTimeout(valueConnectionValidationTimeout.isPresent() ? valueConnectionValidationTimeout.get() : null);
            }

            var valueFastConnectionFailoverEnabled = determineBooleanProperty(PoolDataSourceImpl::getFastConnectionFailoverEnabled,
                                                                              "fast connection failover enabled");

            if (valueFastConnectionFailoverEnabled != null) {
                ds.setFastConnectionFailoverEnabled(valueFastConnectionFailoverEnabled.isPresent() ? valueFastConnectionFailoverEnabled.get() : null);
            }

            var valueMaxIdleTime = determineIntProperty(PoolDataSourceImpl::getMaxIdleTime,
                                                        "max idle time");

            if (valueMaxIdleTime != null) {
                ds.setMaxIdleTime(valueMaxIdleTime.isPresent() ? valueMaxIdleTime.get() : null);
            }

            var valueDataSourceName = determineStringProperty(PoolDataSourceImpl::getDataSourceName,
                                                              "data source name");

            if (valueDataSourceName != null) {
                ds.setDataSourceName(valueDataSourceName.isPresent() ? valueDataSourceName.get() : null);
            }

            var valueQueryTimeout = determineIntProperty(PoolDataSourceImpl::getQueryTimeout,
                                                         "query timeout");

            if (valueQueryTimeout != null) {
                ds.setQueryTimeout(valueQueryTimeout.isPresent() ? valueQueryTimeout.get() : null);
            }

            initializeStringProperty(PoolDataSourceImpl::getONSConfiguration,
                                     PoolDataSourceImpl::setONSConfiguration,
                                     "ONS configuration");

            var valueMaxConnectionReuseCount = determineIntProperty(PoolDataSourceImpl::getMaxConnectionReuseCount,
                                                                    "max connection reuse count");

            if (valueMaxConnectionReuseCount != null) {
                ds.setMaxConnectionReuseCount(valueMaxConnectionReuseCount.isPresent() ? valueMaxConnectionReuseCount.get() : null);
            }

            // Deprecated
            /*
            var valueConnectionWaitTimeout = determineIntProperty(PoolDataSourceImpl::getConnectionWaitTimeout,
                                                                  "connection wait timeout");

            if (valueConnectionWaitTimeout != null) {
                ds.setConnectionWaitTimeout(valueConnectionWaitTimeout.isPresent() ? valueConnectionWaitTimeout.get() : null);
            }
            */
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        }
    }

    void close() {
        synchronized(this) {
            state = State.CLOSED;
        }
    }
}    
