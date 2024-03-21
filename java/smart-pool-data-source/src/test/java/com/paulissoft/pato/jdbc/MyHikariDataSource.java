package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class MyHikariDataSource extends HikariDataSource {
    public MyHikariDataSource() {
        log.info("MyHikariDataSource()");
    }
}
