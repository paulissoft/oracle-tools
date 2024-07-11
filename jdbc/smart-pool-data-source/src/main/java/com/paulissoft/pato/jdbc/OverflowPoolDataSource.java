package com.paulissoft.pato.jdbc;

import java.sql.Connection;
import java.sql.SQLException;
import lombok.NonNull;

public interface OverflowPoolDataSource {
    public Connection getConnection(@NonNull final String schema) throws SQLException;
}
