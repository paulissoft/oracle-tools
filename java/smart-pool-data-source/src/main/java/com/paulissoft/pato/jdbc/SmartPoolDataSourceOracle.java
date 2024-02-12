package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.SQLException;
import javax.sql.DataSource;
import java.util.Properties;
import lombok.experimental.Delegate;
import oracle.ucp.jdbc.PoolDataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class SmartPoolDataSourceOracle extends SmartPoolDataSource implements PoolDataSource {
    // static stuff

    private static final Logger logger = LoggerFactory.getLogger(SmartPoolDataSourceOracle.class);

    static {
        logger.info("Initializing {}", SmartPoolDataSourceOracle.class.toString());
    }

    private interface Overrides {
        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;
    }

    @Delegate(excludes=Overrides.class)
    protected PoolDataSource getCommonPoolDataSourceOracle() {
        return ((PoolDataSource)getCommonPoolDataSource());
    }
    
    public SmartPoolDataSourceOracle(final SimplePoolDataSourceOracle pds,
                                     final String username,
                                     final String password) throws SQLException {
        this(pds, username, password, true, false);        
    }

    private SmartPoolDataSourceOracle(final SimplePoolDataSourceOracle pds,
                                      final String username,
                                      final String password,
                                      final boolean singleSessionProxyModel,
                                      final boolean useFixedUsernamePassword) throws SQLException {
        super(pds, username, password, singleSessionProxyModel, useFixedUsernamePassword);
    }
    
    protected String getPoolNamePrefix() {
        return "OraclePool";
    }    
}
