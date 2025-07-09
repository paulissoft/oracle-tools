package com.paulissoft.pato.jdbc;

import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.function.BiConsumer;
import java.util.function.Function;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.Objects;
import javax.sql.DataSource;

// a package accessible class
abstract class SharedPoolDataSource<T extends DataSource>  {
    private final String VALUES_ERROR = "Not all %s values are the same: %s.";
    
    final T ds;

    final CopyOnWriteArrayList<T> members = new CopyOnWriteArrayList<>();

    enum State {
        INITIALIZING, // a start state; next possible states: ERROR, OPEN or CLOSED
        ERROR,        // INITIALIZATING error; next possible states: CLOSED
        OPEN,         // next possible states: CLOSED
        CLOSED
    }

    volatile State state = State.INITIALIZING; // changed in methods open()/close()

    // constructors
    private SharedPoolDataSource() {
        this.ds = null;
    }

    SharedPoolDataSource(T ds) {
        this.ds = ds;
    }

    void add(T member) {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only add a member to the shared pool while initializing.");
        }

        members.add(member);
    }

    void remove(T member) {
        members.remove(member);

        if (members.size() == 0) {
            close();
        }
    }

    Boolean contains(T member) {
        return members.contains(member);
    }

    @SuppressWarnings("fallthrough")
    Connection getConnection() throws SQLException {
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

    Connection getConnection(String username, String password) throws SQLException {
        throw new SQLFeatureNotSupportedException("getConnection");
    }

    PrintWriter getLogWriter() throws SQLException {
        return ds.getLogWriter();
    }

    void setLogWriter(PrintWriter out) throws SQLException {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setLogWriter() while initializing.");
        }
        ds.setLogWriter(out);
    }

    void setLoginTimeout(int seconds) throws SQLException {
        if (state != State.INITIALIZING) {
            throw new IllegalStateException("You can only issue setLoginTimeout() while initializing.");
        }
        ds.setLoginTimeout(seconds);
    }

    int getLoginTimeout() throws SQLException {
        return ds.getLoginTimeout();
    }

    Logger getParentLogger() throws SQLFeatureNotSupportedException {
        return ds.getParentLogger();
    }

    <U> U unwrap(Class<U> iface) throws SQLException {
        return ds.unwrap(iface);
    }

    boolean isWrapperFor(Class<?> iface) throws SQLException {
        return ds.isWrapperFor(iface);
    }

    void configure() {
        if (members.isEmpty()) {
            throw new IllegalStateException("Members should have been added before you can configure.");
        }
    }

    void configureStringProperty(Function<T, String> getProperty,
				 BiConsumer<T, String> setProperty,
				 String description) {
        var stream = members.stream().map(getProperty);

        if (stream.filter(Objects::isNull).count() == members.size()) {
            /* all null */
            setProperty.accept(ds, null);
        } else if (stream.filter(Objects::nonNull).count() == members.size() &&
                   stream.filter(Objects::nonNull).distinct().count() == 1) {
            /* all not null and the same */
            setProperty.accept(ds, getProperty.apply(members.get(0)));
        } else {
            throw new IllegalStateException(String.format(VALUES_ERROR, stream.collect(Collectors.toList()).toString()));
        }
    }

    void configureIntegerProperty(Function<T, Integer> getProperty,
				  BiConsumer<T, Integer> setProperty,
				  String description) {
        var stream = members.stream().map(getProperty);

        if (stream.distinct().count() == 1) {
            /* all the same */
            setProperty.accept(ds, getProperty.apply(members.get(0)));
        } else {
            throw new IllegalStateException(String.format(VALUES_ERROR, description, stream.collect(Collectors.toList()).toString()));
        }
    }
    
    void configureLongProperty(Function<T, Long> getProperty,
                               BiConsumer<T, Long> setProperty,
                               String description) {
        var stream = members.stream().map(getProperty);

        if (stream.distinct().count() == 1) {
            /* all the same */
            setProperty.accept(ds, getProperty.apply(members.get(0)));
        } else {
            throw new IllegalStateException(String.format(VALUES_ERROR, description, stream.collect(Collectors.toList()).toString()));
        }
    }
    
    void configureBooleanProperty(Function<T, Boolean> getProperty,
                                  BiConsumer<T, Boolean> setProperty,
                                  String description) {
        var stream = members.stream().map(getProperty);

        if (stream.distinct().count() == 1) {
            /* all the same */
            setProperty.accept(ds, getProperty.apply(members.get(0)));
        } else {
            throw new IllegalStateException(String.format(VALUES_ERROR, description, stream.collect(Collectors.toList()).toString()));
        }
    }

    void open() {
        if (state == State.INITIALIZING) {
            synchronized(this) {
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
        }
    }

    abstract void close();

    abstract void setPassword(String password);

    abstract void setUsername(String username);

}    
