package com.paulissoft.pato.jdbc;

// a package accessible class
interface StatePoolDataSource {

    boolean isInitializing();
    
    boolean isNotInitializedCorrectly();

    boolean isOpen();

    boolean isClosed();
}
