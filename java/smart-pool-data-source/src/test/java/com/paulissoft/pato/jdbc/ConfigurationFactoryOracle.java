package com.paulissoft.pato.jdbc;

import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.annotation.Qualifier;

import lombok.extern.slf4j.Slf4j;


@Slf4j
@Configuration
public class ConfigurationFactoryOracle extends ConfigurationFactory {

    @Bean(name = "app-auth-datasource-oracle")
    @ConfigurationProperties(prefix = "app.auth.datasource.oracleucp")
    public PoolDataSourceConfigurationOracle getAppAuthDataSourceConfigurationOracle() {
        return new PoolDataSourceConfigurationOracle();
    }

    @Bean(name = "app-ocpp-datasource-oracle")
    @ConfigurationProperties(prefix = "app.ocpp.datasource.oracleucp")
    public PoolDataSourceConfigurationOracle getAppOcppDataSourceConfigurationOracle() {
        return new PoolDataSourceConfigurationOracle();
    }

    @Bean(name = "app-config-datasource-oracle")
    @ConfigurationProperties(prefix = "app.config.datasource.oracleucp")
    public PoolDataSourceConfigurationOracle getAppConfigDataSourceConfigurationOracle() {
        return new PoolDataSourceConfigurationOracle();
    }

    @Bean(name = "app-ocpi-datasource-oracle")
    @ConfigurationProperties(prefix = "app.ocpi.datasource.oracleucp")
    public PoolDataSourceConfigurationOracle getAppOcpiDataSourceConfigurationOracle() {
        return new PoolDataSourceConfigurationOracle();
    }

    @Bean(name = "app-domain-datasource-oracle")
    @ConfigurationProperties(prefix = "app.domain.datasource.oracleucp")
    public PoolDataSourceConfigurationOracle getAppDomainDataSourceConfigurationOracle() {
        return new PoolDataSourceConfigurationOracle();
    }

    @ConfigurationProperties(prefix = "app.domain.datasource.oracleucp")
    public MyDomainDataSourceOracle domainDataSourceOracle(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(MyDomainDataSourceOracle.class)
            .build();
    } 

    @ConfigurationProperties(prefix = "app.operator.datasource.oracleucp")
    public MyOperatorDataSourceOracle operatorDataSourceOracle(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(MyOperatorDataSourceOracle.class) // app.operator.datasource.type is NOT correct
            .build();
    } 
}
