package com.paulissoft.pato.jdbc;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.stereotype.Component;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;


@Getter
@Setter
@ToString
@Configuration
@Component
public class PoolDataSourceConfiguration {

    // Spring properties
    @Value("${spring.datasource.ucp.initial-pool-size}")
    private int initialPoolSize;

    @Value("${spring.datasource.ucp.min-pool-size}")
    private int minPoolSize;

    @Value("${spring.datasource.ucp.max-pool-size}")
    private int maxPoolSize;
    
    @Value("${spring.datasource.ucp.connection-factory-class-name}")
    private String connectionFactoryClassName;
}
