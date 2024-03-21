package com.paulissoft.pato.jdbc;

import javax.sql.DataSource;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.annotation.Qualifier;


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
    @ConfigurationProperties(prefix = "app.auth.datasource.oracleucp")
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
    @ConfigurationProperties(prefix = "app.ocpp.datasource.oracleucp")
    public PoolDataSourceConfigurationOracle getAppOcppDataSourceConfigurationOracle() {
        return new PoolDataSourceConfigurationOracle();
    }

    @Bean(name = "app-config-datasource")
    @ConfigurationProperties(prefix = "app.config.datasource")
    public PoolDataSourceConfiguration getAppConfigDataSourceConfiguration() {
        return new PoolDataSourceConfiguration();
    }

    @Bean(name = "app-config-datasource-hikari")
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public PoolDataSourceConfigurationHikari getAppConfigDataSourceConfigurationHikari() {
        return new PoolDataSourceConfigurationHikari();
    }

    @Bean(name = "app-config-datasource-oracle")
    @ConfigurationProperties(prefix = "app.config.datasource.oracleucp")
    public PoolDataSourceConfigurationOracle getAppConfigDataSourceConfigurationOracle() {
        return new PoolDataSourceConfigurationOracle();
    }

    @Bean(name = "app-ocpi-datasource")
    @ConfigurationProperties(prefix = "app.ocpi.datasource")
    public PoolDataSourceConfiguration getAppOcpiDataSourceConfiguration() {
        return new PoolDataSourceConfiguration();
    }

    @Bean(name = "app-ocpi-datasource-hikari")
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public PoolDataSourceConfigurationHikari getAppOcpiDataSourceConfigurationHikari() {
        return new PoolDataSourceConfigurationHikari();
    }

    @Bean(name = "app-ocpi-datasource-oracle")
    @ConfigurationProperties(prefix = "app.ocpi.datasource.oracleucp")
    public PoolDataSourceConfigurationOracle getAppOcpiDataSourceConfigurationOracle() {
        return new PoolDataSourceConfigurationOracle();
    }

    @Bean(name = "app-domain-datasource")
    @ConfigurationProperties(prefix = "app.domain.datasource")
    public PoolDataSourceConfiguration getAppDomainDataSourceConfiguration() {
        return new PoolDataSourceConfiguration();
    }

    @Bean(name = "app-domain-datasource-hikari")
    @ConfigurationProperties(prefix = "app.domain.datasource.hikari")
    public PoolDataSourceConfigurationHikari getAppDomainDataSourceConfigurationHikari() {
        return new PoolDataSourceConfigurationHikari();
    }

    @Bean(name = "app-domain-datasource-oracle")
    @ConfigurationProperties(prefix = "app.domain.datasource.oracleucp")
    public PoolDataSourceConfigurationOracle getAppDomainDataSourceConfigurationOracle() {
        return new PoolDataSourceConfigurationOracle();
    }

    @Bean(name = {"operatorDataSourceProperties"})
    @ConfigurationProperties(prefix = "app.operator.datasource")
    public DataSourceProperties dataSourceProperties() {
        return new DataSourceProperties();
    }
    
    @Bean(name = {"operatorDataSource"})
    @ConfigurationProperties(prefix = "app.operator.datasource.hikari")
    public DataSource dataSource(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            //.type(MyHikariDataSource.class)
            .build();
    }
}
