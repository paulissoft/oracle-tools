package com.paulissoft.pato.jdbc.jmh;

import java.util.List;
import java.util.Vector;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;
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
import com.paulissoft.pato.jdbc.OverflowPoolDataSourceHikari;
import com.paulissoft.pato.jdbc.SmartPoolDataSourceHikari;

import oracle.ucp.jdbc.PoolDataSourceImpl;
import com.paulissoft.pato.jdbc.SimplePoolDataSourceOracle;
import com.paulissoft.pato.jdbc.CombiPoolDataSourceOracle;
import com.paulissoft.pato.jdbc.OverflowPoolDataSourceOracle;
import com.paulissoft.pato.jdbc.SmartPoolDataSourceOracle;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@State(Scope.Benchmark)
public class BenchmarkState {

    private static final int NR_CLASSES = 10;
    
    private final int[] logicalConnections = new int[] {20076, 10473, 10494, 14757, 19117, 14987};

    // length: # of classes
    private final DataSource[][] dataSources = {
        { null, null, null, null, null, null },
        { null, null, null, null, null, null },
        { null, null, null, null, null, null },
        { null, null, null, null, null, null },
        { null, null, null, null, null, null },
        { null, null, null, null, null, null },
        { null, null, null, null, null, null },
        { null, null, null, null, null, null },
        { null, null, null, null, null, null },
        { null, null, null, null, null, null }
    };
        
    // length: # of classes
    private static final AtomicLong[] count = {
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L)
    };

    // length: # of classes
    private static final AtomicLong[] ok = {
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L),
        new AtomicLong(0L)
    };

    @Param({/*"10000",*/ "500" })
    public int divideLogicalConnectionsBy;

    public List<Integer> testList = new Vector(1000, 1000);

    @Setup(Level.Trial)
    public void setUp() {
        final ApplicationContext context = SpringContext.getApplicationContext();

        // get instance of MainSpringClass (Spring Managed class)
        int d, t;
        
        for (d = 0; d < 2; d++) {
            for (t = 0; t < (NR_CLASSES / 2); t++) {
                final String suffix = "DataSource" + (d == 0 ? "Hikari" : "Oracle") + t;
                final int idx = d * (NR_CLASSES / 2) + t;
                
                dataSources[idx][0] = (DataSource) context.getBean("auth" + suffix);      
                dataSources[idx][1] = (DataSource) context.getBean("config" + suffix);
                dataSources[idx][2] = (DataSource) context.getBean("domain" + suffix);
                dataSources[idx][3] = (DataSource) context.getBean("ocpi" + suffix);
                dataSources[idx][4] = (DataSource) context.getBean("ocpp" + suffix);
                dataSources[idx][5] = (DataSource) context.getBean("operator" + suffix);

                if (d == 1 && t <= 1) {
                    final String className = (t == 0 ? PoolDataSourceImpl.class.getName() : SimplePoolDataSourceOracle.class.getName());
                    int s = 0;
                
                    for (DataSource ds : dataSources[idx]) {
                        try {
                            final PoolDataSourceImpl pds = (PoolDataSourceImpl) ds;
                            
                            pds.setConnectionPoolName(className + "-" + s++);
                        } catch (Exception ignore) {
                        }
                    }
                }
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

    public static int getClassIndex(final String className) {
        int d = -1, t = -1;

        if (className.equals(HikariDataSource.class.getName())) {
            d = 0; t = 0;
        } else if (className.equals(SimplePoolDataSourceHikari.class.getName())) {
            d = 0; t = 1;
        } else if (className.equals(CombiPoolDataSourceHikari.class.getName())) {
            d = 0; t = 2;
        } else if (className.equals(OverflowPoolDataSourceHikari.class.getName())) {
            d = 0; t = 3;
        } else if (className.equals(SmartPoolDataSourceHikari.class.getName())) {
            d = 0; t = 4;
        } else if (className.equals(PoolDataSourceImpl.class.getName())) {
            d = 1; t = 0;
        } else if (className.equals(SimplePoolDataSourceOracle.class.getName())) {
            d = 1; t = 1;
        } else if (className.equals(CombiPoolDataSourceOracle.class.getName())) {
            d = 1; t = 2;
        } else if (className.equals(OverflowPoolDataSourceOracle.class.getName())) {
            d = 1; t = 3;
        } else if (className.equals(SmartPoolDataSourceOracle.class.getName())) {
            d = 1; t = 4;
        } else {
            throw new RuntimeException("Can not map class '" + className + "' to an index.");
        }

        return d * 4 + t;
    }

    public DataSource[] getDataSources(final int classIndex) {
        return dataSources[classIndex];
    }

    public static void addOk(final int classIndex) {
        count[classIndex].incrementAndGet();
        ok[classIndex].incrementAndGet();
    }

    public static void addNotOk(final int classIndex) {
        count[classIndex].incrementAndGet();
    }
    
    public static long getCount(final int classIndex) {
        return count[classIndex].get();
    }
    
    public static long getOk(final int classIndex) {
        return ok[classIndex].get();
    }
    
    public void doSomeWork() throws InterruptedException {
        TimeUnit.MILLISECONDS.sleep(500);
    }
    
    // https://www.baeldung.com/java-generating-random-numbers-in-range
    private static int getRandomNumber(int min, int max) {
        return (int) ((Math.random() * (max - min)) + min);
    }
}
    
