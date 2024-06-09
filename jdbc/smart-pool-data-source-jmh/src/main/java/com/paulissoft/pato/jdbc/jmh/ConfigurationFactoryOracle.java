package com.paulissoft.pato.jdbc.jmh;


import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

// the four variants
import oracle.ucp.jdbc.PoolDataSourceImpl;
import com.paulissoft.pato.jdbc.SimplePoolDataSourceOracle;
import com.paulissoft.pato.jdbc.CombiPoolDataSourceOracle;
import com.paulissoft.pato.jdbc.OverflowPoolDataSourceOracle;
import com.paulissoft.pato.jdbc.SmartPoolDataSourceOracle;

import lombok.extern.slf4j.Slf4j;


@Slf4j
@Configuration
public class ConfigurationFactoryOracle {

    // PoolDataSourceImpl.class (0)
    @Bean(name = {"authDataSourceOracle0"})
    @ConfigurationProperties(prefix = "app.auth.datasource.oracleucp")
    public DataSource authDataSourceOracle0(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        log.debug("authDataSourceOracle0");
        return properties
            .initializeDataSourceBuilder()
            .type(PoolDataSourceImpl.class)
            .build();
    }

    @Bean(name = {"configDataSourceOracle0"})
    @ConfigurationProperties(prefix = "app.config.datasource.oracleucp")
    public DataSource configDataSourceOracle0(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        log.debug("configDataSourceOracle0");
        return properties
            .initializeDataSourceBuilder()
            .type(PoolDataSourceImpl.class)
            .build();
    }

    @Bean(name = {"domainDataSourceOracle0"})
    @ConfigurationProperties(prefix = "app.domain.datasource.oracleucp")
    public DataSource domainDataSourceOracle0(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        log.debug("domainDataSourceOracle0");
        return properties
            .initializeDataSourceBuilder()
            .type(PoolDataSourceImpl.class)
            .build();
    }

    @Bean(name = {"ocpiDataSourceOracle0"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.oracleucp")
    public DataSource ocpiDataSourceOracle0(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocpiDataSourceOracle0");
        return properties
            .initializeDataSourceBuilder()
            .type(PoolDataSourceImpl.class)
            .build();
    }

    @Bean(name = {"ocppDataSourceOracle0"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.oracleucp")
    public DataSource ocppDataSourceOracle0(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocppDataSourceOracle0");
        return properties
            .initializeDataSourceBuilder()
            .type(PoolDataSourceImpl.class)
            .build();
    }

    @Bean(name = {"operatorDataSourceOracle0"})
    @ConfigurationProperties(prefix = "app.operator.datasource.oracleucp")
    public DataSource operatorDataSourceOracle0(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        log.debug("operatorDataSourceOracle0");
        return properties
            .initializeDataSourceBuilder()
            .type(PoolDataSourceImpl.class)
            .build();
    }

    // SimplePoolDataSourceOracle.class (1)
    @Bean(name = {"authDataSourceOracle1"})
    @ConfigurationProperties(prefix = "app.auth.datasource.oracleucp")
    public DataSource authDataSourceOracle1(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        log.debug("authDataSourceOracle1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"configDataSourceOracle1"})
    @ConfigurationProperties(prefix = "app.config.datasource.oracleucp")
    public DataSource configDataSourceOracle1(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        log.debug("configDataSourceOracle1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"domainDataSourceOracle1"})
    @ConfigurationProperties(prefix = "app.domain.datasource.oracleucp")
    public DataSource domainDataSourceOracle1(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        log.debug("domainDataSourceOracle1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"ocpiDataSourceOracle1"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.oracleucp")
    public DataSource ocpiDataSourceOracle1(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocpiDataSourceOracle1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"ocppDataSourceOracle1"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.oracleucp")
    public DataSource ocppDataSourceOracle1(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocppDataSourceOracle1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"operatorDataSourceOracle1"})
    @ConfigurationProperties(prefix = "app.operator.datasource.oracleucp")
    public DataSource operatorDataSourceOracle1(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        log.debug("operatorDataSourceOracle1");
        return properties
            .initializeDataSourceBuilder()
            .type(SimplePoolDataSourceOracle.class)
            .build();
    }

    // CombiPoolDataSourceOracle.class (2)
    @Bean(name = {"authDataSourceOracle2"})
    @ConfigurationProperties(prefix = "app.auth.datasource.oracleucp")
    public DataSource authDataSourceOracle2(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        log.debug("authDataSourceOracle2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"configDataSourceOracle2"})
    @ConfigurationProperties(prefix = "app.config.datasource.oracleucp")
    public DataSource configDataSourceOracle2(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        log.debug("configDataSourceOracle2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"domainDataSourceOracle2"})
    @ConfigurationProperties(prefix = "app.domain.datasource.oracleucp")
    public DataSource domainDataSourceOracle2(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        log.debug("domainDataSourceOracle2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"ocpiDataSourceOracle2"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.oracleucp")
    public DataSource ocpiDataSourceOracle2(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocpiDataSourceOracle2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"ocppDataSourceOracle2"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.oracleucp")
    public DataSource ocppDataSourceOracle2(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocppDataSourceOracle2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceOracle.class)
            .build();
    }

    @Bean(name = {"operatorDataSourceOracle2"})
    @ConfigurationProperties(prefix = "app.operator.datasource.oracleucp")
    public DataSource operatorDataSourceOracle2(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        log.debug("operatorDataSourceOracle2");
        return properties
            .initializeDataSourceBuilder()
            .type(CombiPoolDataSourceOracle.class)
            .build();
    }

    // OverflowPoolDataSourceOracle.class (3)
    @Bean(name = {"authDataSourceOracle3"})
    @ConfigurationProperties(prefix = "app.auth.datasource.oracleucp")
    public OverflowPoolDataSourceOracle authDataSourceOracle3(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        log.debug("authDataSourceOracle3");
        /*
        return properties
            .initializeDataSourceBuilder()
            .type(OverflowPoolDataSourceOracle.class)
            .build();
        */
        return (OverflowPoolDataSourceOracle) MyDataSourceBuilder.build(ConfigurationFactory.copy(properties, OverflowPoolDataSourceOracle.class));
    }

    @Bean(name = {"configDataSourceOracle3"})
    @ConfigurationProperties(prefix = "app.config.datasource.oracleucp")
    public OverflowPoolDataSourceOracle configDataSourceOracle3(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        log.debug("configDataSourceOracle3");
        /*
        return properties
            .initializeDataSourceBuilder()
            .type(OverflowPoolDataSourceOracle.class)
            .build();
        */
        return (OverflowPoolDataSourceOracle) MyDataSourceBuilder.build(ConfigurationFactory.copy(properties, OverflowPoolDataSourceOracle.class));
    }

    @Bean(name = {"domainDataSourceOracle3"})
    @ConfigurationProperties(prefix = "app.domain.datasource.oracleucp")
    public OverflowPoolDataSourceOracle domainDataSourceOracle3(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        log.debug("domainDataSourceOracle3");
        /*
        return properties
            .initializeDataSourceBuilder()
            .type(OverflowPoolDataSourceOracle.class)
            .build();
        */
        return (OverflowPoolDataSourceOracle) MyDataSourceBuilder.build(ConfigurationFactory.copy(properties, OverflowPoolDataSourceOracle.class));
    }

    @Bean(name = {"ocpiDataSourceOracle3"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.oracleucp")
    public OverflowPoolDataSourceOracle ocpiDataSourceOracle3(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocpiDataSourceOracle3");
        /*
        return properties
            .initializeDataSourceBuilder()
            .type(OverflowPoolDataSourceOracle.class)
            .build();
        */
        return (OverflowPoolDataSourceOracle) MyDataSourceBuilder.build(ConfigurationFactory.copy(properties, OverflowPoolDataSourceOracle.class));
    }

    @Bean(name = {"ocppDataSourceOracle3"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.oracleucp")
    public OverflowPoolDataSourceOracle ocppDataSourceOracle3(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocppDataSourceOracle3");
        /*
        return properties
            .initializeDataSourceBuilder()
            .type(OverflowPoolDataSourceOracle.class)
            .build();
        */
        return (OverflowPoolDataSourceOracle) MyDataSourceBuilder.build(ConfigurationFactory.copy(properties, OverflowPoolDataSourceOracle.class));
    }

    @Bean(name = {"operatorDataSourceOracle3"})
    @ConfigurationProperties(prefix = "app.operator.datasource.oracleucp")
    public OverflowPoolDataSourceOracle operatorDataSourceOracle3(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        log.debug("operatorDataSourceOracle3");
        /*
        return properties
            .initializeDataSourceBuilder()
            .type(OverflowPoolDataSourceOracle.class)
            .build();
        */
        return (OverflowPoolDataSourceOracle) MyDataSourceBuilder.build(ConfigurationFactory.copy(properties, OverflowPoolDataSourceOracle.class));
    }   

    // SmartPoolDataSourceOracle.class (4)
    @Bean(name = {"authDataSourceOracle4"})
    @ConfigurationProperties(prefix = "app.auth.datasource.oracleucp")
    public SmartPoolDataSourceOracle authDataSourceOracle4(@Qualifier("authDataSourceProperties") DataSourceProperties properties) {
        log.debug("authDataSourceOracle4");
        /*
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
        */
        return (SmartPoolDataSourceOracle) MyDataSourceBuilder.build(ConfigurationFactory.copy(properties, SmartPoolDataSourceOracle.class));
    }

    @Bean(name = {"configDataSourceOracle4"})
    @ConfigurationProperties(prefix = "app.config.datasource.oracleucp")
    public SmartPoolDataSourceOracle configDataSourceOracle4(@Qualifier("configDataSourceProperties") DataSourceProperties properties) {
        log.debug("configDataSourceOracle4");
        /*
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
        */
        return (SmartPoolDataSourceOracle) MyDataSourceBuilder.build(ConfigurationFactory.copy(properties, SmartPoolDataSourceOracle.class));
    }

    @Bean(name = {"domainDataSourceOracle4"})
    @ConfigurationProperties(prefix = "app.domain.datasource.oracleucp")
    public SmartPoolDataSourceOracle domainDataSourceOracle4(@Qualifier("domainDataSourceProperties") DataSourceProperties properties) {
        log.debug("domainDataSourceOracle4");
        /*
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
        */
        return (SmartPoolDataSourceOracle) MyDataSourceBuilder.build(ConfigurationFactory.copy(properties, SmartPoolDataSourceOracle.class));
    }

    @Bean(name = {"ocpiDataSourceOracle4"})
    @ConfigurationProperties(prefix = "app.ocpi.datasource.oracleucp")
    public SmartPoolDataSourceOracle ocpiDataSourceOracle4(@Qualifier("ocpiDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocpiDataSourceOracle4");
        /*
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
        */
        return (SmartPoolDataSourceOracle) MyDataSourceBuilder.build(ConfigurationFactory.copy(properties, SmartPoolDataSourceOracle.class));
    }

    @Bean(name = {"ocppDataSourceOracle4"})
    @ConfigurationProperties(prefix = "app.ocpp.datasource.oracleucp")
    public SmartPoolDataSourceOracle ocppDataSourceOracle4(@Qualifier("ocppDataSourceProperties") DataSourceProperties properties) {
        log.debug("ocppDataSourceOracle4");
        /*
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
        */
        return (SmartPoolDataSourceOracle) MyDataSourceBuilder.build(ConfigurationFactory.copy(properties, SmartPoolDataSourceOracle.class));
    }

    @Bean(name = {"operatorDataSourceOracle4"})
    @ConfigurationProperties(prefix = "app.operator.datasource.oracleucp")
    public SmartPoolDataSourceOracle operatorDataSourceOracle4(@Qualifier("operatorDataSourceProperties") DataSourceProperties properties) {
        log.debug("operatorDataSourceOracle4");
        /*
        return properties
            .initializeDataSourceBuilder()
            .type(SmartPoolDataSourceOracle.class)
            .build();
        */
        return (SmartPoolDataSourceOracle) MyDataSourceBuilder.build(ConfigurationFactory.copy(properties, SmartPoolDataSourceOracle.class));
    }   
}
