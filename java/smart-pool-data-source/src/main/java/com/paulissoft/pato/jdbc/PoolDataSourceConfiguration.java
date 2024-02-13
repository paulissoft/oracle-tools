package com.paulissoft.pato.jdbc;

import javax.sql.DataSource;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;
import org.springframework.boot.context.properties.ConfigurationProperties;


@Data
@NoArgsConstructor
@SuperBuilder(toBuilder = true)
@ConfigurationProperties
public class PoolDataSourceConfiguration {

    private String driverClassName;

    private String url;
    
    private String username;

    private String password;

    private String type;

    public Class getType() {
        try {
            final Class cls = type != null ? Class.forName(type) : null;

            return cls != null && DataSource.class.isAssignableFrom(cls) ? cls : null;
        } catch (ClassNotFoundException ex) {
            return null;
        }
    }

    public void setType(final String type) {
        try {
            if (DataSource.class.isAssignableFrom(Class.forName(type))) {
                this.type = type;
            }
        } catch (ClassNotFoundException ex) {
            this.type = null;
        }
    }

    // copy parent fields
    public void copy(final PoolDataSourceConfiguration poolDataSourceConfiguration) {
        this.driverClassName = poolDataSourceConfiguration.driverClassName;
        this.url = poolDataSourceConfiguration.url;    
        this.username = poolDataSourceConfiguration.username;
        this.password = poolDataSourceConfiguration.password;
        this.type = poolDataSourceConfiguration.type;
    }

    public void clearCommonDataSourceConfiguration() {
        this.username = null;
        this.password = null;
    }
}
