package com.paulissoft.pato.jdbc;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;


@Configuration
public class ConfigurationFactory {

    @Bean(name = "spring-datasource")
    @ConfigurationProperties(prefix = "spring.datasource")
    public DataSourceConfiguration getDataSourceConfiguration() {
        return new DataSourceConfiguration();
    }

    @Bean(name = "app-auth-datasource-pool")
    @ConfigurationProperties(prefix = "spring.datasource.pool")
    public PoolDataSourceConfiguration getPoolDataSourceConfiguration() {
        return new PoolDataSourceConfiguration();
    }

    @Bean(name = "app-auth-datasource-hikari")
    @ConfigurationProperties(prefix = "app.auth.datasource.hikari")
    public PoolDataSourceConfigurationHikari getPoolDataSourceConfigurationHikari() {
        return new PoolDataSourceConfigurationHikari();
    }

    @Bean(name = "app-auth-datasource-oracle")
    @ConfigurationProperties(prefix = "app.auth.datasource.oracle")
    public PoolDataSourceConfigurationOracle getPoolDataSourceConfigurationOracle() {
        return new PoolDataSourceConfigurationOracle();
    }
}
