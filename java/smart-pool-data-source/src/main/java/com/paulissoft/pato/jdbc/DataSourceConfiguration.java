package com.paulissoft.pato.jdbc;

import org.springframework.beans.factory.annotation.Autowired;
import javax.sql.DataSource;
import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Data
@NoArgsConstructor
@ConfigurationProperties
public class DataSourceConfiguration {

    private String driverClassName;

    private String url;
    
    private String username;

    private String password;

    private String type;
}
