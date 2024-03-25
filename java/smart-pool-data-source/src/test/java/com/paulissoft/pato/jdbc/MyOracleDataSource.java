package com.paulissoft.pato.jdbc;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.sql.SQLException;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class MyOracleDataSource extends CombiPoolDataSourceOracle {

    // Since getPassword is deprecated in PoolDataSourceImpl
    // we need to store it here via setPassword()
    // and return it via getPassword().
    private String password;

    public MyOracleDataSource() {
        // super(); /* unnecessary call */
        log.info("MyOracleDataSource()");
    }

    @Override
    public void setUrl(java.lang.String jdbcUrl) throws SQLException {
        log.info("setUrl({})", jdbcUrl);
        super.setUrl(jdbcUrl);
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
    public void setUsername(java.lang.String username) throws SQLException {
        log.info("setUsername({})", username);
        super.setUsername(username);
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

    @PostConstruct
    @Override
    public void init() {
        super.init();
    }

    @PreDestroy
    @Override
    public void done() {
        super.done();
    }
}
