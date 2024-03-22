package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import javax.sql.DataSource;
import java.sql.SQLException;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;
import lombok.NonNull;


@Slf4j
public class PoolDataSourceHikari extends BasePoolDataSourceHikari {

    private interface ToOverride {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;
    }

    @Delegate(types=HikariDataSource.class, excludes=ToOverride.class)
    private CommonPoolDataSourceHikari commonPoolDataSourceHikari = null;

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

    public void join(final HikariDataSource ds) {
        join((CommonPoolDataSourceHikari)ds);
    }
    
    public void leave(final HikariDataSource ds) {
        leave((CommonPoolDataSourceHikari)ds);
    }

    public void close() {
        leave(commonPoolDataSourceHikari);
    }

    private void join(final CommonPoolDataSourceHikari pds) {
        try {
            pds.join(this);
        } finally {
            commonPoolDataSourceHikari = pds;
        }
    }

    public void leave(final CommonPoolDataSourceHikari pds) {
        try {
            pds.leave(this);
        } finally {
            commonPoolDataSourceHikari = null;
        }
    }
}
