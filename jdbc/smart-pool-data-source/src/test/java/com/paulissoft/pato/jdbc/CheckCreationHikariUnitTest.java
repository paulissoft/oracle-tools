package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import java.io.IOException;
import java.io.InputStream;
import java.sql.SQLException;
import java.util.Properties;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

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

        assertEquals("com.paulissoft.pato.jdbc.SmartPoolDataSourceHikari", properties.getProperty("spring.datasource.hikari.type"));

        final String username = properties.getProperty("spring.datasource.proxy.username");
        final String password = properties.getProperty("spring.datasource.proxy.password");
        final String jdbcUrl = properties.getProperty("spring.datasource.url");

        assertNotNull(username);
        assertNotNull(password);
        assertNotNull(jdbcUrl);

        for (int i = 0; i < 2; i++) {
            try (HikariDataSource ds = (i == 0 ? new HikariDataSource() : new SmartPoolDataSourceHikari())) {
                ds.setUsername(username);
                ds.setPassword(password);
                ds.setJdbcUrl(jdbcUrl);

                assertEquals(username, ds.getUsername(), "try " + i);
                assertEquals(jdbcUrl, ds.getJdbcUrl(), "try " + i);

                assertNotNull(ds.getConnection(), "try " + i);
            }
        }
    }
}
