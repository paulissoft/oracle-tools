package com.paulissoft.pato.jdbc;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;
import org.springframework.boot.context.properties.ConfigurationProperties;


@Data
@NoArgsConstructor
@SuperBuilder(toBuilder = true)
@ConfigurationProperties
public class PoolDataSourceConfiguration {

    private int initialPoolSize;

    private int minPoolSize;

    private int maxPoolSize;
    
    private String connectionFactoryClassName;
}
