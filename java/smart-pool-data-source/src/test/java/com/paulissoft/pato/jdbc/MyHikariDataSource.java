package com.paulissoft.pato.jdbc;

import lombok.extern.slf4j.Slf4j;


@Slf4j
public class MyHikariDataSource extends CommonPoolDataSourceHikari {

    // just add a dummy constructor and override methods to see the logging

    public MyHikariDataSource() {
        log.info("MyHikariDataSource()");
        log.info("getJdbcUrl(): {}", getJdbcUrl());
        log.info("getMaximumPoolSize(): {}", getMaximumPoolSize());
        log.info("getMinimumIdle(): {}", getMinimumIdle());
        log.info("getPoolName(): {}", getPoolName());
        log.info("getUsername(): {}", getUsername());
    }

    @Override
    public void setJdbcUrl(java.lang.String jdbcUrl) {
        log.info("setJdbcUrl({})", jdbcUrl);
        super.setJdbcUrl(jdbcUrl);
    }

    @Override
    public void setMaximumPoolSize(int maxPoolSize) {
        log.info("setMaximumPoolSize({})", maxPoolSize);
        super.setMaximumPoolSize(maxPoolSize);
    }

    @Override
    public void setMinimumIdle(int minIdle) {
        log.info("setMinimumIdle({})", minIdle);
        super.setMinimumIdle(minIdle);
    }

    @Override
    public void setPoolName(java.lang.String poolName) {
        log.info("setPoolName({})", poolName);
        super.setPoolName(poolName);
    }

    @Override
    public void setUsername(java.lang.String username) {
        log.info("setUsername({})", username);
        super.setUsername(username);
    }
}
