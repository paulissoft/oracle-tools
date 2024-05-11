package com.paulissoft.pato.jdbc.jmh;

import java.util.List;
import java.util.Vector;
import javax.sql.DataSource;
import org.openjdk.jmh.annotations.Level;
import org.openjdk.jmh.annotations.Param;
import org.openjdk.jmh.annotations.Scope;
import org.openjdk.jmh.annotations.Setup;
import org.openjdk.jmh.annotations.State;
import org.springframework.context.ApplicationContext;

import com.zaxxer.hikari.HikariDataSource;
import com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari;
import com.paulissoft.pato.jdbc.CombiPoolDataSourceHikari;
import com.paulissoft.pato.jdbc.SmartPoolDataSourceHikari;

import oracle.ucp.jdbc.PoolDataSourceImpl;
import com.paulissoft.pato.jdbc.SimplePoolDataSourceOracle;
import com.paulissoft.pato.jdbc.CombiPoolDataSourceOracle;
import com.paulissoft.pato.jdbc.SmartPoolDataSourceOracle;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@State(Scope.Benchmark)
public class BenchmarkState {

    private final int[] logicalConnections = new int[] {20076, 10473, 10494, 14757, 19117, 14987};

    public final DataSource[][][] dataSources = {
        { { null, null, null, null, null, null },
          { null, null, null, null, null, null },
          { null, null, null, null, null, null },
          { null, null, null, null, null, null } },
        { { null, null, null, null, null, null },
          { null, null, null, null, null, null },
          { null, null, null, null, null, null },
          { null, null, null, null, null, null } }
    };
        
    @Param({"10000"})
    public int divideLogicalConnectionsBy;

    public List<Integer> testList = new Vector(1000, 1000);

    @Setup(Level.Trial)
    public void setUp() {
        final ApplicationContext context = SpringContext.getApplicationContext();

        // get instance of MainSpringClass (Spring Managed class)
        int d, t;
        
        for (d = 0; d < 2; d++) {
            for (t = 0; t < 4; t++) {
                final String suffix = "DataSource" + (d == 0 ? "Hikari" : "Oracle") + t;
                
                dataSources[d][t][0] = (DataSource) context.getBean("auth" + suffix);      
                dataSources[d][t][1] = (DataSource) context.getBean("config" + suffix);
                dataSources[d][t][2] = (DataSource) context.getBean("domain" + suffix);
                dataSources[d][t][3] = (DataSource) context.getBean("ocpi" + suffix);
                dataSources[d][t][4] = (DataSource) context.getBean("ocpp" + suffix);
                dataSources[d][t][5] = (DataSource) context.getBean("operator" + suffix);
            }
        }

        final int[] logicalConnections = new int[this.logicalConnections.length];
        int totalLogicalConnections = 0;
        int idx;
            
        for (idx = 0; idx < logicalConnections.length; idx++) {
            logicalConnections[idx] = this.logicalConnections[idx] / divideLogicalConnectionsBy;

            log.debug("# logical connections for index {}: {}", idx, logicalConnections[idx]);
                            
            assert logicalConnections[idx] > 0;
            totalLogicalConnections += logicalConnections[idx];    
        }

        log.debug("# logical connections: {}", totalLogicalConnections);

        while (totalLogicalConnections > 0) {
            do {
                idx = getRandomNumber(0, logicalConnections.length);
            } while (logicalConnections[idx] == 0);

            assert logicalConnections[idx] > 0;

            logicalConnections[idx]--;
            totalLogicalConnections--;

            log.debug("adding index ", idx);
                
            testList.add(idx);
        }

        log.debug("# indexes: {}", testList.size());
    }

    public DataSource[] getDataSources(String className) {
        int d = -1, t = -1;

        if (className.equals(HikariDataSource.class.getName())) {
            d = 0; t = 0;
        } else if (className.equals(SimplePoolDataSourceHikari.class.getName())) {
            d = 0; t = 1;
        } else if (className.equals(CombiPoolDataSourceHikari.class.getName())) {
            d = 0; t = 2;
        } else if (className.equals(SmartPoolDataSourceHikari.class.getName())) {
            d = 0; t = 3;
        } else if (className.equals(PoolDataSourceImpl.class.getName())) {
            d = 1; t = 0;
        } else if (className.equals(SimplePoolDataSourceOracle.class.getName())) {
            d = 1; t = 1;
        } else if (className.equals(CombiPoolDataSourceOracle.class.getName())) {
            d = 1; t = 2;
        } else if (className.equals(SmartPoolDataSourceOracle.class.getName())) {
            d = 1; t = 3;
        }

        return dataSources[d][t];
    }
    
    // https://www.baeldung.com/java-generating-random-numbers-in-range
    private static int getRandomNumber(int min, int max) {
        return (int) ((Math.random() * (max - min)) + min);
    }
}
    
