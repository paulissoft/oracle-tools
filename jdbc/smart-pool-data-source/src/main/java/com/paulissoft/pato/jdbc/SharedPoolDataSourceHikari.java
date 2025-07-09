package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariConfigMXBean;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariPoolMXBean;
import com.zaxxer.hikari.metrics.MetricsTrackerFactory;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.util.Objects;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.function.BiConsumer;
import java.util.function.Function;
import java.util.logging.Logger;
import java.util.stream.Collectors;


// a package accessible class
class SharedPoolDataSourceHikari {
    private static final String USERNAMES_ERROR = "Not all usernames are the same and not null: %s.";

    private static final String DATA_SOURCE_CLASS_NAMES_ERROR = "Not all data source class names are the same: %s.";
        
    private final HikariDataSource ds = new HikariDataSource();

    private final CopyOnWriteArrayList<HikariDataSource> members = new CopyOnWriteArrayList<>();

    private enum State {
        INITIALIZING, // a start state; next possible states: ERROR, OPEN or CLOSED
        ERROR,        // INITIALIZATING error; next possible states: CLOSED
        OPEN,         // next possible states: CLOSED
        CLOSED
    }

    private volatile State state = State.INITIALIZING; // changed in a synchronized methods open()/close()

    public void add(HikariDataSource member) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only add a member to the shared pool while initializing.");
        }

        members.add(member);
    }

    public void remove(HikariDataSource member) {
        members.remove(member);

        if (members.size() == 0) {
            close();
        }
    }

    public Boolean contains(HikariDataSource member) {
        return members.contains(member);
    }

    @SuppressWarnings("fallthrough")
    public Connection getConnection() throws SQLException {
        switch (state) {
        case INITIALIZING:
            open(); // will change state to OPEN
            if (state != State.OPEN) {
                throw new IllegalStateException("After the pool data source is opened, the state must be OPEN.");
            }

            /* FALLTHROUGH */
        case OPEN:
            break;
        default:
            throw new IllegalStateException(String.format("You can only get a connection when the pool state is OPEN but it is %s.",
                                                          state));
        }

        return ds.getConnection();
    }

    public Connection getConnection(String username, String password) throws SQLException {
        throw new SQLFeatureNotSupportedException("getConnection");
    }

    public PrintWriter getLogWriter() throws SQLException {
        return ds.getLogWriter();
    }

    public void setLogWriter(PrintWriter out) throws SQLException {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setLogWriter() while initializing.");
        }
        ds.setLogWriter(out);
    }

    public void setLoginTimeout(int seconds) throws SQLException {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setLoginTimeout() while initializing.");
        }
        ds.setLoginTimeout(seconds);
    }

    public int getLoginTimeout() throws SQLException {
        return ds.getLoginTimeout();
    }

    public Logger getParentLogger() throws SQLFeatureNotSupportedException {
        return ds.getParentLogger();
    }

    public <T> T unwrap(Class<T> iface) throws SQLException {
        return ds.unwrap(iface);
    }

    public boolean isWrapperFor(Class<?> iface) throws SQLException {
        return ds.isWrapperFor(iface);
    }

    public void setMetricRegistry(Object metricRegistry) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setMetricRegistry() while initializing.");
        }
        ds.setMetricRegistry(metricRegistry);
    }
    
    public void setMetricsTrackerFactory(MetricsTrackerFactory metricsTrackerFactory) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setMetricsTrackerFactory() while initializing.");
        }
        ds.setMetricsTrackerFactory(metricsTrackerFactory);
    }

    public void setHealthCheckRegistry(Object healthCheckRegistry) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setHealthCheckRegistry() while initializing.");
        }
        ds.setHealthCheckRegistry(healthCheckRegistry);
    }

    public boolean isRunning() {
        return ds.isRunning();
    }

    public HikariPoolMXBean getHikariPoolMXBean() {
        return ds.getHikariPoolMXBean();
    }

    public HikariConfigMXBean getHikariConfigMXBean() {
        return ds.getHikariConfigMXBean();
    }

    public void evictConnection(Connection connection) {
        ds.evictConnection(connection);
    }

    public void setPassword(String password) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setPassword() while initializing.");
        }
        ds.setPassword(password);
    }
    
    public void setUsername(String username) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setUsername() while initializing.");
        }
        ds.setUsername(username);
    }

    // private stuff

    private void configure() {
        if (members.isEmpty()) {
            throw new IllegalStateException("Members should have been added before you can configure.");
        }
        
        ds.setMinimumIdle(members.stream().mapToInt(HikariDataSource::getMinimumIdle).sum());
        ds.setMaximumPoolSize(members.stream().mapToInt(HikariDataSource::getMaximumPoolSize).sum());

        // properties that may NOT differ, i.e. must be common

        // private String username;
        var streamUsername = members.stream().map(HikariDataSource::getUsername);

        // just a check: no need to invoke ds.setUsername() since that has been done already in SmartPoolDataSourceHikari
        if (!(streamUsername.filter(Objects::nonNull).count() == members.size() &&
              streamUsername.filter(Objects::nonNull).distinct().count() == 1)) {
            /* some null or not the same */
        } else {
            throw new IllegalStateException(String.format(USERNAMES_ERROR, streamUsername.collect(Collectors.toList()).toString()));
        }

        // private String dataSourceClassName;
        var streamDataSourceClassName = members.stream().map(HikariDataSource::getDataSourceClassName);

        if (streamDataSourceClassName.filter(Objects::isNull).count() == members.size()) {
            /* all null */
            ds.setDataSourceClassName(null);
        } else if (streamDataSourceClassName.filter(Objects::nonNull).count() == members.size() &&
                   streamDataSourceClassName.filter(Objects::nonNull).distinct().count() == 1) {
            /* all not null and the same */
            ds.setDataSourceClassName(members.get(0).getDataSourceClassName());
        } else {
            throw new IllegalStateException(String.format(DATA_SOURCE_CLASS_NAMES_ERROR, streamDataSourceClassName.collect(Collectors.toList()).toString()));
        }

        // Must use lambda expressions below since primitives are used and
        // the functional interface does not support them all (boolean).
        
        // private boolean autoCommit;
        configureBooleanProperty((ds) -> ds.isAutoCommit(),
                                 (ds, value) -> ds.setAutoCommit(value),
                                 "auto commit");
        
        // private long connectionTimeout;
        configureLongProperty((ds) -> ds.getConnectionTimeout(),
                              (ds, value) -> ds.setConnectionTimeout(value),
                              "connection timeout");

        // private long idleTimeout;
        configureLongProperty((ds) -> ds.getIdleTimeout(),
                              (ds, value) -> ds.setIdleTimeout(value),
                              "idle timeout");

        // private long maxLifetime;
        configureLongProperty((ds) -> ds.getMaxLifetime(),
                              (ds, value) -> ds.setMaxLifetime(value),
                              "max lifetime");

        // private long initializationFailTimeout;
        configureLongProperty((ds) -> ds.getInitializationFailTimeout(),
                              (ds, value) -> ds.setInitializationFailTimeout(value),
                              "initialization fail timeout");

        // private boolean isolateInternalQueries;
        configureBooleanProperty((ds) -> ds.isIsolateInternalQueries(),
                                 (ds, value) -> ds.setIsolateInternalQueries(value),
                                 "isolate internal queries");

        // private boolean allowPoolSuspension;
        configureBooleanProperty((ds) -> ds.isAllowPoolSuspension(),
                                 (ds, value) -> ds.setAllowPoolSuspension(value),
                                 "allow pool suspension");

        // private boolean readOnly;
        configureBooleanProperty((ds) -> ds.isReadOnly(),
                                 (ds, value) -> ds.setReadOnly(value),
                                 "read only");

        // private boolean registerMbeans;
        configureBooleanProperty((ds) -> ds.isRegisterMbeans(),
                                 (ds, value) -> ds.setRegisterMbeans(value),
                                 "register Mbeans");

        // private long validationTimeout;
        configureLongProperty((ds) -> ds.getValidationTimeout(),
                              (ds, value) -> ds.setValidationTimeout(value),
                              "validation timeout");

        // private long leakDetectionThreshold;
        configureLongProperty((ds) -> ds.getLeakDetectionThreshold(),
                              (ds, value) -> ds.setLeakDetectionThreshold(value),
                              "leak detection threshold");
    }

    private synchronized void open() {
        if (state == State.INITIALIZING) {
            try {
                configure();
                state = State.OPEN;                
            } catch (Exception ex) {
                state = State.ERROR;
                throw ex;
            }
        }
    }

    private void configureLongProperty(Function<HikariDataSource, Long> getProperty,
                                       BiConsumer<HikariDataSource, Long> setProperty,
                                       String description) {
        var stream = members.stream().map(getProperty);

        if (stream.distinct().count() == 1) {
            /* all the same */
            setProperty.accept(ds, getProperty.apply(members.get(0)));
        } else {
            throw new IllegalStateException(String.format("Not all %s values are the same: %s.", description, stream.collect(Collectors.toList()).toString()));
        }
    }

    private void configureBooleanProperty(Function<HikariDataSource, Boolean> getProperty,
                                          BiConsumer<HikariDataSource, Boolean> setProperty,
                                          String description) {
        var stream = members.stream().map(getProperty);

        if (stream.distinct().count() == 1) {
            /* all the same */
            setProperty.accept(ds, getProperty.apply(members.get(0)));
        } else {
            throw new IllegalStateException(String.format("Not all %s values are the same: %s.", description, stream.collect(Collectors.toList()).toString()));
        }
    }

    private synchronized void close() {
        ds.close();
        state = State.CLOSED;
    }
}    
