package com.paulissoft.pato.jdbc;

import java.sql.Driver;
import javax.sql.DataSource;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.pool.HikariPool;
import java.sql.SQLException;
import javax.sql.DataSource;
import org.springframework.beans.DirectFieldAccessor;    
import java.util.Hashtable;

public class SimplePoolDataSourceHikari extends HikariDataSource implements SimplePoolDataSource {

    public static final String AUTO_COMMIT = "auto-commit";

    public static final String CONNECTION_TIMEOUT = "connection-timeout";

    public static final String IDLE_TIMEOUT = "idle-timeout";

    public static final String MAX_LIFETIME = "max-lifetime";

    public static final String CONNECTION_TEST_QUERY = "connection-test-query";

    public static final String INITIALIZATION_FAIL_TIMEOUT = "initialization-fail-timeout";

    public static final String ISOLATE_INTERNAL_QUERIES = "isolate-internal-queries";

    public static final String ALLOW_POOL_SUSPENSION = "allow-pool-suspension";

    public static final String READ_ONLY = "read-only";

    public static final String REGISTER_MBEANS = "register-mbeans";

    public static final String VALIDATION_TIMEOUT = "validation-timeout";

    public static final String LEAK_DETECTION_THRESHOLD = "leak-detection-threshold";
    
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
            AUTO_COMMIT,
            CONNECTION_TIMEOUT,
            IDLE_TIMEOUT,
            MAX_LIFETIME,
            CONNECTION_TEST_QUERY,
            INITIALIZATION_FAIL_TIMEOUT,
            ISOLATE_INTERNAL_QUERIES,
            ALLOW_POOL_SUSPENSION,
            READ_ONLY,
            REGISTER_MBEANS,
            VALIDATION_TIMEOUT,
            LEAK_DETECTION_THRESHOLD };

    // get common pool data source proerties like the ones define above
    public Hashtable<String, Object> getProperties() {
        final Hashtable<String, Object> properties = new Hashtable<>(propertyNames.length);
        
        for (String propertyName: propertyNames) {
            Object value;
            
            switch(propertyName) {
            case CLASS:
                value = getClass().getName();
                break;
                
            case CONNECTION_FACTORY_CLASS_NAME:
                value = getDataSourceClassName();
                if (value == null) {
                    value = getDriverClassName();
                }
                break;
                
            case URL:
                value = getJdbcUrl();
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

            case AUTO_COMMIT:
                value = isAutoCommit();
                break;
                
            case CONNECTION_TIMEOUT:
                value = getConnectionTimeout();
                break;
                
            case IDLE_TIMEOUT:
                value = getIdleTimeout();
                break;
                
            case MAX_LIFETIME:
                value = getMaxLifetime();
                break;
                
            case CONNECTION_TEST_QUERY:
                value = getConnectionTestQuery();
                break;
                
            case INITIALIZATION_FAIL_TIMEOUT:
                value = getInitializationFailTimeout();
                break;
                
            case ISOLATE_INTERNAL_QUERIES:
                value = isIsolateInternalQueries();
                break;
                
            case ALLOW_POOL_SUSPENSION:
                value = isAllowPoolSuspension();
                break;
                
            case READ_ONLY:
                value = isReadOnly();
                break;
                
            case REGISTER_MBEANS:
                value = isRegisterMbeans();
                break;
                
            case VALIDATION_TIMEOUT:
                value = getValidationTimeout();
                break;
                
            case LEAK_DETECTION_THRESHOLD:
                value = getLeakDetectionThreshold();
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

    // set common pool data source proerties like the ones define above
    public void setProperties(final Hashtable<String, Object> properties) throws SQLException {
        for (String propertyName: propertyNames) {
            final Object value = properties.get(propertyName);
            
            switch(propertyName) {
            case CLASS:
                break;
                
            case CONNECTION_FACTORY_CLASS_NAME:
                try {
                    if (DataSource.class.isAssignableFrom(Class.forName((String)value))) {
                        setDataSourceClassName((String)value);
                    } else if (Driver.class.isAssignableFrom(Class.forName((String)value))) {
                        setDriverClassName((String)value);
                    }
                } catch(ClassNotFoundException ex) {
                    ; // ignore
                }
                break;
                
            case URL:
                setJdbcUrl((String)value);
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

            case AUTO_COMMIT:
                setAutoCommit(Boolean.valueOf(value.toString()));
                break;
                
            case CONNECTION_TIMEOUT:
                setConnectionTimeout(Long.valueOf(value.toString()));
                break;
                
            case IDLE_TIMEOUT:
                setIdleTimeout(Long.valueOf(value.toString()));
                break;
                
            case MAX_LIFETIME:
                setMaxLifetime(Long.valueOf(value.toString()));
                break;
                
            case CONNECTION_TEST_QUERY:
                setConnectionTestQuery((String)value);
                break;
                
            case INITIALIZATION_FAIL_TIMEOUT:
                setInitializationFailTimeout(Long.valueOf(value.toString()));
                break;
                
            case ISOLATE_INTERNAL_QUERIES:
                setIsolateInternalQueries(Boolean.valueOf(value.toString()));
                break;
                
            case ALLOW_POOL_SUSPENSION:
                setAllowPoolSuspension(Boolean.valueOf(value.toString()));
                break;
                
            case READ_ONLY:
                setReadOnly(Boolean.valueOf(value.toString()));
                break;
                
            case REGISTER_MBEANS:
                setRegisterMbeans(Boolean.valueOf(value.toString()));
                break;
                
            case VALIDATION_TIMEOUT:
                setValidationTimeout(Long.valueOf(value.toString()));
                break;
                
            case LEAK_DETECTION_THRESHOLD:
                setLeakDetectionThreshold(Long.valueOf(value.toString()));
                break;
                
            default:
                break;
            }
        }
    }
        
    // HikariCP does NOT know of an initial pool size
    public int getInitialPoolSize() {
        return -1;
    }

    public void setInitialPoolSize(int initialPoolSize) {
        ;
    }

    // HikariCP does NOT know of a minimum pool size but minimumIdle seems to be the equivalent
    public int getMinPoolSize() {
        return getMinimumIdle();
    }

    public void setMinPoolSize(int minPoolSize) {
        setMinimumIdle(minPoolSize);
    }        

    public int getMaxPoolSize() {
        return getMaxPoolSize();
    }

    public void setMaxPoolSize(int maxPoolSize) {
        setMaximumPoolSize(maxPoolSize);
    }
    
    // https://stackoverflow.com/questions/40784965/how-to-get-the-number-of-active-connections-for-hikaricp
    private HikariPool getHikariPool() {
        return (HikariPool) new DirectFieldAccessor(this).getPropertyValue("pool");
    }

    public int getActiveConnections() {
        try {
            return getHikariPool().getActiveConnections();
        } catch (NullPointerException ex) {
            return -1;
        }
    }

    public int getIdleConnections() {
        try {
            return getHikariPool().getIdleConnections();
        } catch (NullPointerException ex) {
            return -1;
        }
    }

    public int getTotalConnections() {
        try {
            return getHikariPool().getTotalConnections();
        } catch (NullPointerException ex) {
            return -1;
        }
    }
}
