package com.paulissoft.pato.jdbc;

import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.util.IntSummaryStatistics;
import java.util.LongSummaryStatistics;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.function.BiConsumer;
import java.util.function.Function;
import java.util.function.ObjIntConsumer;
import java.util.function.ObjLongConsumer;
import java.util.function.Supplier;
import java.util.function.ToIntFunction;
import java.util.function.ToLongFunction;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import java.util.stream.LongStream;
import java.util.stream.Stream;
import javax.sql.DataSource;

// a package accessible class
abstract class SharedPoolDataSource<T extends DataSource> implements StatePoolDataSource {
    private final String VALUES_ERROR = "Not all %s values are the same: %s.";
    
    final T ds;

    final CopyOnWriteArrayList<T> members = new CopyOnWriteArrayList<>();

    enum State {
        INITIALIZING,               // a start state; next possible states: NOT_INITIALIZED_CORRECTLY, OPEN or CLOSED
        NOT_INITIALIZED_CORRECTLY,  // INITIALIZATING error; next possible states: CLOSED
        OPEN,                       // next possible states: CLOSED
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

    void configure() {
        if (members.isEmpty()) {
            throw new IllegalStateException("Members should have been added before you can configure.");
        }
    }

    private static boolean eq(Object obj1, Object obj2) {
        return ((obj1 == null && obj2 == null) ||
                (obj1 != null && obj2 != null && obj1.equals(obj2)));
    }

    boolean mustSetObjectProperty(Function<T, Object> getProperty,
                                  String description) {
        // the default value for this property since ds should not have been set
        final var defaultValue = getProperty.apply(ds);
        // a supplier to get different values (including null)
        final Supplier<Stream<Object>> stream = () -> members.stream().map(getProperty).filter(value -> !eq(value, defaultValue));

        if (stream.get().count() == 0L) {
            // all members still have the default, no need to set anything
            return false;
        } else if (stream.get().count() == members.size()) {
            // all members have a different value than the default: check they are all the same
            if (stream.get().distinct().count() == 1L) {
                return true;
            }
        }

        // error
        throw new IllegalStateException(String.format(VALUES_ERROR, description, stream.get().collect(Collectors.toList()).toString()));        
    }

    void checkStringProperty(Function<T, String> getProperty,
                             String description) {
        // ignore return value
        mustSetObjectProperty(e -> getProperty.apply(e), description);
    }

    void configureObjectProperty(Function<T, Object> getProperty,
                                 BiConsumer<T, Object> setProperty,
                                 String description) {
        if (mustSetObjectProperty(getProperty, description)) {
            var newValue = getProperty.apply(members.get(0));

            setProperty.accept(ds, newValue);
        }
    }

    void configureStringProperty(Function<T, String> getProperty,
                                 BiConsumer<T, String> setProperty,
                                 String description) {
        configureObjectProperty(e -> getProperty.apply(e),
                                (e, value) -> setProperty.accept(e, value.toString()),
                                description);
    }

    IntSummaryStatistics checkIntProperty(ToIntFunction<T> getProperty,
                                          String description,
                                          boolean sumAllMembers) {
        // the default value for this property since ds should not have been set
        final var defaultValue = getProperty.applyAsInt(ds);
        // a supplier to get different values
        final Supplier<IntStream> stream = () -> members.stream().mapToInt(getProperty).filter(value -> value != defaultValue);
        final IntSummaryStatistics summary = stream.get().summaryStatistics();

        if (summary.getCount() == 0L) {
            // all members still have the default, no need to set anything
            return null;
        } else if (summary.getCount() == members.size()) {
            // all members have a different value than the default: check they are all the same when NOT summing
            if (sumAllMembers || summary.getMin() == summary.getMax()) {
                return summary;
            }
        }

        // error
        throw new IllegalStateException(String.format(VALUES_ERROR, description, stream.get().boxed().collect(Collectors.toList()).toString()));
    }

    void configureIntProperty(ToIntFunction<T> getProperty,
                              ObjIntConsumer<T> setProperty,
                              String description) {
        configureIntProperty(getProperty, setProperty, description, false);
    }

    void configureIntProperty(ToIntFunction<T> getProperty,
                              ObjIntConsumer<T> setProperty,
                              String description,
                              boolean sumAllMembers) {
        final IntSummaryStatistics summary = checkIntProperty(getProperty, description, sumAllMembers);

        if (summary != null) {
            setProperty.accept(ds, (sumAllMembers ? (int) summary.getSum() : summary.getMin()));
        }
    }

    LongSummaryStatistics checkLongProperty(ToLongFunction<T> getProperty,
                                            String description,
                                            boolean sumAllMembers) {
        // the default value for this property since ds should not have been set
        final var defaultValue = getProperty.applyAsLong(ds);
        // a supplier to get different values
        final Supplier<LongStream> stream = () -> members.stream().mapToLong(getProperty).filter(value -> value != defaultValue);
        final LongSummaryStatistics summary = stream.get().summaryStatistics();

        if (summary.getCount() == 0L) {
            // all members still have the default, no need to set anything
            return null;
        } else if (summary.getCount() == members.size()) {
            // all members have a different value than the default: check they are all the same when NOT summing
            if (sumAllMembers || summary.getMin() == summary.getMax()) {
                return summary;
            }
        }

        // error
        throw new IllegalStateException(String.format(VALUES_ERROR, description, stream.get().boxed().collect(Collectors.toList()).toString()));
    }

    void configureLongProperty(ToLongFunction<T> getProperty,
                               ObjLongConsumer<T> setProperty,
                               String description) {
        configureLongProperty(getProperty, setProperty, description, false);
    }

    void configureLongProperty(ToLongFunction<T> getProperty,
                               ObjLongConsumer<T> setProperty,
                               String description,
                               boolean sumAllMembers) {
        final LongSummaryStatistics summary = checkLongProperty(getProperty, description, sumAllMembers);

        if (summary != null) {
            setProperty.accept(ds, (sumAllMembers ? summary.getSum() : summary.getMin()));
        }
    }
    
    void configureBooleanProperty(Function<T, Boolean> getProperty,
                                  BiConsumer<T, Boolean> setProperty,
                                  String description) {
        // convert to int first
        configureIntProperty((ds) -> (getProperty.apply(ds) ? 1 : 0),
                             (ds, value) -> setProperty.accept(ds, value != 0),
                             description);
    }

    void open() {
        if (state == State.INITIALIZING) {
            synchronized(this) {
                if (state == State.INITIALIZING) {
                    try {
                        configure();
                        state = State.OPEN;                
                    } catch (Exception ex) {
                        state = State.NOT_INITIALIZED_CORRECTLY;
                        throw ex;
                    }
                }
            }               
        }
    }

    /*
    // Start of interface StatePoolDataSource
    */

    public boolean isInitializing() {
        return state == State.INITIALIZING;
    }

    public boolean isNotInitializedCorrectly() {
        return state == State.NOT_INITIALIZED_CORRECTLY;
    }
    
    public boolean isOpen() {
        return state == State.OPEN;
    }

    public boolean isClosed() {
        return state == State.CLOSED;
    }

    /*
    // End of interface StatePoolDataSource
    */

    abstract void close();

    abstract void setPassword(String password);

    abstract void setUsername(String username);

}    
