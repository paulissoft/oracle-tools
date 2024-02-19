package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.SQLException;
import lombok.experimental.Delegate;
import oracle.ucp.jdbc.PoolDataSource;


public class SmartPoolDataSourceOracle extends SmartPoolDataSource implements PoolDataSource {

    private interface Overrides {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;
    }

    @Delegate(excludes=Overrides.class)
    protected PoolDataSource getCommonPoolDataSourceOracle() {
        return ((PoolDataSource)getCommonPoolDataSource());
    }
    
    public SmartPoolDataSourceOracle(final PoolDataSourceConfiguration pds,
                                     final SimplePoolDataSourceOracle commonPoolDataSource) throws SQLException {
        this(pds, commonPoolDataSource, true, false);        
    }

    private SmartPoolDataSourceOracle(final PoolDataSourceConfiguration pds,
                                      final SimplePoolDataSourceOracle commonPoolDataSource,
                                      final boolean singleSessionProxyModel,
                                      final boolean useFixedUsernamePassword) throws SQLException {
        super(pds, commonPoolDataSource, singleSessionProxyModel, useFixedUsernamePassword);
    }

    /*TBD*/
    /*
    protected String getPoolNamePrefix() {
        return "OraclePool";
    }
    */
}
