package com.paulissoft.pato.jdbc;

import javax.sql.DataSource;
import lombok.experimental.Delegate;


public class PoolDataSourceProperties<T extends DataSource> implements DataSource {

    @Delegate(types=DataSource.class)
    private final T pds;

    private final String usernameSession1;

    private final String passwordSession1;

    private final String usernameSession2;

    protected static class BuildResult {
        final DataSource pds;

        final String username;

        final String password;
        
        BuildResult(final DataSource pds,
                    final String username,
                    final String password) {
            this.pds = pds;
            this.username = username;
            this.password = password;
        }
    }

    protected PoolDataSourceProperties(final BuildResult buildResult) {
        this.pds = (T) buildResult.pds;
        this.usernameSession1 = buildResult.username;
        this.passwordSession1 = buildResult.password;
        this.usernameSession2 = null;
    }

    protected T getPoolDataSource() {
        return pds;
    }
}
