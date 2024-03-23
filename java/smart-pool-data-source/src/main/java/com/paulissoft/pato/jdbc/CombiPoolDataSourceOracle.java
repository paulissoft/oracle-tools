package com.paulissoft.pato.jdbc;

import lombok.extern.slf4j.Slf4j;
import oracle.ucp.jdbc.PoolDataSource;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.experimental.Delegate;
import java.sql.Connection;
import java.sql.SQLException;
//import javax.sql.DataSource;


@Slf4j
public class CombiPoolDataSourceOracle implements PoolDataSource, PoolDataSourcePropertiesOracle {

    private final PoolDataSource poolDataSourceConfig;

    private final PoolDataSource poolDataSourceExec;

    private boolean initializing = true;
    
    private CombiPoolDataSourceOracle() {
        this(null);
    }

    private CombiPoolDataSourceOracle(final PoolDataSource poolDataSourceConfig) {
        this(poolDataSourceConfig, null);
    }
    
    private CombiPoolDataSourceOracle(final PoolDataSource poolDataSourceConfig, final CombiPoolDataSourceOracle poolDataSourceExec) {
        this.poolDataSourceConfig = poolDataSourceConfig;
        this.poolDataSourceExec = poolDataSourceExec != null ? poolDataSourceExec.poolDataSourceExec : poolDataSourceConfig;
    }

    public static CombiPoolDataSourceOracle build(final PoolDataSource poolDataSourceConfig) {
        return new CombiPoolDataSourceOracle(poolDataSourceConfig);
    }
    
    public static CombiPoolDataSourceOracle build(final PoolDataSource poolDataSourceConfig, final CombiPoolDataSourceOracle poolDataSourceExec) {
        return new CombiPoolDataSourceOracle(poolDataSourceConfig, poolDataSourceExec);
    }

    @PostConstruct
    public void init() {
        if (initializing) {
            updatePool(poolDataSourceConfig, poolDataSourceExec);
            initializing = false;
        }
    }

    @PreDestroy
    public void done(){
        if (!initializing) {
            updatePool(poolDataSourceConfig, poolDataSourceExec);
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
        return poolDataSourceExec;
    }

    public Connection getConnection() throws SQLException {
        return null;
    }

    public Connection getConnection(String username, String password) throws SQLException {
        return null;
    }
    
    private static void updatePool(final PoolDataSource poolDataSourceConfig,
                                   final PoolDataSource poolDataSourceExec) {

    }
}
