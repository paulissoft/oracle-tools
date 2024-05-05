package com.example.springboot;

import java.util.Arrays;
import java.util.List;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@SpringBootApplication
public class Application implements ApplicationRunner {

    private List<String> jmhFilter = null;
        
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Bean
    public CommandLineRunner commandLineRunner(ApplicationContext ctx) {
        return args -> {

            if (log.isDebugEnabled()) {
                log.debug("Let's inspect the application beans provided by Spring Boot:");

                String[] beanNames = ctx.getBeanDefinitionNames();
            
                Arrays.sort(beanNames);
                for (String beanName : beanNames) {
                    if (beanName.endsWith("DataSourceHikari0") ||
                        beanName.endsWith("DataSourceHikari1") ||
                        beanName.endsWith("DataSourceHikari2") ||
                        beanName.endsWith("DataSourceHikari3") ||
                        (beanName.endsWith("DataSourceProperties") && !beanName.endsWith(".DataSourceHikariProperties"))) {
                        log.debug(beanName);
                    }
                }
            }

            BenchmarkTest.executeJmhRunner(jmhFilter);
        };
    }

    @Override
    public void run(ApplicationArguments args) throws Exception {
        System.out.println("# NonOptionArgs: " + args.getNonOptionArgs().size());

        System.out.println("NonOptionArgs:");
        args.getNonOptionArgs().forEach(System.out::println);

        // -Dspring-boot.run.arguments="abc def"
        jmhFilter = args.getNonOptionArgs();

        System.out.println("# OptionArgs: " + args.getOptionNames().size());
        System.out.println("OptionArgs:");

        args.getOptionNames().forEach(optionName -> {
            System.out.println(optionName + "=" + args.getOptionValues(optionName));
        });
    }
}
