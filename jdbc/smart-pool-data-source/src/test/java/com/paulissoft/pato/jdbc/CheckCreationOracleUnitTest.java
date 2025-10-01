package com.paulissoft.pato.jdbc;

import oracle.ucp.jdbc.PoolDataSourceImpl;
import java.io.IOException;
import java.io.InputStream;
import java.sql.SQLException;
import java.util.Properties;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

public class CheckCreationOracleUnitTest {

    //=== Oracle ===

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

        assertEquals("com.paulissoft.pato.jdbc.SmartPoolDataSourceOracle", properties.getProperty("spring.datasource.oracleucp.type"));

        final String username = properties.getProperty("spring.datasource.proxy.username");
        final String password = properties.getProperty("spring.datasource.proxy.password");
        final String jdbcUrl = properties.getProperty("spring.datasource.url");
        final String connectionFactoryClassName = properties.getProperty("spring.datasource.oracleucp.connection-factory-class-name");
    
        assertNotNull(username);
        assertNotNull(password);
        assertNotNull(jdbcUrl);
        assertNotNull(connectionFactoryClassName);

        for (int i = 0; i < 2; i++) {
            final PoolDataSourceImpl ds = (i == 0 ? new PoolDataSourceImpl() : new SmartPoolDataSourceOracle());
            
            ds.setUser(username);
            ds.setPassword(password);
            ds.setURL(jdbcUrl);
            ds.setConnectionFactoryClassName(connectionFactoryClassName);

            assertEquals(username, ds.getUser(), "try " + i);
            assertEquals(jdbcUrl, ds.getURL(), "try " + i);

            assertNotNull(ds.getConnection(), "try " + i);
        }
    }
}
