package com.paulissoft.pato.jdbc.jmh;

//import static org.junit.jupiter.api.Assertions.assertEquals;
//import static org.junit.jupiter.api.Assertions.assertNotEquals;
//import static org.junit.jupiter.api.Assertions.assertNull;

//import java.util.Arrays;

import org.junit.Test;
import org.openjdk.jmh.runner.RunnerException;
import org.junit.jupiter.api.extension.ExtendWith;
//import org.springframework.boot.test.context.SpringBootTest;
//import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.test.context.ContextConfiguration;
//import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@ExtendWith(SpringExtension.class)
//@SpringBootTest
//@EnableConfigurationProperties({MyDomainDataSourceHikari.class, MyOperatorDataSourceHikari.class})
@ContextConfiguration(classes={ConfigurationFactory.class, ConfigurationFactoryHikari.class, ConfigurationFactoryOracle.class})
//@TestPropertySource("classpath:application-test.properties")
public class BenchmarkTest extends BenchmarkTestRunner {

    public BenchmarkTest() {
    }

    @Test
    public void executeAll() throws RunnerException {
        BenchmarkTestRunner.execute(null); // all tests
    }
}
