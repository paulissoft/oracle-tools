package com.paulissoft.pato.jdbc;

import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.util.IntSummaryStatistics;
import java.util.LongSummaryStatistics;
import java.util.Optional;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.function.BiConsumer;
import java.util.function.Function;
import java.util.function.IntPredicate;
import java.util.function.LongPredicate;
import java.util.function.ObjIntConsumer;
import java.util.function.ObjLongConsumer;
import java.util.function.Predicate;
import java.util.function.Supplier;
import java.util.function.ToIntFunction;
import java.util.function.ToLongFunction;
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
        INITIALIZING,          // a start state; next possible states: INITIALIZATION_ERROR, OPEN or CLOSED
        INITIALIZATION_ERROR,  // INITIALIZATION error; next possible states: CLOSED
        OPEN,                  // next possible states: CLOSING, CLOSED
        CLOSING,               // at least one of the members has closed but not all
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
        if (members.remove(member)) {
            if (members.isEmpty()) {
                close();
            } else if (state == State.OPEN) {
                synchronized(this) {
                    if (state == State.OPEN) {
                        state = State.CLOSING;
                    }
                }
            }
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
        case CLOSING:
            break;
        default:
            throw new IllegalStateException(String.format("You can only get a connection when the pool state is OPEN (or CLOSING) but it is %s.",
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

    void initialize() {
        if (members.isEmpty()) {
            throw new IllegalStateException("Members should have been added before you can configure.");
        }
    }

    private static boolean eq(Object obj1, Object obj2) {
        return ((obj1 == null && obj2 == null) ||
                (obj1 != null && obj2 != null && obj1.equals(obj2)));
    }

    Optional<String> determineStringProperty(Function<T, String> getProperty,
                                             String description) {
        final var lastValue = getProperty.apply(ds);
        // a supplier to get different values (including null)
        final Supplier<Stream<String>> stream = () -> members.stream().map(getProperty).filter(value -> !eq(value, lastValue));

        if (stream.get().count() == 0L) {
            // all members still have the default, no need to set anything
            return null;
        } else if (stream.get().count() == members.size()) {
            // all members have a different value than the default: check they are all the same
            if (stream.get().distinct().count() == 1L) {
                return Optional.ofNullable(getProperty.apply(members.get(0)));
            }
        }

        // error
        throw new IllegalStateException(String.format(VALUES_ERROR, description, stream.get().collect(Collectors.toList()).toString()));        
    }

    void checkStringProperty(Function<T, String> getProperty,
                             String description) {
        // ignore result but just raise an exception in case of errors
        determineStringProperty(getProperty, description);
    }

    void initializeStringProperty(Function<T, String> getProperty,
                                  BiConsumer<T, String> setProperty,
                                  String description) {
        var result = determineStringProperty(getProperty, description);

        if (result != null) {
            setProperty.accept(ds, result.isPresent() ? result.get() : null);
        }
    }

    Optional<Integer> determineIntProperty(ToIntFunction<T> getProperty,
                                           String description) {
        return determineIntProperty(getProperty, description, false);
    }
    
    Optional<Integer> determineIntProperty(ToIntFunction<T> getProperty,
                                           String description,
                                           boolean sumAllMembers) {
        final var lastValue = getProperty.applyAsInt(ds);
        // a supplier to get different values
        final IntPredicate isCandidate = value -> (sumAllMembers ? value >= 0 && value != Integer.MAX_VALUE : value != lastValue);
        final Supplier<IntStream> stream = () -> members.stream().mapToInt(getProperty).filter(isCandidate);
        final IntSummaryStatistics summary = stream.get().summaryStatistics();

        if (summary.getCount() == 0L) {
            // all members still have the last, no need to set anything
            return null;
        } else if (summary.getCount() == members.size()) {
            // all members have a different value than the last: check they are all the same when NOT summing
            if (sumAllMembers || summary.getMin() == summary.getMax()) {
                return Optional.of(sumAllMembers ? (int) summary.getSum() : summary.getMin());
            }
        }

        // error
        throw new IllegalStateException(String.format(VALUES_ERROR, description, stream.get().boxed().collect(Collectors.toList()).toString()));
    }

    void initializeIntProperty(ToIntFunction<T> getProperty,
                               ObjIntConsumer<T> setProperty,
                               String description) {
        initializeIntProperty(getProperty, setProperty, description, false);
    }

    void initializeIntProperty(ToIntFunction<T> getProperty,
                               ObjIntConsumer<T> setProperty,
                               String description,
                               boolean sumAllMembers) {
        var result = determineIntProperty(getProperty, description, sumAllMembers);

        if (result != null) {
            setProperty.accept(ds, result.get());
        }
    }

    Optional<Long> determineLongProperty(ToLongFunction<T> getProperty,
                                         String description) {
        return determineLongProperty(getProperty, description, false);
    }
    
    Optional<Long> determineLongProperty(ToLongFunction<T> getProperty,
                                         String description,
                                         boolean sumAllMembers) {
        final var lastValue = getProperty.applyAsLong(ds);
        // a supplier to get different values
        final LongPredicate isCandidate = value -> (sumAllMembers ? value >= 0L && value != Long.MAX_VALUE : value != lastValue);
        final Supplier<LongStream> stream = () -> members.stream().mapToLong(getProperty).filter(isCandidate);
        final LongSummaryStatistics summary = stream.get().summaryStatistics();

        if (summary.getCount() == 0L) {
            // all members still have the last, no need to set anything
            return null;
        } else if (summary.getCount() == members.size()) {
            // all members have a different value than the last: check they are all the same when NOT summing
            if (sumAllMembers || summary.getMin() == summary.getMax()) {
                return Optional.of(sumAllMembers ? summary.getSum() : summary.getMin());
            }
        }

        // error
        throw new IllegalStateException(String.format(VALUES_ERROR, description, stream.get().boxed().collect(Collectors.toList()).toString()));
    }

    void initializeLongProperty(ToLongFunction<T> getProperty,
                                ObjLongConsumer<T> setProperty,
                                String description) {
        initializeLongProperty(getProperty, setProperty, description, false);
    }

    void initializeLongProperty(ToLongFunction<T> getProperty,
                                ObjLongConsumer<T> setProperty,
                                String description,
                                boolean sumAllMembers) {
        var result = determineLongProperty(getProperty, description, sumAllMembers);

        if (result != null) {
            setProperty.accept(ds, result.get());
        }
    }
    
    Optional<Boolean> determineBooleanProperty(Predicate<T> getProperty,
                                               String description) {
        // convert to int first
        var result = determineIntProperty((ds) -> (getProperty.test(ds) ? 1 : 0), description);

        if (result != null) {
            return Optional.of(result.get() != 0 ? true : false);
        }
        return null;
    }

    void initializeBooleanProperty(Predicate<T> getProperty,
                                   BiConsumer<T, Boolean> setProperty,
                                   String description) {
        var result = determineBooleanProperty(getProperty, description);

        if (result != null) {
            setProperty.accept(ds, result.get());
        }
    }

    void open() {
        if (state == State.INITIALIZING) {
            synchronized(this) {
                if (state == State.INITIALIZING) {
                    try {
                        initialize();
                        state = State.OPEN;                
                    } catch (Exception ex) {
                        state = State.INITIALIZATION_ERROR;
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

    public boolean hasInitializationError() {
        return state == State.INITIALIZATION_ERROR;
    }
    
    public boolean isOpen() {
        return state == State.OPEN;
    }

    public boolean isClosing() {
        return state == State.CLOSING;
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
