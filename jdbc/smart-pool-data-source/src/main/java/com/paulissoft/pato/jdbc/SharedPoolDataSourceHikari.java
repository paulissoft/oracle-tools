package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import java.sql.SQLException;


// a package accessible class
class SharedPoolDataSourceHikari extends SharedPoolDataSource<HikariDataSource> {

    // constructor
    SharedPoolDataSourceHikari() {
        super(new HikariDataSource());
    }

    @Override
    void initialize() {
        super.initialize();

        try {
            initializeIntProperty(HikariDataSource::getMinimumIdle,
                                  HikariDataSource::setMinimumIdle,
                                  "minimum idle",
                                  true);

            initializeIntProperty(HikariDataSource::getMaximumPoolSize,
                                  HikariDataSource::setMaximumPoolSize,
                                  "maximum pool size",
                                  true);

            // Must use lambda expressions for methods with primitive arguments or return values
            // since the functional interface does not support them all (boolean).
            // But auto-boxing handles this implicitly.
        
            // properties that may NOT differ, i.e. must be common

            // just a check: no need to invoke ds.setUsername() since that has been done already via SmartPoolDataSourceHikari.setUsername().
            checkStringProperty(HikariDataSource::getUsername, "username");

            initializeStringProperty(HikariDataSource::getCatalog, HikariDataSource::setCatalog, "catalog");

            initializeStringProperty(HikariDataSource::getConnectionInitSql, HikariDataSource::setConnectionInitSql, "connection init sql");

            initializeStringProperty(HikariDataSource::getDataSourceClassName, HikariDataSource::setDataSourceClassName, "data source class name");

            initializeStringProperty(HikariDataSource::getDataSourceJNDI, HikariDataSource::setDataSourceJNDI, "data source JNDI");

            initializeStringProperty(HikariDataSource::getDriverClassName, HikariDataSource::setDriverClassName, "driver class name");

            initializeBooleanProperty(HikariDataSource::isAllowPoolSuspension, HikariDataSource::setAllowPoolSuspension, "allow pool suspension");

            initializeBooleanProperty(HikariDataSource::isAutoCommit, HikariDataSource::setAutoCommit, "auto commit");
        
            initializeLongProperty(HikariDataSource::getConnectionTimeout, HikariDataSource::setConnectionTimeout, "connection timeout");

            initializeLongProperty(HikariDataSource::getIdleTimeout, HikariDataSource::setIdleTimeout, "idle timeout");

            initializeLongProperty(HikariDataSource::getInitializationFailTimeout,
                                   HikariDataSource::setInitializationFailTimeout,
                                   "initialization fail timeout");

            initializeStringProperty(HikariDataSource::getJdbcUrl, HikariDataSource::setJdbcUrl, "JDBC URL");

            // The functional interface does not allow checked exceptions so convert them into a RuntimeException (unchecked).
            final var valueLoginTimeout =
                determineIntProperty((ds) -> { try { return ds.getLoginTimeout(); } catch (SQLException ex) { throw new RuntimeException(ex); } },
                                     "login timeout");

            if (valueLoginTimeout != null) {
                ds.setLoginTimeout(valueLoginTimeout.get());
            }

            initializeLongProperty(HikariDataSource::getMaxLifetime, HikariDataSource::setMaxLifetime, "max lifetime");

            initializeBooleanProperty(HikariDataSource::isIsolateInternalQueries, HikariDataSource::setIsolateInternalQueries, "isolate internal queries");

            initializeBooleanProperty(HikariDataSource::isReadOnly, HikariDataSource::setReadOnly, "read only");

            initializeBooleanProperty(HikariDataSource::isRegisterMbeans, HikariDataSource::setRegisterMbeans, "register Mbeans");

            initializeStringProperty(HikariDataSource::getSchema, HikariDataSource::setSchema, "schema");

            initializeStringProperty(HikariDataSource::getTransactionIsolation, HikariDataSource::setTransactionIsolation, "transaction isolation");

            initializeLongProperty(HikariDataSource::getValidationTimeout, HikariDataSource::setValidationTimeout, "validation timeout");

            initializeLongProperty(HikariDataSource::getLeakDetectionThreshold, HikariDataSource::setLeakDetectionThreshold, "leak detection threshold");
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } 
    }

    void close() {
        ds.close();
        synchronized(this) {
            state = State.CLOSED;
        }
    }
}    
