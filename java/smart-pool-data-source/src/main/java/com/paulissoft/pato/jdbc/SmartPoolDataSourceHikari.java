package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import java.io.Closeable;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;
import lombok.experimental.Delegate;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SmartPoolDataSourceHikari extends SmartPoolDataSource implements HikariConfigMXBean, Closeable {

    private static final Logger logger = LoggerFactory.getLogger(SmartPoolDataSourceHikari.class);

    static {
        logger.info("Initializing {}", SmartPoolDataSourceHikari.class.toString());
    }

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

    public SmartPoolDataSourceHikari(final SimplePoolDataSourceHikari pds,
                                     final String username,
                                     final String password) throws SQLException {
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

        this(pds, username, password, false, true);
    }
    
    private SmartPoolDataSourceHikari(final SimplePoolDataSourceHikari pds,
                                      final String username,
                                      final String password,
                                      final boolean singleSessionProxyModel,
                                      final boolean useFixedUsernamePassword) throws SQLException {
        
        /*
         * NOTE 2.
         *
         * The combination of singleSessionProxyModel true and useFixedUsernamePassword false does not work.
         * So when singleSessionProxyModel is true, useFixedUsernamePassword must be true as well.
         */
        super(pds,
              username,
              password,
              singleSessionProxyModel,
              singleSessionProxyModel || useFixedUsernamePassword);
    }

    @SuppressWarnings("deprecation")
    @Override
    public Connection getConnection(String username, String password) throws SQLException {
        return super.getConnection(username, password);
    }

    public void close() {
        if (done()) {
            getCommonPoolDataSourceHikari().close();
        }
    }

    protected String getPoolNamePrefix() {
        return "HikariPool";
    }
}
