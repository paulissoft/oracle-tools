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
    @Bean(name = {"authDataSource0"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public DataSource authDataSource0(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        log.debug("authDataSource0");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    @Bean(name = {"configDataSource0"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public DataSource configDataSource0(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        log.debug("configDataSource0");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    @Bean(name = {"domainDataSource0"})
    @ConfigurationProperties(prefix = "app.domain.datasource.hikari")
    public DataSource domainDataSource0(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        log.debug("domainDataSource0");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    @Bean(name = {"ocpiDataSource0"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public DataSource ocpiDataSource0(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocpiDataSource0");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    @Bean(name = {"ocppDataSource0"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public DataSource ocppDataSource0(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocppDataSource0");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    @Bean(name = {"operatorDataSource0"})
    @ConfigurationProperties(prefix = "app.operator.datasource.hikari")
    public DataSource operatorDataSource0(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        log.debug("operatorDataSource0");
        return properties
            .initializeDataSourceBuilder()
            .type(HikariDataSource.class)
            .build();
    }

    // SimplePoolDataSourceHikari.class (1)
    @Bean(name = {"authDataSource1"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public DataSource authDataSource1(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        log.debug("authDataSource1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"configDataSource1"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public DataSource configDataSource1(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        log.debug("configDataSource1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"domainDataSource1"})
    @ConfigurationProperties(prefix = "app.domain.datasource.hikari")
    public DataSource domainDataSource1(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        log.debug("domainDataSource1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocpiDataSource1"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public DataSource ocpiDataSource1(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocpiDataSource1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocppDataSource1"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public DataSource ocppDataSource1(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocppDataSource1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"operatorDataSource1"})
    @ConfigurationProperties(prefix = "app.operator.datasource.hikari")
    public DataSource operatorDataSource1(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        log.debug("operatorDataSource1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceHikari.class)
            .build();
    }

    // CombiPoolDataSourceHikari.class (2)
    @Bean(name = {"authDataSource2"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public DataSource authDataSource2(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        log.debug("authDataSource2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"configDataSource2"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public DataSource configDataSource2(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        log.debug("configDataSource2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"domainDataSource2"})
    @ConfigurationProperties(prefix = "app.domain.datasource.hikari")
    public DataSource domainDataSource2(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        log.debug("domainDataSource2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocpiDataSource2"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public DataSource ocpiDataSource2(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocpiDataSource2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocppDataSource2"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public DataSource ocppDataSource2(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocppDataSource2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"operatorDataSource2"})
    @ConfigurationProperties(prefix = "app.operator.datasource.hikari")
    public DataSource operatorDataSource2(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        log.debug("operatorDataSource2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceHikari.class)
            .build();
    }

    // CombiPoolDataSourceHikari.class (3)
    @Bean(name = {"authDataSource3"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public DataSource authDataSource3(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        log.debug("authDataSource3");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"configDataSource3"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public DataSource configDataSource3(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        log.debug("configDataSource3");
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"domainDataSource3"})
    @ConfigurationProperties(prefix = "app.domain.datasource.hikari")
    public DataSource domainDataSource3(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        log.debug("domainDataSource3");
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocpiDataSource3"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public DataSource ocpiDataSource3(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocpiDataSource3");
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocppDataSource3"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public DataSource ocppDataSource3(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocppDataSource3");
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"operatorDataSource3"})
    @ConfigurationProperties(prefix = "app.operator.datasource.hikari")
    public DataSource operatorDataSource3(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        log.debug("operatorDataSource3");
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }   
}
