package com.paulissoft.pato.jdbc;

// a package accessible class
interface StatePoolDataSource {

    boolean isInitializing();
    
    boolean hasInitializationError();

    boolean isOpen();

    boolean isClosed();

    default void checkInitializing(String method) {
        if (!isInitializing()) {
            throw new IllegalStateException("You can only issue method '" + method + "' while initializing.");
        }
    }

    default void checkNotInitializing(String method) {
        if (isInitializing()) {
            throw new IllegalStateException("You can only issue method '" + method + "' while NOT initializing.");
        }
    }
}
