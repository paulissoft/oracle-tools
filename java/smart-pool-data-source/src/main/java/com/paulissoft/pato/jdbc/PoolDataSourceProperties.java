package com.paulissoft.pato.jdbc;

import javax.sql.DataSource;
import lombok.experimental.Delegate;


public class PoolDataSourceProperties<T extends DataSource> implements DataSource {

    @Delegate(types=DataSource.class)
    private final T pds;

    private final String usernameSession1;

    private final String passwordSession1;

    private final String usernameSession2;

    protected PoolDataSourceProperties(final Object[] fields) {
        this.pds = (T) fields[0];
        this.usernameSession1 = (String) fields[1];
        this.passwordSession1 = (String) fields[2];
        this.usernameSession2 = null;
    }

    protected T getPoolDataSource() {
        return pds;
    }
}
