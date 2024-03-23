package com.paulissoft.pato.jdbc;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.sql.Connection;
import java.sql.SQLException;
import lombok.NonNull;
import lombok.experimental.Delegate;
import lombok.extern.slf4j.Slf4j;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceImpl;


@Slf4j
public class CombiPoolDataSourceOracle implements PoolDataSource, PoolDataSourcePropertiesOracle {

    @NonNull
    private final PoolDataSource poolDataSourceConfig;

    @NonNull
    private final PoolDataSource poolDataSourceExec;

    private boolean initializing = true;
    
    private CombiPoolDataSourceOracle() {
        this(new PoolDataSourceImpl());
    }

    private CombiPoolDataSourceOracle(@NonNull final PoolDataSource poolDataSourceConfig) {
        this(poolDataSourceConfig, null);
    }
    
    private CombiPoolDataSourceOracle(@NonNull final PoolDataSource poolDataSourceConfig, final CombiPoolDataSourceOracle poolDataSourceExec) {
        this.poolDataSourceConfig = poolDataSourceConfig;
        this.poolDataSourceExec = poolDataSourceExec != null ? poolDataSourceExec.poolDataSourceExec : poolDataSourceConfig;
    }

    public static CombiPoolDataSourceOracle build(@NonNull final PoolDataSource poolDataSourceConfig) {
        return new CombiPoolDataSourceOracle(poolDataSourceConfig);
    }
    
    public static CombiPoolDataSourceOracle build(@NonNull final PoolDataSource poolDataSourceConfig, final CombiPoolDataSourceOracle poolDataSourceExec) {
        return new CombiPoolDataSourceOracle(poolDataSourceConfig, poolDataSourceExec);
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

    // only setters and getters
    @Delegate(types=PoolDataSourcePropertiesOracle.class)
    private PoolDataSource getPoolDataSourceConfig() {
        return poolDataSourceConfig;
    }

    private interface ToOverride {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;

        //public PoolDataSourceConfiguration getPoolDataSourceConfiguration();
    }

    // the rest
    @Delegate(excludes=ToOverride.class)
    private PoolDataSource getPoolDataSourceExec() {        
        return initializing ? null : poolDataSourceExec;
    }

    public Connection getConnection() throws SQLException {
        return null;
    }

    public Connection getConnection(String username, String password) throws SQLException {
        return null;
    }
    
    private void updatePool() {
    }
}
