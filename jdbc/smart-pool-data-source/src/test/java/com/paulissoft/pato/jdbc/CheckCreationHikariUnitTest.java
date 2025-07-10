package com.paulissoft.pato.jdbc;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;
import oracle.jdbc.OracleConnection;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class CheckCreationHikariUnitTest {

    //=== Hikari ===

    @Test
    void testCreation() throws SQLException, IOException {
        // The class loader that loaded the class
        final ClassLoader classLoader = getClass().getClassLoader();
        final String fileName = "application-test.properties";
        final InputStream inputStream = classLoader.getResourceAsStream(fileName);

        // the stream holding the file content
        if (inputStream == null) {
            throw new IllegalArgumentException("file not found: " + fileName);
        }

        final Properties properties = new Properties();

        properties.load(inputStream);

        assertEquals("com.paulissoft.pato.jdbc.SmartPoolDataSourceHikari", properties.get("spring.datasource.hikari.type"));
        assertEquals("com.paulissoft.pato.jdbc.SmartPoolDataSourceOracle", properties.get("spring.datasource.oracleucp.type"));
    }
}
