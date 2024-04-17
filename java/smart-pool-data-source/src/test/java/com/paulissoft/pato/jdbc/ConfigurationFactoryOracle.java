package com.paulissoft.pato.jdbc;

import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.annotation.Qualifier;

import lombok.extern.slf4j.Slf4j;


@Slf4j
@Configuration
public class ConfigurationFactoryOracle {

    @Bean(name = {"configDataSource1"})
    @ConfigurationProperties(prefix = "app.config.datasource.oracleucp")
    public CombiPoolDataSourceOracle configDataSource1(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"configDataSource2"})
    @ConfigurationProperties(prefix = "app.config.datasource.oracleucp")
    public CombiPoolDataSourceOracle configDataSource2(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"ocpiDataSource1"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.oracleucp")
    public CombiPoolDataSourceOracle ocpiDataSource1(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties,
                                                     @Qualifier("configDataSource1") CombiPoolDataSourceOracle configDataSource) {
        return new CombiPoolDataSourceOracle(configDataSource,
                                             properties.getUrl(),
                                             properties.getUsername(),
                                             properties.getPassword(),
                                             properties.getType().getClass().getName());
    }

    @Bean(name = {"ocpiDataSource2"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.oracleucp")
    public CombiPoolDataSourceOracle ocpiDataSource2(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties,
                                                     @Qualifier("configDataSource2") CombiPoolDataSourceOracle configDataSource) {
        return new CombiPoolDataSourceOracle(configDataSource,
                                             properties.getUrl(),
                                             properties.getUsername(),
                                             properties.getPassword(),
                                             properties.getType().getClass().getName());
    }

    @Bean(name = {"ocppDataSource1"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.oracleucp")
    public CombiPoolDataSourceOracle ocppDataSource1(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties,
                                                     @Qualifier("configDataSource1") CombiPoolDataSourceOracle configDataSource) {
        return new CombiPoolDataSourceOracle(configDataSource,
                                             properties.getUrl(),
                                             properties.getUsername(),
                                             properties.getPassword(),
                                             properties.getType().getClass().getName());
    }

    @Bean(name = {"ocppDataSource2"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.oracleucp")
    public CombiPoolDataSourceOracle ocppDataSource2(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties,
                                                     @Qualifier("configDataSource2") CombiPoolDataSourceOracle configDataSource) {
        return new CombiPoolDataSourceOracle(configDataSource,
                                             properties.getUrl(),
                                             properties.getUsername(),
                                             properties.getPassword(),
                                             properties.getType().getClass().getName());
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
            .type(MyOperatorDataSourceOracle.class)
            .build();
    } 
}
