package com.paulissoft.pato.jdbc;

import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.annotation.Qualifier;

import lombok.extern.slf4j.Slf4j;


@Slf4j
@Configuration
public class ConfigurationFactoryHikari {

    @Bean(name = {"configDataSource"})
    @ConfigurationProperties(prefix = "app.config.datasource.hikari")
    public CombiPoolDataSourceHikari configDataSource(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        final CombiPoolDataSourceHikari ds = properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceHikari.class)
            .build();

        log.debug("configDataSource({}): {}", properties, ds);
        
        return ds;
    }

    @Bean(name = {"ocpiDataSource"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.hikari")
    public CombiPoolDataSourceHikari ocpiDataSource(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties,
                                                    @Qualifier("configDataSource") CombiPoolDataSourceHikari configDataSource) {
        final CombiPoolDataSourceHikari ds = new CombiPoolDataSourceHikari(configDataSource,
                                                                           properties.getDriverClassName(),
                                                                           properties.getUrl(),
                                                                           properties.getUsername(),
                                                                           properties.getPassword());
        
        log.debug("ocpiDataSource({}, {}): {}", properties, configDataSource, ds);

        return ds;
    }

    @Bean(name = {"ocppDataSource"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.hikari")
    public CombiPoolDataSourceHikari ocppDataSource(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties,
                                                    @Qualifier("configDataSource") CombiPoolDataSourceHikari configDataSource) {
        final CombiPoolDataSourceHikari ds = new CombiPoolDataSourceHikari(configDataSource,
                                                                           properties.getDriverClassName(),
                                                                           properties.getUrl(),
                                                                           properties.getUsername(),
                                                                           properties.getPassword());

        log.debug("ocppDataSource({}, {}): {}", properties, configDataSource, ds);

        return ds;
    }

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
