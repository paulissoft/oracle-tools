package com.paulissoft.pato.jdbc.jmh;

//import java.util.Arrays;
//import java.util.List;

//import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
//import org.springframework.boot.ApplicationRunner;
//import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.autoconfigure.SpringBootApplication;
//import org.springframework.context.ApplicationContext;
//import org.springframework.context.annotation.Bean;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@SpringBootApplication
public class Application /*implements ApplicationRunner*/ {

    //private List<String> jmhFilter = null;
        
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
