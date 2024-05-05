package com.example.springboot;

import java.util.Arrays;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Bean
    public CommandLineRunner commandLineRunner(ApplicationContext ctx) {
        return args -> {

            System.out.println("Let's inspect the application beans provided by Spring Boot:");

            String[] beanNames = ctx.getBeanDefinitionNames();
            
            Arrays.sort(beanNames);
            for (String beanName : beanNames) {
                if (beanName.endsWith("DataSource1") ||
                    beanName.endsWith("DataSource2") ||
                    beanName.endsWith("DataSource3") ||
                    beanName.endsWith("DataSource4") ||
                    (beanName.endsWith("DataSourceProperties") && !beanName.endsWith(".DataSourceProperties"))) {
                    System.out.println(beanName);
                }
            }

            (new HikariTest()).executeJmhRunner();
        };
    }
}
