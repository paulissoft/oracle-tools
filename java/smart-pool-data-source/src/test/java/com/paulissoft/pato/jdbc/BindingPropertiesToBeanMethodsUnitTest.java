package com.paulissoft.pato.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.HashMap;
import java.util.Map;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;

@ExtendWith(SpringExtension.class)
/**/@EnableConfigurationProperties(value = DataSourceConfiguration.class)
@ContextConfiguration(classes = ConfigurationFactory.class)
@TestPropertySource("classpath:application-test.properties")
public class BindingPropertiesToBeanMethodsUnitTest {

    @Autowired
    @Qualifier("spring-datasource")
    private DataSourceConfiguration dataSourceConfiguration;

    @Test
    void givenBeanAnnotatedMethod_whenBindingProperties_thenAllFieldsAreSet() {
        assertEquals("oracle.jdbc.OracleDriver", dataSourceConfiguration.getDriverClassName());
        assertEquals("jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1", dataSourceConfiguration.getUrl());
        assertEquals("system", dataSourceConfiguration.getUsername());
        assertEquals("change_on_install", dataSourceConfiguration.getPassword());
        assertEquals("com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari", dataSourceConfiguration.getType());
    }
}
