package com.paulissoft.pato.jdbc;

import lombok.experimental.SuperBuilder;


@SuperBuilder(toBuilder = true)
public class PoolDataSourceConfiguration {

    private int initialPoolSize;

    private int minPoolSize;

    private int maxPoolSize;
    
    private String connectionFactoryClassName;
}
