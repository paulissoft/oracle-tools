package com.paulissoft.pato.jdbc.jmh;

import com.zaxxer.hikari.HikariDataSource;
import java.util.concurrent.ConcurrentHashMap;
import javax.sql.DataSource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;

import com.paulissoft.pato.jdbc.CombiPoolDataSourceHikari;
import com.paulissoft.pato.jdbc.CombiPoolDataSourceOracle;
import com.paulissoft.pato.jdbc.PoolDataSourceConfiguration;
import com.paulissoft.pato.jdbc.PoolDataSourceConfigurationCommonId;
import com.paulissoft.pato.jdbc.PoolDataSourceConfigurationHikari;
import com.paulissoft.pato.jdbc.PoolDataSourceConfigurationOracle;
import com.paulissoft.pato.jdbc.SimplePoolDataSource;
import com.paulissoft.pato.jdbc.SmartPoolDataSourceHikari;
import com.paulissoft.pato.jdbc.SmartPoolDataSourceOracle;


@Slf4j
public class MyDataSourceBuilder {

    private static final ConcurrentHashMap<PoolDataSourceConfigurationCommonId, DataSource> parents = new ConcurrentHashMap<>();

    public static DataSource build(final DataSourceProperties properties) {
        final Class cls = properties.getType() == null ? HikariDataSource.class : properties.getType();
        final String type = properties.getType() == null ? null : properties.getType().getName();
        PoolDataSourceConfiguration poolDataSourceConfiguration;

        log.debug("MyDataSourceBuilder.build(properties=(driverClassName={}, url={}, username={}, type={}))",
                  properties.getDriverClassName(),
                  properties.getUrl(),
                  properties.getUsername(),
                  type);       

        if (HikariDataSource.class.isAssignableFrom(cls)) {
            poolDataSourceConfiguration =
                PoolDataSourceConfigurationHikari.build(properties.getDriverClassName(),
                                                        properties.getUrl(),
                                                        properties.getUsername(),
                                                        properties.getPassword(),
                                                        type);
        } else {
            poolDataSourceConfiguration =
                PoolDataSourceConfigurationOracle.build(properties.getUrl(),
                                                        properties.getUsername(),
                                                        properties.getPassword(),
                                                        type);
        }
            
        final PoolDataSourceConfigurationCommonId commonId =
            new PoolDataSourceConfigurationCommonId(poolDataSourceConfiguration);
        final DataSource parentDataSource = parents.get(commonId);
        DataSource dataSource = null;

        log.debug("parentDataSource: {}; commonId: {}", parentDataSource, commonId);

        if (SmartPoolDataSourceHikari.class.isAssignableFrom(cls)) {
            dataSource = new SmartPoolDataSourceHikari(properties.getDriverClassName(),
                                                       properties.getUrl(),
                                                       properties.getUsername(),
                                                       properties.getPassword(),
                                                       type);
        } else if (SmartPoolDataSourceOracle.class.isAssignableFrom(cls)) {
            dataSource = new SmartPoolDataSourceOracle(properties.getUrl(),
                                                       properties.getUsername(),
                                                       properties.getPassword(),
                                                       type);
        } else if (parentDataSource != null &&
                   parentDataSource instanceof CombiPoolDataSourceHikari &&
                   CombiPoolDataSourceHikari.class.isAssignableFrom(cls)) {
            dataSource = new CombiPoolDataSourceHikari((CombiPoolDataSourceHikari) parentDataSource,
                                                       properties.getDriverClassName(),
                                                       properties.getUrl(),
                                                       properties.getUsername(),
                                                       properties.getPassword(),
                                                       type);
        } else if (parentDataSource != null &&
                   parentDataSource instanceof CombiPoolDataSourceOracle &&
                   CombiPoolDataSourceOracle.class.isAssignableFrom(cls)) {
            dataSource = new CombiPoolDataSourceOracle((CombiPoolDataSourceOracle) parentDataSource,
                                                       properties.getUrl(),
                                                       properties.getUsername(),
                                                       properties.getPassword(),
                                                       type);
        } else {
            dataSource = properties.initializeDataSourceBuilder().build(); // standard beans with setters

            final DataSource thisDataSource = dataSource;
            
            parents.computeIfAbsent(commonId, k -> thisDataSource); // dataSource must be final
        }

        log.debug("data source: {}", dataSource);
        if (dataSource instanceof SimplePoolDataSource) {
            log.debug("this pool data source configuration: {}", ((SimplePoolDataSource) dataSource).get());            
        }

        return dataSource;
    }
}
