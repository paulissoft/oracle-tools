package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.sql.SQLException;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class PoolDataSourceHikari extends HikariDataSource {

    private interface ToOverride {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;
    }

    @Delegate(types=HikariDataSource.class, excludes=ToOverride.class)
    private CommonPoolDataSourceHikari commonPoolDataSourceHikari = null;

    public PoolDataSourceHikari() {
        
    }

    public Connection getConnection() throws SQLException {
        return null;
    }

    public Connection getConnection(String username, String password) throws SQLException {
        return null;
    }
}
