package com.example.springboot;

import com.zaxxer.hikari.HikariDataSource;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari;
import com.paulissoft.pato.jdbc.CombiPoolDataSourceHikari;
import com.paulissoft.pato.jdbc.SmartPoolDataSourceHikari;

import lombok.extern.slf4j.Slf4j;


@Slf4j
@Configuration
public class ConfigurationFactoryHikari {

    // HikariDataSource.class (0)
    @Bean(name = {"authDataSourceHikari0"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public DataSource authDataSourceHikari0(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        log.debug("authDataSourceHikari0");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    @Bean(name = {"configDataSourceHikari0"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public DataSource configDataSourceHikari0(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        log.debug("configDataSourceHikari0");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    @Bean(name = {"domainDataSourceHikari0"})
    @ConfigurationProperties(prefix = "app.domain.datasource.hikari")
    public DataSource domainDataSourceHikari0(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        log.debug("domainDataSourceHikari0");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    @Bean(name = {"ocpiDataSourceHikari0"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public DataSource ocpiDataSourceHikari0(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocpiDataSourceHikari0");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    @Bean(name = {"ocppDataSourceHikari0"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public DataSource ocppDataSourceHikari0(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocppDataSourceHikari0");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    @Bean(name = {"operatorDataSourceHikari0"})
    @ConfigurationProperties(prefix = "app.operator.datasource.hikari")
    public DataSource operatorDataSourceHikari0(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        log.debug("operatorDataSourceHikari0");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    // SimplePoolDataSourceHikari.class (1)
    @Bean(name = {"authDataSourceHikari1"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public DataSource authDataSourceHikari1(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        log.debug("authDataSourceHikari1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"configDataSourceHikari1"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public DataSource configDataSourceHikari1(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        log.debug("configDataSourceHikari1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"domainDataSourceHikari1"})
    @ConfigurationProperties(prefix = "app.domain.datasource.hikari")
    public DataSource domainDataSourceHikari1(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        log.debug("domainDataSourceHikari1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocpiDataSourceHikari1"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public DataSource ocpiDataSourceHikari1(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocpiDataSourceHikari1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocppDataSourceHikari1"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public DataSource ocppDataSourceHikari1(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocppDataSourceHikari1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"operatorDataSourceHikari1"})
    @ConfigurationProperties(prefix = "app.operator.datasource.hikari")
    public DataSource operatorDataSourceHikari1(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        log.debug("operatorDataSourceHikari1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceHikari.class)
            .build();
    }

    // CombiPoolDataSourceHikari.class (2)
    @Bean(name = {"authDataSourceHikari2"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public DataSource authDataSourceHikari2(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        log.debug("authDataSourceHikari2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"configDataSourceHikari2"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public DataSource configDataSourceHikari2(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        log.debug("configDataSourceHikari2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"domainDataSourceHikari2"})
    @ConfigurationProperties(prefix = "app.domain.datasource.hikari")
    public DataSource domainDataSourceHikari2(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        log.debug("domainDataSourceHikari2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocpiDataSourceHikari2"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public DataSource ocpiDataSourceHikari2(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocpiDataSourceHikari2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocppDataSourceHikari2"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public DataSource ocppDataSourceHikari2(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocppDataSourceHikari2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"operatorDataSourceHikari2"})
    @ConfigurationProperties(prefix = "app.operator.datasource.hikari")
    public DataSource operatorDataSourceHikari2(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        log.debug("operatorDataSourceHikari2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceHikari.class)
            .build();
    }

    // CombiPoolDataSourceHikari.class (3)
    @Bean(name = {"authDataSourceHikari3"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public DataSource authDataSourceHikari3(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        log.debug("authDataSourceHikari3");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"configDataSourceHikari3"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public DataSource configDataSourceHikari3(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        log.debug("configDataSourceHikari3");
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"domainDataSourceHikari3"})
    @ConfigurationProperties(prefix = "app.domain.datasource.hikari")
    public DataSource domainDataSourceHikari3(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        log.debug("domainDataSourceHikari3");
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocpiDataSourceHikari3"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public DataSource ocpiDataSourceHikari3(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocpiDataSourceHikari3");
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocppDataSourceHikari3"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public DataSource ocppDataSourceHikari3(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocppDataSourceHikari3");
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"operatorDataSourceHikari3"})
    @ConfigurationProperties(prefix = "app.operator.datasource.hikari")
    public DataSource operatorDataSourceHikari3(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        log.debug("operatorDataSourceHikari3");
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }   
}
