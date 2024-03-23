package com.paulissoft.pato.jdbc;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.sql.Connection;
import java.sql.SQLException;
import javax.sql.DataSource;
import lombok.NonNull;


public abstract class CombiPoolDataSource<T extends DataSource> implements DataSource {

    @NonNull
    private final T poolDataSourceConfig;

    @NonNull
    private final T poolDataSourceExec;

    private boolean initializing = true;
    
    protected CombiPoolDataSource(@NonNull final T poolDataSourceConfig) {
        this(poolDataSourceConfig, null);
    }
    
    protected CombiPoolDataSource(@NonNull final T poolDataSourceConfig, final CombiPoolDataSource<T> poolDataSourceExec) {
        this.poolDataSourceConfig = poolDataSourceConfig;
        this.poolDataSourceExec = poolDataSourceExec != null ? poolDataSourceExec.poolDataSourceExec : poolDataSourceConfig;
    }

    @PostConstruct
    public void init() {
        if (initializing) {
            updatePool();
            initializing = false;
        }
    }

    @PreDestroy
    public void done(){
        if (!initializing) {
            updatePool();
            initializing = true;
        }
    }
    
    @Override
    public boolean equals(Object obj) {
        if (obj == null) {
            return false;
        }

        try {
            final T other = (T) obj;
        
            return other.toString().equals(this.toString());
        } catch (Exception ex) {
            return false;
        }
    }

    @Override
    public int hashCode() {
        return this.getPoolDataSourceConfiguration().hashCode();
    }

    @Override
    public String toString() {
        return this.getPoolDataSourceConfiguration().toString();
    }

    public abstract PoolDataSourceConfiguration getPoolDataSourceConfiguration();

    protected abstract void updatePool();

    // only setters and getters
    // @Delegate(types=P.class)
    protected T getPoolDataSourceConfig() {
        return poolDataSourceConfig;
    }

    protected interface ToOverride {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;
    }

    // the rest
    // @Delegate(excludes=ToOverride.class)
    protected T getPoolDataSourceExec() {        
        return initializing ? null : poolDataSourceExec;
    }
}
