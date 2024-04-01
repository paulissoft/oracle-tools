package com.paulissoft.pato.jdbc;

import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import lombok.extern.slf4j.Slf4j;


@Slf4j
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

    @Bean(name = "app-ocpp-datasource")
    @ConfigurationProperties(prefix = "app.ocpp.datasource")
    public PoolDataSourceConfiguration getAppOcppDataSourceConfiguration() {
        return new PoolDataSourceConfiguration();
    }

    @Bean(name = "app-config-datasource")
    @ConfigurationProperties(prefix = "app.config.datasource")
    public PoolDataSourceConfiguration getAppConfigDataSourceConfiguration() {
        return new PoolDataSourceConfiguration();
    }

    @Bean(name = "app-ocpi-datasource")
    @ConfigurationProperties(prefix = "app.ocpi.datasource")
    public PoolDataSourceConfiguration getAppOcpiDataSourceConfiguration() {
        return new PoolDataSourceConfiguration();
    }

    @Bean(name = "app-domain-datasource")
    @ConfigurationProperties(prefix = "app.domain.datasource")
    public PoolDataSourceConfiguration getAppDomainDataSourceConfiguration() {
        return new PoolDataSourceConfiguration();
    }

    @Bean(name = {"operatorDataSourceProperties"})
    @ConfigurationProperties(prefix = "app.operator.datasource")
    public DataSourceProperties dataSourceProperties() {
        return new DataSourceProperties();
    }
}
