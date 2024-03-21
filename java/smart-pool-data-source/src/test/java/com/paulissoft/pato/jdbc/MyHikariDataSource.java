package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import lombok.extern.slf4j.Slf4j;
//import org.springframework.stereotype.Component;


@Slf4j
//@Component
public class MyHikariDataSource extends HikariDataSource {
    public MyHikariDataSource() {
        log.info("MyHikariDataSource()");
        log.info("getJdbcUrl(): {}", getJdbcUrl());
        log.info("getMaximumPoolSize(): {}", getMaximumPoolSize());
        log.info("getMinimumIdle(): {}", getMinimumIdle());
        log.info("getPoolName(): {}", getPoolName());
        log.info("getUsername(): {}", getUsername());
    }

    public void setJdbcUrl(java.lang.String jdbcUrl) {
        log.info("setJdbcUrl({})", jdbcUrl);
        super.setJdbcUrl(jdbcUrl);
    }

    public void setMaximumPoolSize(int maxPoolSize) {
        log.info("setMaximumPoolSize({})", maxPoolSize);
        super.setMaximumPoolSize(maxPoolSize);
    }

    public void setMinimumIdle(int minIdle) {
        log.info("setMinimumIdle({})", minIdle);
        super.setMinimumIdle(minIdle);
    }

    public void setPoolName(java.lang.String poolName) {
        log.info("setPoolName({})", poolName);
        super.setPoolName(poolName);
    }

    public void setUsername(java.lang.String username) {
        log.info("setUsername({})", username);
        super.setUsername(username);
    }
}
