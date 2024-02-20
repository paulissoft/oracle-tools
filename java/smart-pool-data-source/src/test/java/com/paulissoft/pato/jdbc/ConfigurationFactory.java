package com.paulissoft.pato.jdbc;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;


@Configuration
public class ConfigurationFactory {

    @Bean(name = "spring-datasource")
    @ConfigurationProperties(prefix = "spring.datasource")
    public PoolDataSourceConfiguration getSpringDataSourceConfiguration() {
        return new PoolDataSourceConfiguration();
    }

    @Bean(name = "app-auth-datasource")
    @ConfigurationProperties(prefix = "app.auth.datasource")
    public PoolDataSourceConfiguration getAppAuthDataSourceConfiguration() {
        return new PoolDataSourceConfiguration();
    }

    @Bean(name = "app-auth-datasource-hikari")
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public PoolDataSourceConfigurationHikari getAppAuthDataSourceConfigurationHikari() {
        return new PoolDataSourceConfigurationHikari();
    }

    @Bean(name = "app-auth-datasource-oracle")
    @ConfigurationProperties(prefix = "app.auth.datasource.ucp")
    public PoolDataSourceConfigurationOracle getAppAuthDataSourceConfigurationOracle() {
        return new PoolDataSourceConfigurationOracle();
    }

    @Bean(name = "app-ocpp-datasource")
    @ConfigurationProperties(prefix = "app.ocpp.datasource")
    public PoolDataSourceConfiguration getAppOcppDataSourceConfiguration() {
        return new PoolDataSourceConfiguration();
    }

    @Bean(name = "app-ocpp-datasource-hikari")
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public PoolDataSourceConfigurationHikari getAppOcppDataSourceConfigurationHikari() {
        return new PoolDataSourceConfigurationHikari();
    }

    @Bean(name = "app-ocpp-datasource-oracle")
    @ConfigurationProperties(prefix = "app.ocpp.datasource.ucp")
    public PoolDataSourceConfigurationOracle getAppOcppDataSourceConfigurationOracle() {
        return new PoolDataSourceConfigurationOracle();
    }
}
