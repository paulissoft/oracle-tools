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
    public OverflowPoolDataSourceHikari authDataSource1(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(OverflowPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"authDataSource2"})
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public OverflowPoolDataSourceHikari authDataSource2(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(OverflowPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"configDataSource1"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public CombiPoolDataSourceHikari configDataSource1(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"configDataSource2"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public CombiPoolDataSourceHikari configDataSource2(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"configDataSource3"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public OverflowPoolDataSourceHikari configDataSource3(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(OverflowPoolDataSourceHikari.class)
            .build();
    }

    @Bean(name = {"ocpiDataSource1"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public CombiPoolDataSourceHikari ocpiDataSource1(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties,
                                                     @Qualifier("configDataSource1") CombiPoolDataSourceHikari configDataSource) {
        return new CombiPoolDataSourceHikari(configDataSource,
                                             properties.getDriverClassName(),
                                             properties.getUrl(),
                                             properties.getUsername(),
                                             properties.getPassword(),
                                             properties.getType().getClass().getName());
    }

    @Bean(name = {"ocpiDataSource2"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public CombiPoolDataSourceHikari ocpiDataSource2(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties,
                                                     @Qualifier("configDataSource2") CombiPoolDataSourceHikari configDataSource) {
        return new CombiPoolDataSourceHikari(configDataSource,
                                             properties.getDriverClassName(),
                                             properties.getUrl(),
                                             properties.getUsername(),
                                             properties.getPassword(),
                                             properties.getType().getClass().getName());
    }

    @Bean(name = {"ocppDataSource1"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public CombiPoolDataSourceHikari ocppDataSource1(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties,
                                                     @Qualifier("configDataSource1") CombiPoolDataSourceHikari configDataSource) {
        return new CombiPoolDataSourceHikari(configDataSource,
                                             properties.getDriverClassName(),
                                             properties.getUrl(),
                                             properties.getUsername(),
                                             properties.getPassword(),
                                             properties.getType().getClass().getName());
    }

    @Bean(name = {"ocppDataSource2"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public CombiPoolDataSourceHikari ocppDataSource2(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties,
                                                     @Qualifier("configDataSource2") CombiPoolDataSourceHikari configDataSource) {
        return new CombiPoolDataSourceHikari(configDataSource,
                                             properties.getDriverClassName(),
                                             properties.getUrl(),
                                             properties.getUsername(),
                                             properties.getPassword(),
                                             properties.getType().getClass().getName());
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
