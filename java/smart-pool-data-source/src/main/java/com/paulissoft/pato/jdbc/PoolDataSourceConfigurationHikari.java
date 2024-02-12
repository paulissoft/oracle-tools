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
public class PoolDataSourceConfigurationHikari extends PoolDataSourceConfiguration {

    // Spring properties
    @Value("${spring.datasource.hikari.initial-pool-size}")
    private int initialPoolSize;

    @Value("${spring.datasource.hikari.min-pool-size}")
    private int minPoolSize;

    @Value("${spring.datasource.hikari.max-pool-size}")
    private int maxPoolSize;
    
    @Value("${spring.datasource.hikari.connection-factory-class-name}")
    private String connectionFactoryClassName;

    @Value("spring.datasource.hikari.auto-commit")
    private boolean autoCommit;
    
    @Value("spring.datasource.hikari.connection-timeout")
    private long connectionTimeout;
    
    @Value("spring.datasource.hikari.idle-timeout")
    private long idleTimeout;
    
    @Value("spring.datasource.hikari.max-lifetime")
    private long maxLifetime;
    
    @Value("spring.datasource.hikari.connection-test-query")
    private String connectionTestQuery;
    
    @Value("spring.datasource.hikari.maximum-pool-size")
    private int maximumPoolSize;
    
    @Value("spring.datasource.hikari.minimum-idle")
    private int minimumIdle;
    
    @Value("spring.datasource.hikari.initialization-fail-timeout")
    private long initializationFailTimeout;
    
    @Value("spring.datasource.hikari.isolate-internal-queries")
    private boolean isolateInternalQueries;
    
    @Value("spring.datasource.hikari.allow-pool-suspension")
    private boolean allowPoolSuspension;
    
    @Value("spring.datasource.hikari.read-only")
    private boolean readOnly;
    
    @Value("spring.datasource.hikari.register-mbeans")
    private boolean registerMbeans;
    
    @Value("spring.datasource.hikari.validation-timeout")
    private long validationTimeout;
    
    @Value("spring.datasource.hikari.leak-detection-threshold")
    private long leakDetectionThreshold;
}
