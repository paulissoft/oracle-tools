package com.paulissoft.pato.jdbc;

import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.beans.factory.annotation.Qualifier;

@Configuration
public class ConfigurationFactoryOracle {

    @Bean(name = {"authDataSourceOracle1"})
    @ConfigurationProperties(prefix = "app.auth.datasource.oracleucp")
    public SmartPoolDataSourceOracle authDataSourceOracle1(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"configDataSourceOracle3"})
    @ConfigurationProperties(prefix = "app.config.datasource.oracleucp")
    public SmartPoolDataSourceOracle configDataSourceOracle3(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
    }
    
    @Bean(name = {"configDataSourceOracle4"})
    @ConfigurationProperties(prefix = "app.config.datasource.oracleucp")
    public SmartPoolDataSourceOracle configDataSourceOracle4(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"ocpiDataSourceOracle1"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.oracleucp")
    public SmartPoolDataSourceOracle ocpiDataSourceOracle1(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"ocpiDataSourceOracle3"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.oracleucp")
    public SmartPoolDataSourceOracle ocpiDataSourceOracle3(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"ocppDataSourceOracle1"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.oracleucp")
    public SmartPoolDataSourceOracle ocppDataSourceOracle1(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"ocppDataSourceOracle3"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.oracleucp")
    public SmartPoolDataSourceOracle ocppDataSourceOracle3(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
    }

    @Primary
    @ConfigurationProperties(prefix = "app.domain.datasource.oracleucp")
    public SmartPoolDataSourceOracle domainDataSourceOracle(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
    } 

    @ConfigurationProperties(prefix = "app.operator.datasource.oracleucp")
    public SmartPoolDataSourceOracle operatorDataSourceOracle(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
    } 
}
