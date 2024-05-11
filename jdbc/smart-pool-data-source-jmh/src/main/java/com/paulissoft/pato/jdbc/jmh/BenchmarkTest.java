//package com.paulissoft.pato.jdbc;

package com.paulissoft.pato.jdbc.jmh;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.concurrent.TimeUnit;
import javax.sql.DataSource;
//import org.openjdk.jmh.annotations.Benchmark;
//import org.openjdk.jmh.annotations.BenchmarkMode;
//import org.openjdk.jmh.annotations.Mode;
//import org.openjdk.jmh.annotations.OutputTimeUnit;
//import org.openjdk.jmh.annotations.Scope;
//import org.openjdk.jmh.annotations.State;
import org.openjdk.jmh.infra.Blackhole;

import lombok.extern.slf4j.Slf4j;

@Slf4j
public class BenchmarkTest {

    DataSource[] dataSources = null;

    public void tearDown() throws Exception {
        if (dataSources != null) {
            int i;

            for (i = 0; i < dataSources.length; i++) {
                if (dataSources[i] instanceof AutoCloseable) {
                    ((AutoCloseable)dataSources[i]).close();
                }
            }
        }
    }

    public void connectAll(Blackhole bh,
                           BenchmarkState bs,
                           String dataSourceClassName) throws SQLException {
        dataSources = bs.getDataSources(dataSourceClassName);
        
        bs.testList.parallelStream().forEach(idx -> {
                try (final Connection conn = dataSources[idx].getConnection()) {
                    TimeUnit.SECONDS.sleep(1);
                    bh.consume(conn.getSchema());
                } catch (SQLException | InterruptedException ex) {
                    throw new RuntimeException(ex.getMessage());
                }});
    }
}
