package com.paulissoft.pato.jdbc.jmh;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@SpringBootApplication
public class Application {
        
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
