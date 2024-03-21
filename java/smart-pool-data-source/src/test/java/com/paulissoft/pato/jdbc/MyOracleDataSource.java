package com.paulissoft.pato.jdbc;

import java.sql.SQLException;
import lombok.extern.slf4j.Slf4j;
import oracle.ucp.jdbc.PoolDataSourceImpl;


@Slf4j
public class MyOracleDataSource extends PoolDataSourceImpl {

    // Since getPassword is deprecated in PoolDataSourceImpl
    // we need to store it here via setPassword()
    // and return it via getPassword().
    private String password;
    
    public MyOracleDataSource() {
        log.info("MyOracleDataSource()");
        log.info("getURL(): {}", getURL());
        log.info("getMaxPoolSize(): {}", getMaxPoolSize());
        log.info("getMinPoolSize(): {}", getMinPoolSize());
        log.info("getConnectionPoolName(): {}", getConnectionPoolName());
        log.info("getUser(): {}", getUser());
    }

    @Override
    public void setURL(java.lang.String jdbcUrl) throws SQLException {
        log.info("setURL({})", jdbcUrl);
        super.setURL(jdbcUrl);
    }

    @Override
    public void setMaxPoolSize(int maxPoolSize) throws SQLException {
        log.info("setMaxPoolSize({})", maxPoolSize);
        super.setMaxPoolSize(maxPoolSize);
    }

    @Override
    public void setMinPoolSize(int minPoolSize) throws SQLException {
        log.info("setMinPoolSize({})", minPoolSize);
        super.setMinPoolSize(minPoolSize);
    }

    @Override
    public void setConnectionPoolName(java.lang.String poolName) throws SQLException {
        log.info("setConnectionPoolName({})", poolName);
        super.setConnectionPoolName(poolName);
    }

    @Override
    public void setUser(java.lang.String username) throws SQLException {
        log.info("setUser({})", username);
        super.setUser(username);
    }

    @Override
    public void setPassword(String password) throws SQLException {
        log.info("setPassword({})", password);
        super.setPassword(password);
        this.password = password;
    }

    @Override
    public String getPassword() {
        log.info("getPassword()");
        return password;
    }
}
