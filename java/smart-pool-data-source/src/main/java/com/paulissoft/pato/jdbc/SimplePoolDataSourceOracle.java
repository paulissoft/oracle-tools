package com.paulissoft.pato.jdbc;

import java.sql.SQLException;
import oracle.ucp.jdbc.PoolDataSourceImpl;
import java.util.Hashtable;


public class SimplePoolDataSourceOracle extends PoolDataSourceImpl implements SimplePoolDataSource {

    public static final String VALIDATE_CONNECTION_ON_BORROW = "validate-connection-on-borrow";
    
    public static final String ABANDONED_CONNECTION_TIMEOUT = "abandoned-connection-timeout";
    
    public static final String TIME_TO_LIVE_CONNECTION_TIMEOUT = "time-to-live-connection-timeout";
    
    public static final String INACTIVE_CONNECTION_TIMEOUT = "inactive-connection-timeout";
    
    public static final String TIMEOUT_CHECK_INTERVAL = "timeout-check-interval";
    
    public static final String MAX_STATEMENTS = "max-statements";
    
    public static final String CONNECTION_WAIT_TIMEOUT = "connection-wait-timeout";
    
    public static final String MAX_CONNECTION_REUSE_TIME = "max-connection-reuse-time";
    
    public static final String SECONDS_TO_TRUST_IDLE_CONNECTION = "seconds-to-trust-idle-connection";
    
    public static final String CONNECTION_VALIDATION_TIMEOUT = "connection-validation-timeout";

    private static final String[] propertyNames = new String[] { /* common properties */ CLASS,
            CONNECTION_FACTORY_CLASS_NAME,        
            URL,
            /* both username and password are supplied in SmartPoolDataSource constructors */
            // USERNAME,    
            // PASSWORD,    
            POOL_NAME,
            INITIAL_POOL_SIZE,
            MIN_POOL_SIZE,
            MAX_POOL_SIZE,
            /* specific properties */
            VALIDATE_CONNECTION_ON_BORROW,
            ABANDONED_CONNECTION_TIMEOUT,
            TIME_TO_LIVE_CONNECTION_TIMEOUT,
            INACTIVE_CONNECTION_TIMEOUT,
            TIMEOUT_CHECK_INTERVAL,
            MAX_STATEMENTS,
            CONNECTION_WAIT_TIMEOUT,
            MAX_CONNECTION_REUSE_TIME,
            SECONDS_TO_TRUST_IDLE_CONNECTION,
            CONNECTION_VALIDATION_TIMEOUT
    };

    // get common pool data source properties like the ones define above
    public Hashtable<String, Object> getProperties() {
        final Hashtable<String, Object> properties = new Hashtable<>(propertyNames.length);
        
        for (String propertyName: propertyNames) {
            Object value;
            
            switch(propertyName) {
            case CLASS:
                value = getClass().getName();
                break;
                
            case CONNECTION_FACTORY_CLASS_NAME:
                value = getConnectionFactoryClassName();
                break;
                
            case URL:
                value = getURL();
                break;
                
            case POOL_NAME:
                value = getPoolName();
                break;
                
            case INITIAL_POOL_SIZE:
                value = getInitialPoolSize();
                break;
                
            case MIN_POOL_SIZE:
                value = getMinPoolSize();
                break;
                
            case MAX_POOL_SIZE:
                value = getMaxPoolSize();
                break;

            case VALIDATE_CONNECTION_ON_BORROW:
                value = getValidateConnectionOnBorrow();
                break;
                
            case ABANDONED_CONNECTION_TIMEOUT:
                value = getAbandonedConnectionTimeout();
                break;
                
            case TIME_TO_LIVE_CONNECTION_TIMEOUT:
                value = getTimeToLiveConnectionTimeout();
                break;
                
            case INACTIVE_CONNECTION_TIMEOUT:
                value = getInactiveConnectionTimeout();
                break;
                
            case TIMEOUT_CHECK_INTERVAL:
                value = getTimeoutCheckInterval();
                break;
                
            case MAX_STATEMENTS:
                value = getMaxStatements();
                break;
                
            case CONNECTION_WAIT_TIMEOUT:
                value = getConnectionWaitTimeout();
                break;
                
            case MAX_CONNECTION_REUSE_TIME:
                value = getMaxConnectionReuseTime();
                break;
                
            case SECONDS_TO_TRUST_IDLE_CONNECTION:
                value = getSecondsToTrustIdleConnection();
                break;
                
            case CONNECTION_VALIDATION_TIMEOUT:
                value = getConnectionValidationTimeout();
                break;
                    
            default:
                value = null;
                break;
            }
            if (value != null) {
                properties.put(propertyName, value);
            }
        }
        
        return properties;
    }

    // set common pool data source properties like the ones define above
    public void setProperties(final Hashtable<String, Object> properties) throws SQLException {
        for (String propertyName: propertyNames) {
            final Object value = properties.get(propertyName);

            if (value == null) {
                continue;
            }
            
            switch(propertyName) {
            case CLASS:
                break;
                
            case CONNECTION_FACTORY_CLASS_NAME:                
                setConnectionFactoryClassName((String)value);
                break;
                
            case URL:
                setURL((String)value);
                break;
                
            case POOL_NAME:
                setPoolName((String)value);
                break;
                
            case INITIAL_POOL_SIZE:
                setInitialPoolSize(Integer.valueOf(value.toString())); // value can be either a string or integer
                break;
                
            case MIN_POOL_SIZE:
                setMinPoolSize(Integer.valueOf(value.toString()));
                break;
                
            case MAX_POOL_SIZE:
                setMaxPoolSize(Integer.valueOf(value.toString()));
                break;

            case VALIDATE_CONNECTION_ON_BORROW:
                setValidateConnectionOnBorrow(Boolean.valueOf(value.toString()));
                break;
                
            case ABANDONED_CONNECTION_TIMEOUT:
                setAbandonedConnectionTimeout(Integer.valueOf(value.toString()));
                break;
                
            case TIME_TO_LIVE_CONNECTION_TIMEOUT:
                setTimeToLiveConnectionTimeout(Integer.valueOf(value.toString()));
                break;
                
            case INACTIVE_CONNECTION_TIMEOUT:
                setInactiveConnectionTimeout(Integer.valueOf(value.toString()));
                break;
                
            case TIMEOUT_CHECK_INTERVAL:
                setTimeoutCheckInterval(Integer.valueOf(value.toString()));
                break;
                
            case MAX_STATEMENTS:
                setMaxStatements(Integer.valueOf(value.toString()));
                break;
                
            case CONNECTION_WAIT_TIMEOUT:
                setConnectionWaitTimeout(Integer.valueOf(value.toString()));
                break;
                
            case MAX_CONNECTION_REUSE_TIME:
                setMaxConnectionReuseTime(Integer.valueOf(value.toString()));
                break;
                
            case SECONDS_TO_TRUST_IDLE_CONNECTION:
                setSecondsToTrustIdleConnection(Integer.valueOf(value.toString()));
                break;
                
            case CONNECTION_VALIDATION_TIMEOUT:
                setConnectionValidationTimeout(Integer.valueOf(value.toString()));
                break;
                
            default:
                break;
            }
        }
    }
        
    public String getPoolName() {
        return getConnectionPoolName();
    }

    public void setPoolName(String poolName) throws SQLException {
        setConnectionPoolName(poolName);
    }

    public void setUrl(String url) throws SQLException {
        setURL(url);
    }

    public String getUsername() {
        return getUser();
    }

    public void setUsername(String username) throws SQLException {
        setUser(username);
    }

    public long getConnectionTimeout() { // milliseconds
        return 1000 * getConnectionWaitTimeout();
    }

    // connection statistics
    
    public int getActiveConnections() {
        return getBorrowedConnectionsCount();
    }

    public int getIdleConnections() {
        return getAvailableConnectionsCount();
    }

    public int getTotalConnections() {
        return getActiveConnections() + getIdleConnections();
    }

    public void close() {
        ; // nothing
    }
}
