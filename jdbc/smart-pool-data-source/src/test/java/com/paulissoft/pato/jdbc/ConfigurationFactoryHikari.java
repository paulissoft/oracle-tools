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

    @Bean(name = {"authDataSourceHikari1"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public SmartPoolDataSourceHikari authDataSourceHikari1(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"authDataSourceHikari2"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public SmartPoolDataSourceHikari authDataSourceHikari2(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"authDataSourceHikari3"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public SmartPoolDataSourceHikari authDataSourceHikari3(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"configDataSourceHikari3"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public SmartPoolDataSourceHikari configDataSourceHikari3(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"configDataSourceHikari4"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public SmartPoolDataSourceHikari configDataSourceHikari4(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocpiDataSourceHikari1"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public SmartPoolDataSourceHikari ocpiDataSourceHikari1(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocppDataSourceHikari1"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public SmartPoolDataSourceHikari ocppDataSourceHikari1(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
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
