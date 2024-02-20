package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import java.io.Closeable;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;
import lombok.experimental.Delegate;


public class SmartPoolDataSourceHikari extends SmartPoolDataSource implements HikariConfigMXBean, Closeable {

    private interface Overrides {
        public void close();

        public Connection getConnection() throws SQLException;

        public Connection getConnection(String username, String password) throws SQLException;

        /*
        // To solve this error:
        //
        // getDataSourceProperties() in nl.bluecurrent.backoffice.configuration.SmartPoolDataSourceHikari cannot override
        // getDataSourceProperties() in nl.bluecurrent.backoffice.configuration.SmartPoolDataSource
        // return type java.util.Properties is not compatible with org.springframework.boot.autoconfigure.jdbc.DataSourceProperties
        */
        public Properties getDataSourceProperties();
    }
    
    @Delegate(excludes=Overrides.class)
    protected HikariDataSource getCommonPoolDataSourceHikari() {
        return ((HikariDataSource)getCommonPoolDataSource());
    }

    public SmartPoolDataSourceHikari(final PoolDataSourceConfiguration pds,
                                     final SimplePoolDataSourceHikari commonPoolDataSource) {
        /*
         * NOTE 1.
         *
         * HikariCP does not support getConnection(String username, String password) so set
         * singleSessionProxyModel to false and useFixedUsernamePassword to true so the
         * common properties will include the proxy user name ("bc_proxy" from "bc_proxy[bodomain]")
         * if any else just the username. Meaning "bc_proxy[bodomain]", "bc_proxy[boauth]" and so one
         * will have ONE common pool data source.
         *
         * See also https://github.com/brettwooldridge/HikariCP/issues/231
         */

        this(pds, commonPoolDataSource, false, true);
    }
    
    private SmartPoolDataSourceHikari(final PoolDataSourceConfiguration pds,
                                      final SimplePoolDataSourceHikari commonPoolDataSource,
                                      final boolean singleSessionProxyModel,
                                      final boolean useFixedUsernamePassword) {
        
        /*
         * NOTE 2.
         *
         * The combination of singleSessionProxyModel true and useFixedUsernamePassword false does not work.
         * So when singleSessionProxyModel is true, useFixedUsernamePassword must be true as well.
         */
        super(pds,
              commonPoolDataSource,
              singleSessionProxyModel,
              singleSessionProxyModel || useFixedUsernamePassword);
    }

    @SuppressWarnings("deprecation")
    @Override
    public Connection getConnection(String username, String password) throws SQLException {
        return super.getConnection(username, password);
    }
}
