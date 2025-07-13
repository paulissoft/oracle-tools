package com.paulissoft.pato.jdbc;

// a package accessible class
interface StatePoolDataSource {

    boolean isInitializing();
    
    boolean hasInitializationError();

    boolean isOpen();

    boolean isClosed();
}
