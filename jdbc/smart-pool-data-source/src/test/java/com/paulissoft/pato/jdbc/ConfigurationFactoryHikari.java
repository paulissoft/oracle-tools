package com.paulissoft.pato.jdbc;

import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.beans.factory.annotation.Qualifier;

import lombok.extern.slf4j.Slf4j;


@Slf4j
@Configuration
public class ConfigurationFactoryHikari {

    @Bean(name = {"authDataSource1"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public SmartPoolDataSourceHikari authDataSource1(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"authDataSource2"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public SmartPoolDataSourceHikari authDataSource2(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"authDataSource3"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public SmartPoolDataSourceHikari authDataSource3(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"configDataSource1"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public SmartPoolDataSourceHikari configDataSource1(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"configDataSource2"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public SmartPoolDataSourceHikari configDataSource2(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"configDataSource3"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public SmartPoolDataSourceHikari configDataSource3(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"configDataSource4"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public SmartPoolDataSourceHikari configDataSource4(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocpiDataSource1"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public SmartPoolDataSourceHikari ocpiDataSource1(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocpiDataSource2"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public SmartPoolDataSourceHikari ocpiDataSource2(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocppDataSource1"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public SmartPoolDataSourceHikari ocppDataSource1(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocppDataSource2"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public SmartPoolDataSourceHikari ocppDataSource2(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Primary
    @ConfigurationProperties(prefix = "app.domain.datasource.hikari")
    public MyDomainDataSourceHikari domainDataSourceHikari(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(MyDomainDataSourceHikari.class)
            .build();
    }

    @ConfigurationProperties(prefix = "app.operator.datasource.hikari")
    public MyOperatorDataSourceHikari operatorDataSourceHikari(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(MyOperatorDataSourceHikari.class)
            .build();
    }
}
