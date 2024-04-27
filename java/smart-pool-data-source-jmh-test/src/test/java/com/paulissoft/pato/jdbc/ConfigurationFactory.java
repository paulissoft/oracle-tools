package com.paulissoft.pato.jdbc;

import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import lombok.extern.slf4j.Slf4j;


@Slf4j
@Configuration
public class ConfigurationFactory {

    @Bean(name = {"authDataSourceProperties"})
    @ConfigurationProperties(prefix = "app.auth.datasource")
    public DataSourceProperties authDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean(name = {"configDataSourceProperties"})
    @ConfigurationProperties(prefix = "app.config.datasource")
    public DataSourceProperties configDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean(name = {"ocpiDataSourceProperties"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource")
    public DataSourceProperties ocpiDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean(name = {"ocppDataSourceProperties"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource")
    public DataSourceProperties ocppDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean(name = {"domainDataSourceProperties"})
    @ConfigurationProperties(prefix = "app.domain.datasource")
    public DataSourceProperties domainDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean(name = {"operatorDataSourceProperties"})
    @ConfigurationProperties(prefix = "app.operator.datasource")
    public DataSourceProperties operatorDataSourceProperties() {
        return new DataSourceProperties();
    }
}
