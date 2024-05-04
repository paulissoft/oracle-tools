package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.annotation.Qualifier;

import lombok.extern.slf4j.Slf4j;


@Slf4j
@Configuration
public class ConfigurationFactoryHikari {

    @Bean(name = {"authDataSource1"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public HikariDataSource authDataSource1(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        log.debug("authDataSource1");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    @Bean(name = {"configDataSource1"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public HikariDataSource configDataSource1(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        log.debug("configDataSource1");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    @Bean(name = {"domainDataSource1"})
    @ConfigurationProperties(prefix = "app.domain.datasource.hikari")
    public HikariDataSource domainDataSource1(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        log.debug("domainDataSource1");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    @Bean(name = {"ocpiDataSource1"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public HikariDataSource ocpiDataSource1(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocpiDataSource1");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    @Bean(name = {"ocppDataSource1"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public HikariDataSource ocppDataSource1(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocppDataSource1");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    @Bean(name = {"operatorDataSource1"})
    @ConfigurationProperties(prefix = "app.operator.datasource.hikari")
    public HikariDataSource operatorDataSource1(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        log.debug("operatorDataSource1");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }
}
