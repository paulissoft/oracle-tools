package com.paulissoft.pato.jdbc.jmh;

import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import lombok.extern.slf4j.Slf4j;


@Slf4j
@Configuration
public class ConfigurationFactory {

    @Primary
    @Bean(name = {"authDataSourceProperties"})
    @ConfigurationProperties(prefix = "app.auth.datasource")
    public DataSourceProperties authDataSourceProperties() {
        log.debug("authDataSourceProperties");
        return new DataSourceProperties();
    }
    
    @Bean(name = {"configDataSourceProperties"})
    @ConfigurationProperties(prefix = "app.config.datasource")
    public DataSourceProperties configDataSourceProperties() {
        log.debug("configDataSourceProperties");
        return new DataSourceProperties();
    }

    @Bean(name = {"ocpiDataSourceProperties"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource")
    public DataSourceProperties ocpiDataSourceProperties() {
        log.debug("ocpiDataSourceProperties");
        return new DataSourceProperties();
    }

    @Bean(name = {"ocppDataSourceProperties"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource")
    public DataSourceProperties ocppDataSourceProperties() {
        log.debug("ocppDataSourceProperties");
        return new DataSourceProperties();
    }

    @Bean(name = {"domainDataSourceProperties"})
    @ConfigurationProperties(prefix = "app.domain.datasource")
    public DataSourceProperties domainDataSourceProperties() {
        log.debug("domainDataSourceProperties");
        return new DataSourceProperties();
    }

    @Bean(name = {"operatorDataSourceProperties"})
    @ConfigurationProperties(prefix = "app.operator.datasource")
    public DataSourceProperties operatorDataSourceProperties() {
        log.debug("operatorDataSourceProperties");
        return new DataSourceProperties();
    }
}
