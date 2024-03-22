package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.sql.SQLException;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;
import lombok.NonNull;


@Slf4j
public class PoolDataSourceHikari extends BasePoolDataSourceHikari {

    private interface ToOverride {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;

        // the following methods must be invoked for this instance
        public void setDriverClassName(String driverClassName);
        
        public void setJdbcUrl(String url);

        public void setUsername(String username);
        
        public void setPassword(String password);

        public String getPoolName();
        
        public void setPoolName(String poolName);

        public int getMaximumPoolSize();
        
        public void setMaximumPoolSize(int maximumPoolSize);
        
        public int getMinimumIdle();

        public void setMinimumIdle(int minimumIdle);
        
        public void setDataSourceClassName(String dataSourceClassName);
        
        public void setAutoCommit(boolean autoCommit);
        
        public void setConnectionTimeout(long connectionTimeout);
        
        public void setIdleTimeout(long idleTimeout);
        
        public void setMaxLifetime(long maxLifetime);
        
        public void setConnectionTestQuery(String connectionTestQuery);
        
        public void setInitializationFailTimeout(long initializationFailTimeout);

        public void setIsolateInternalQueries(boolean isolateInternalQueries);
        
        public void setAllowPoolSuspension(boolean allowPoolSuspension);
        
        public void setReadOnly(boolean readOnly);
        
        public void setRegisterMbeans(boolean registerMbeans);
        
        public void setValidationTimeout(long validationTimeout);
        
        public void setLeakDetectionThreshold(long leakDetectionThreshold);
    }

    @Delegate(types=HikariDataSource.class, excludes=ToOverride.class)
    private CommonPoolDataSourceHikari commonPoolDataSourceHikari = null;

    public PoolDataSourceHikari() {
    }
                                
    public PoolDataSourceHikari(String driverClassName,
                                @NonNull String url,
                                @NonNull String username,
                                @NonNull String password,
                                String poolName,
                                int maximumPoolSize,
                                int minimumIdle,
                                String dataSourceClassName,
                                boolean autoCommit,
                                long connectionTimeout,
                                long idleTimeout,
                                long maxLifetime,
                                String connectionTestQuery,
                                long initializationFailTimeout,
                                boolean isolateInternalQueries,
                                boolean allowPoolSuspension,
                                boolean readOnly,
                                boolean registerMbeans,
                                long validationTimeout,
                                long leakDetectionThreshold) {
        super(driverClassName,
              url,
              username,
              password,
              poolName,
              maximumPoolSize,
              minimumIdle,
              dataSourceClassName,
              autoCommit,
              connectionTimeout,
              idleTimeout,
              maxLifetime,
              connectionTestQuery,
              initializationFailTimeout,
              isolateInternalQueries,
              allowPoolSuspension,
              readOnly,
              registerMbeans,
              validationTimeout,
              leakDetectionThreshold);
    }

    public Connection getConnection() throws SQLException {
        return commonPoolDataSourceHikari.getConnection(getUsernameSession1(),
                                                        getPasswordSession1(),
                                                        getUsernameSession2());
    }

    public Connection getConnection(String username, String password) throws SQLException {
        final PoolDataSourceConfiguration poolDataSourceConfiguration =
            new PoolDataSourceConfiguration("", "", username, password);

        final String usernameSession2 = poolDataSourceConfiguration.getSchema();
        // there may be no proxy session at all
        final String usernameSession1 =
            poolDataSourceConfiguration.getProxyUsername() != null
            ? poolDataSourceConfiguration.getProxyUsername()
            : usernameSession2;
        final String passwordSession1 = password;

        return commonPoolDataSourceHikari.getConnection(usernameSession1,
                                                        passwordSession1,
                                                        usernameSession2);
    }

    public void setDriverClassName(String driverClassName) {
        if (commonPoolDataSourceHikari == null) {
            super.setDriverClassName(driverClassName);
        } else {
            commonPoolDataSourceHikari.setDriverClassName(driverClassName);
        }
    }
        
    public void setJdbcUrl(String url) {
        if (commonPoolDataSourceHikari == null) {
            super.setJdbcUrl(url);
        } else {
            commonPoolDataSourceHikari.setJdbcUrl(url);
        }
    }

    public void setUsername(String username) {
        if (commonPoolDataSourceHikari == null) {
            super.setUsername(username);
        } else {
            commonPoolDataSourceHikari.setUsername(username);
        }
    }
        
    public void setPassword(String password) {
        if (commonPoolDataSourceHikari == null) {
            super.setPassword(password);
        } else {
            commonPoolDataSourceHikari.setPassword(password);
        }
    }

    public String getPoolName() {
        if (commonPoolDataSourceHikari == null) {
            return super.getPoolName();
        } else {
            return commonPoolDataSourceHikari.getPoolName();
        }
    }

    public void setPoolName(String poolName) {
        if (commonPoolDataSourceHikari == null) {
            super.setPoolName(poolName);
        } else {
            commonPoolDataSourceHikari.setPoolName(poolName);
        }
    }

    public int getMaximumPoolSize() {
        if (commonPoolDataSourceHikari == null) {
            return super.getMaximumPoolSize();
        } else {
            return commonPoolDataSourceHikari.getMaximumPoolSize();
        }
    }
        
    public void setMaximumPoolSize(int maximumPoolSize) {
        if (commonPoolDataSourceHikari == null) {
            super.setMaximumPoolSize(maximumPoolSize);
        } else {
            commonPoolDataSourceHikari.setMaximumPoolSize(maximumPoolSize);
        }
    }
        
    public int getMinimumIdle() {
        if (commonPoolDataSourceHikari == null) {
            return super.getMinimumIdle();
        } else {
            return commonPoolDataSourceHikari.getMinimumIdle();
        }
    }
        
    public void setMinimumIdle(int minimumIdle) {
        if (commonPoolDataSourceHikari == null) {
            super.setMinimumIdle(minimumIdle);
        } else {
            commonPoolDataSourceHikari.setMinimumIdle(minimumIdle);
        }
    }
        
    public void setDataSourceClassName(String dataSourceClassName) {
        if (commonPoolDataSourceHikari == null) {
            super.setDataSourceClassName(dataSourceClassName);
        } else {
            commonPoolDataSourceHikari.setDataSourceClassName(dataSourceClassName);
        }
    }
        
    public void setAutoCommit(boolean autoCommit) {
        if (commonPoolDataSourceHikari == null) {
            super.setAutoCommit(autoCommit);
        } else {
            commonPoolDataSourceHikari.setAutoCommit(autoCommit);
        }
    }
        
    public void setConnectionTimeout(long connectionTimeout) {
        if (commonPoolDataSourceHikari == null) {
            super.setConnectionTimeout(connectionTimeout);
        } else {
            commonPoolDataSourceHikari.setConnectionTimeout(connectionTimeout);
        }
    }
        
    public void setIdleTimeout(long idleTimeout) {
        if (commonPoolDataSourceHikari == null) {
            super.setIdleTimeout(idleTimeout);
        } else {
            commonPoolDataSourceHikari.setIdleTimeout(idleTimeout);
        }
    }
        
    public void setMaxLifetime(long maxLifetime) {
        if (commonPoolDataSourceHikari == null) {
            super.setMaxLifetime(maxLifetime);
        } else {
            commonPoolDataSourceHikari.setMaxLifetime(maxLifetime);
        }
    }
        
    public void setConnectionTestQuery(String connectionTestQuery) {
        if (commonPoolDataSourceHikari == null) {
            super.setConnectionTestQuery(connectionTestQuery);
        } else {
            commonPoolDataSourceHikari.setConnectionTestQuery(connectionTestQuery);
        }
    }
        
    public void setInitializationFailTimeout(long initializationFailTimeout) {
        if (commonPoolDataSourceHikari == null) {
            super.setInitializationFailTimeout(initializationFailTimeout);
        } else {
            commonPoolDataSourceHikari.setInitializationFailTimeout(initializationFailTimeout);
        }
    }

    public void setIsolateInternalQueries(boolean isolateInternalQueries) {
        if (commonPoolDataSourceHikari == null) {
            super.setIsolateInternalQueries(isolateInternalQueries);
        } else {
            commonPoolDataSourceHikari.setIsolateInternalQueries(isolateInternalQueries);
        }
    }
        
    public void setAllowPoolSuspension(boolean allowPoolSuspension) {
        if (commonPoolDataSourceHikari == null) {
            super.setAllowPoolSuspension(allowPoolSuspension);
        } else {
            commonPoolDataSourceHikari.setAllowPoolSuspension(allowPoolSuspension);
        }
    }
        
    public void setReadOnly(boolean readOnly) {
        if (commonPoolDataSourceHikari == null) {
            super.setReadOnly(readOnly);
        } else {
            commonPoolDataSourceHikari.setReadOnly(readOnly);
        }
    }
        
    public void setRegisterMbeans(boolean registerMbeans) {
        if (commonPoolDataSourceHikari == null) {
            super.setRegisterMbeans(registerMbeans);
        } else {
            commonPoolDataSourceHikari.setRegisterMbeans(registerMbeans);
        }
    }
        
    public void setValidationTimeout(long validationTimeout) {
        if (commonPoolDataSourceHikari == null) {
            super.setValidationTimeout(validationTimeout);
        } else {
            commonPoolDataSourceHikari.setValidationTimeout(validationTimeout);
        }
    }
        
    public void setLeakDetectionThreshold(long leakDetectionThreshold) {
        if (commonPoolDataSourceHikari == null) {
            super.setLeakDetectionThreshold(leakDetectionThreshold);
        } else {
            commonPoolDataSourceHikari.setLeakDetectionThreshold(leakDetectionThreshold);
        }
    }

    /* from the interface */
    
    public void join(final HikariDataSource ds) {
        join((CommonPoolDataSourceHikari)ds);
    }
    
    private void join(final CommonPoolDataSourceHikari pds) {
        if (commonPoolDataSourceHikari != null) {
            return;
        }
        
        try {
            pds.join(this);
        } finally {
            commonPoolDataSourceHikari = pds;
        }
    }

    public void leave(final HikariDataSource ds) {
        leave((CommonPoolDataSourceHikari)ds);
    }

    private void leave(final CommonPoolDataSourceHikari pds) {
        commonPoolDataSourceHikari = null; // this will force getXXX functions to use super.getXXX (see above)
        pds.leave(this);
    }

    @Override
    public void close() {
        // do not invoke super.close() since we did not really use this data source but its delegate
        if (commonPoolDataSourceHikari != null) {
            leave(commonPoolDataSourceHikari);
        }
    }
}
