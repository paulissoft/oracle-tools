package com.paulissoft.pato.jdbc;

import java.sql.Driver;
import javax.sql.DataSource;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.pool.HikariPool;
import javax.sql.DataSource;
import org.springframework.beans.DirectFieldAccessor;    

public class SimplePoolDataSourceHikari extends HikariDataSource implements SimplePoolDataSource {

    // get common pool data source properties like the ones define above
    public PoolDataSourceConfiguration getPoolDataSourceConfiguration() {
        return PoolDataSourceConfigurationHikari
            .builder()
            .driverClassName(getDriverClassName())
            .url(getJdbcUrl())
            .username(getUsername())
            .password(getPassword())
            .type(SimplePoolDataSourceHikari.class.getName())
            .poolName(getPoolName())
            .maximumPoolSize(getMaximumPoolSize())
            .minimumIdle(getMinimumIdle())
            .autoCommit(isAutoCommit())
            .connectionTimeout(getConnectionTimeout())
            .idleTimeout(getIdleTimeout())
            .maxLifetime(getMaxLifetime())
            .connectionTestQuery(getConnectionTestQuery())
            .initializationFailTimeout(getInitializationFailTimeout())
            .isolateInternalQueries(isIsolateInternalQueries())
            .allowPoolSuspension(isAllowPoolSuspension())
            .readOnly(isReadOnly())
            .registerMbeans(isRegisterMbeans())
            .validationTimeout(getValidationTimeout())
            .leakDetectionThreshold(getLeakDetectionThreshold())
            .build();
    }
        
    public void setUrl(String url) {
        setJdbcUrl(url);
    }

    public void setConnectionFactoryClassName(String value) {
        try {
            if (DataSource.class.isAssignableFrom(Class.forName(value))) {
                setDataSourceClassName(value);
            } else if (Driver.class.isAssignableFrom(Class.forName(value))) {
                setDriverClassName(value);
            }
        } catch(ClassNotFoundException ex) {
            ; // ignore
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
        return getMaximumPoolSize();
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
