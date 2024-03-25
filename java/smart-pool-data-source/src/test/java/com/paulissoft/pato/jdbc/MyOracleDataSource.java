package com.paulissoft.pato.jdbc;

import java.sql.SQLException;
import lombok.extern.slf4j.Slf4j;


@Slf4j
public class MyOracleDataSource extends CombiPoolDataSourceOracle {

    // Since getPassword is deprecated in PoolDataSourceImpl
    // we need to store it here via setPassword()
    // and return it via getPassword().
    private String password;

    @Override
    public void setPassword(String password) throws SQLException {
        log.info("setPassword({})", password);
        super.setPassword(password);
        this.password = password;
    }

    @Override
    public String getPassword() {
        log.info("getPassword()");
        return password;
    }
}
