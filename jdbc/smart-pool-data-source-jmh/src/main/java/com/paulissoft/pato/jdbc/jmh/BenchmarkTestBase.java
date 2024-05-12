package com.paulissoft.pato.jdbc.jmh;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.concurrent.TimeUnit;
import javax.sql.DataSource;
import oracle.ucp.jdbc.PoolDataSourceImpl;
import org.openjdk.jmh.annotations.BenchmarkMode;
import org.openjdk.jmh.annotations.Mode;
import org.openjdk.jmh.annotations.OutputTimeUnit;
import org.openjdk.jmh.annotations.Scope;
import org.openjdk.jmh.annotations.State;
import org.openjdk.jmh.infra.Blackhole;

import lombok.extern.slf4j.Slf4j;

@Slf4j
// JMH annotations
@State(Scope.Benchmark)
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
public class BenchmarkTestBase {

    DataSource[] dataSources = null;

    public void tearDown() throws Exception {
        if (dataSources != null) {
            for (DataSource ds : dataSources) {
                if (ds instanceof AutoCloseable) {
                    ((AutoCloseable)ds).close();
                }
            }
            dataSources = null;
        }
    }

    public void connectAll(Blackhole bh,
                           BenchmarkState bs,
                           String dataSourceClassName) throws SQLException {
        dataSources = bs.getDataSources(dataSourceClassName);

        try {
            bs.testList.parallelStream().forEach(idx -> {
                    try (final Connection conn = dataSources[idx].getConnection()) {
                        TimeUnit.SECONDS.sleep(1);
                        bh.consume(conn.getSchema());
                    } catch (SQLException | InterruptedException ex) {
                        if (ex.getMessage().contains("UCP-")) { // ignore UCP message for now
                            log.warn("UCP exception: {}", ex);
                        } else {
                            throw new RuntimeException(ex.getMessage());
                        }
                    }});
        } catch (Exception ex) {
            if (dataSources != null) {
                int nr = 0;
                
                for (DataSource ds : dataSources) {
                    try {
                        final PoolDataSourceImpl pds = (PoolDataSourceImpl) ds;
                        
                        log.warn("Connection pool name of data source # {}: {}", ++nr, pds.getConnectionPoolName());
                    } catch (Exception ignore) {
                    }
                }
            }
            throw ex;
        }
    }
}
