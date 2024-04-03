package com.paulissoft.pato.jdbc;

import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.annotation.Qualifier;

import lombok.extern.slf4j.Slf4j;


@Slf4j
@Configuration
public class ConfigurationFactoryHikari extends ConfigurationFactory {

    @Bean(name = "app-auth-datasource-hikari")
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public PoolDataSourceConfigurationHikari getAppAuthDataSourceConfigurationHikari() {
        return new PoolDataSourceConfigurationHikari();
    }

    @Bean(name = "app-ocpp-datasource-hikari")
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public PoolDataSourceConfigurationHikari getAppOcppDataSourceConfigurationHikari() {
        return new PoolDataSourceConfigurationHikari();
    }

    @Bean(name = "app-config-datasource-hikari")
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public PoolDataSourceConfigurationHikari getAppConfigDataSourceConfigurationHikari() {
        return new PoolDataSourceConfigurationHikari();
    }

    @Bean(name = "app-ocpi-datasource-hikari")
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public PoolDataSourceConfigurationHikari getAppOcpiDataSourceConfigurationHikari() {
        return new PoolDataSourceConfigurationHikari();
    }

    @Bean(name = "app-domain-datasource-hikari")
    @ConfigurationProperties(prefix = "app.domain.datasource.hikari")
    public SmartPoolDataSourceHikari getAppDomainDataSourceHikari(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }

    // new standard: DataSourceBuilder

    /*
    @Bean(name = "app-auth-datasource-hikari")
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public SmartPoolDataSourceHikari authDataSourceHikari(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }
    */

    /*
    @Bean(name = "app-ocpp-datasource-hikari")
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public SmartPoolDataSourceHikari ocppDataSourceHikari(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();
    }
    */

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
            .type(MyOperatorDataSourceHikari.class) // app.operator.datasource.type is NOT correct
            .build();
    }
}
