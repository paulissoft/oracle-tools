package com.paulissoft.pato.jdbc;

// a package accessible class
interface StatisticsPoolDataSource {

    int getActiveConnections();

    int getIdleConnections();

    default int getTotalConnections() {
        return getActiveConnections() + getIdleConnections();
    }
}
