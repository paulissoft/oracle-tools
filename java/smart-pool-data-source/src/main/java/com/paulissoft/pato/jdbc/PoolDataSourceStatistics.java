package com.paulissoft.pato.jdbc;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;
import oracle.jdbc.OracleConnection;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.function.Supplier;

public class PoolDataSourceStatistics {

    // all static stuff
    
    private static final Logger logger = LoggerFactory.getLogger(PoolDataSourceStatistics.class);

    static final String INDENT_PREFIX = "* ";

    static final String TOTAL = "total";

    public static final String EXCEPTION_CLASS_NAME = "class";

    public static final String EXCEPTION_SQL_ERROR_CODE = "SQL error code";

    public static final String EXCEPTION_SQL_STATE = "SQL state";

    private static final int ROUND_SCALE = 32;

    private static final int DISPLAY_SCALE = 0;

    private static Method loggerInfo;

    private static Method loggerDebug;

    static final PoolDataSourceStatistics poolDataSourceStatisticsGrandTotal = new PoolDataSourceStatistics(() -> "pool: (all)");

    static {
        logger.info("Initializing {}", PoolDataSourceStatistics.class.toString());
        
        try {
            loggerInfo = logger.getClass().getMethod("info", String.class, Object[].class);
        } catch (Exception e) {
            logger.error(exceptionToString(e));
            loggerInfo = null;
        }

        try {
            loggerDebug = logger.getClass().getMethod("debug", String.class, Object[].class);
        } catch (Exception e) {
            logger.error(exceptionToString(e));
            loggerDebug = null;
        }
    }

    // all instance stuff
    
    private Supplier<String> nameSupplier = null;

    private int level;

    // all physical time elapsed stuff
    
    private Set<OracleConnection> physicalConnections = null;

    private AtomicLong physicalConnectionCount = new AtomicLong();

    private AtomicLong physicalTimeElapsedMin = new AtomicLong(Long.MAX_VALUE);
    
    private AtomicLong physicalTimeElapsedMax = new AtomicLong(Long.MIN_VALUE);
    
    private AtomicBigDecimal physicalTimeElapsedAvg = new AtomicBigDecimal(BigDecimal.ZERO);

    // all logical time elapsed stuff
    
    private AtomicLong logicalConnectionCount = new AtomicLong();

    private AtomicLong logicalTimeElapsedMin = new AtomicLong(Long.MAX_VALUE);
    
    private AtomicLong logicalTimeElapsedMax = new AtomicLong(Long.MIN_VALUE);
    
    private AtomicBigDecimal logicalTimeElapsedAvg = new AtomicBigDecimal(BigDecimal.ZERO);

    // all proxy time elapsed stuff

    private AtomicLong proxyLogicalConnectionCount = new AtomicLong();
        
    private AtomicLong proxyOpenSessionCount = new AtomicLong();
        
    private AtomicLong proxyCloseSessionCount = new AtomicLong();

    private AtomicLong proxyTimeElapsedMin = new AtomicLong(Long.MAX_VALUE);
    
    private AtomicLong proxyTimeElapsedMax = new AtomicLong(Long.MIN_VALUE);
    
    private AtomicBigDecimal proxyTimeElapsedAvg = new AtomicBigDecimal(BigDecimal.ZERO);

    // all connection related stuff

    private AtomicLong activeConnectionsMin = new AtomicLong(Long.MAX_VALUE);
        
    private AtomicLong activeConnectionsMax = new AtomicLong(Long.MIN_VALUE);

    private AtomicBigDecimal activeConnectionsAvg = new AtomicBigDecimal(BigDecimal.ZERO);
            
    private AtomicLong idleConnectionsMin = new AtomicLong(Long.MAX_VALUE);
        
    private AtomicLong idleConnectionsMax = new AtomicLong(Long.MIN_VALUE);

    private AtomicBigDecimal idleConnectionsAvg = new AtomicBigDecimal(BigDecimal.ZERO);
            
    private AtomicLong totalConnectionsMin = new AtomicLong(Long.MAX_VALUE);
        
    private AtomicLong totalConnectionsMax = new AtomicLong(Long.MIN_VALUE);

    private AtomicBigDecimal totalConnectionsAvg = new AtomicBigDecimal(BigDecimal.ZERO);

    // the error attributes (error code and SQL state) and its count
    private ConcurrentHashMap<Properties, AtomicLong> errors = new ConcurrentHashMap<>();

    private PoolDataSourceStatistics parent = null;

    public PoolDataSourceStatistics() {
        this(null);
    }
        
    public PoolDataSourceStatistics(final Supplier<String> nameSupplier) {
        this(nameSupplier, null);
    }
        
    public PoolDataSourceStatistics(final Supplier<String> nameSupplier, final PoolDataSourceStatistics parent) {
        this.nameSupplier = nameSupplier;
        this.parent = parent;

        // only the overall instance tracks note of physical connections
        if (parent == null) {
            // see https://www.geeksforgeeks.org/how-to-create-a-thread-safe-concurrenthashset-in-java/
            final ConcurrentHashMap<Connection, Integer> dummy = new ConcurrentHashMap<>();
 
            this.physicalConnections = dummy.newKeySet();

            level = 1;
        } else {
            level = 1 + parent.level;
        }
    }

    private String getName() {
        return nameSupplier != null ? nameSupplier.get() : null;
    }
        
    void update(final Connection conn,
                final long timeElapsed) throws SQLException {
        final boolean isPhysicalConnection = add(conn);
            
        // We must use count and avg from the same connection so just synchronize.
        // If we don't synchronize we risk to get the average and count from different connections.
        synchronized (this) {                
            BigDecimal count = new BigDecimal(isPhysicalConnection ?
                                              this.physicalConnectionCount.incrementAndGet() :
                                              this.logicalConnectionCount.incrementAndGet());

            if (isPhysicalConnection) {
                updateIterativeMean(count, timeElapsed, physicalTimeElapsedAvg);
            } else {
                updateIterativeMean(count, timeElapsed, logicalTimeElapsedAvg);
            }
        }

        // The rest is using AtomicLong, hence concurrent.
        if (isPhysicalConnection) {
            updateMinMax(timeElapsed, physicalTimeElapsedMin, physicalTimeElapsedMax);
        } else {
            updateMinMax(timeElapsed, logicalTimeElapsedMin, logicalTimeElapsedMax);
        }
    }

    void update(final Connection conn,
                final long timeElapsed,
                final long proxyTimeElapsed,
                final int proxyLogicalConnectionCount,
                final int proxyOpenSessionCount,
                final int proxyCloseSessionCount) throws SQLException {
        final boolean isPhysicalConnection = add(conn);
            
        // We must use count and avg from the same connection so just synchronize.
        // If we don't synchronize we risk to get the average and count from different connections.
        synchronized (this) {                
            BigDecimal count = new BigDecimal(isPhysicalConnection ?
                                              this.physicalConnectionCount.incrementAndGet() :
                                              this.logicalConnectionCount.incrementAndGet());

            if (isPhysicalConnection) {
                updateIterativeMean(count, timeElapsed, physicalTimeElapsedAvg);
            } else {
                updateIterativeMean(count, timeElapsed, logicalTimeElapsedAvg);
            }

            // add the other part as well
            count = count.add(new BigDecimal(!isPhysicalConnection ?
                                             this.physicalConnectionCount.get() :
                                             this.logicalConnectionCount.get()));

            updateIterativeMean(count, proxyTimeElapsed, proxyTimeElapsedAvg);
        }

        // The rest is using AtomicLong, hence concurrent.
        if (isPhysicalConnection) {
            updateMinMax(timeElapsed, physicalTimeElapsedMin, physicalTimeElapsedMax);
        } else {
            updateMinMax(timeElapsed, logicalTimeElapsedMin, logicalTimeElapsedMax);
        }        
        updateMinMax(proxyTimeElapsed, proxyTimeElapsedMin, proxyTimeElapsedMax);
            
        this.proxyLogicalConnectionCount.addAndGet(proxyLogicalConnectionCount);
        this.proxyOpenSessionCount.addAndGet(proxyOpenSessionCount);
        this.proxyCloseSessionCount.addAndGet(proxyCloseSessionCount);
    }

    void update(final int activeConnections,
                final int idleConnections,
                final int totalConnections) /*throws SQLException*/ {
        // We must use count and avg from the same connection so just synchronize.
        // If we don't synchronize we risk to get the average and count from different connections.
        synchronized (this) {                
            BigDecimal count = new BigDecimal(getConnectionCount());
            
            updateIterativeMean(count, activeConnections, activeConnectionsAvg);
            updateIterativeMean(count, idleConnections, idleConnectionsAvg);
            updateIterativeMean(count, totalConnections, totalConnectionsAvg);
        }

        updateMinMax(activeConnections, activeConnectionsMin, activeConnectionsMax);
        updateMinMax(idleConnections, idleConnectionsMin, idleConnectionsMax);
        updateMinMax(totalConnections, totalConnectionsMin, totalConnectionsMax);
    }

    private boolean add(final Connection conn) throws SQLException {
        return ( parent != null ? parent.add(conn) : physicalConnections.add(conn.unwrap(OracleConnection.class)) );
    }
    
    long signalSQLException(final SQLException ex) {
        final Properties attrs = new Properties();

        attrs.setProperty(EXCEPTION_CLASS_NAME, ex.getClass().getName());
        attrs.setProperty(EXCEPTION_SQL_ERROR_CODE, String.valueOf(ex.getErrorCode()));
        attrs.setProperty(EXCEPTION_SQL_STATE, ex.getSQLState());
            
        return this.errors.computeIfAbsent(attrs, msg -> new AtomicLong(0)).incrementAndGet();
    }
        
    long signalException(final Exception ex) {
        final Properties attrs = new Properties();

        attrs.setProperty(EXCEPTION_CLASS_NAME, ex.getClass().getName());
            
        return this.errors.computeIfAbsent(attrs, msg -> new AtomicLong(0)).incrementAndGet();
    }
        
    // Iterative Mean, see https://www.heikohoffmann.de/htmlthesis/node134.html
                
    // See https://stackoverflow.com/questions/4591206/
    //   arithmeticexception-non-terminating-decimal-expansion-no-exact-representable
    // to prevent this error: Non-terminating decimal expansion; no exact representable decimal result.
    private void updateIterativeMean(final BigDecimal count, final long value, final AtomicBigDecimal avg) {
        if (value >= 0L) {
            avg.addAndGet(new BigDecimal(value).subtract(avg.get()).divide(count,
                                                                           ROUND_SCALE,
                                                                           RoundingMode.HALF_UP));
        }
    }

    private void updateMinMax(final long value, final AtomicLong min, final AtomicLong max) {
        if (value >= 0) {
            if (value < min.get()) {
                min.set(value);
            }
            if (value > max.get()) {
                max.set(value);
            }
        }
    }

    boolean countersEqual(final PoolDataSourceStatistics compareTo) {
        return
            this.getPhysicalConnectionCount() == compareTo.getPhysicalConnectionCount() &&
            this.getLogicalConnectionCount() == compareTo.getLogicalConnectionCount() &&
            this.getProxyLogicalConnectionCount() == compareTo.getProxyLogicalConnectionCount() &&
            this.getProxyOpenSessionCount() == compareTo.getProxyOpenSessionCount() &&
            this.getProxyCloseSessionCount() == compareTo.getProxyCloseSessionCount();
    }

    public void showStatistics(final SimplePoolDataSource pds,
                               final long timeElapsed,
                               final long proxyTimeElapsed,
                               final boolean showTotals) {
        if (!showTotals && !logger.isDebugEnabled()) {
            return;
        }
        
        final Method method = (showTotals ? loggerInfo : loggerDebug);

        final boolean isTotal = level == 2;
        final boolean isGrandTotal = level == 1;
        final boolean showPoolSizes = isTotal;
        final boolean showErrors = showTotals && (isTotal || isGrandTotal);
        final String prefix = INDENT_PREFIX;
        final String poolDescription = getName();

        try {
            if (method != null) {
                method.invoke(logger, "statistics for {}:", (Object) new Object[]{ poolDescription });
            
                if (!showTotals) {
                    if (timeElapsed >= 0L) {
                        method.invoke(logger,
                                      "{}time needed to open last connection (ms): {}",
                                      (Object) new Object[]{ prefix, timeElapsed });
                    }
                    if (proxyTimeElapsed >= 0L) {
                        method.invoke(logger,
                                      "{}time needed to open last proxy connection (ms): {}",
                                      (Object) new Object[]{ prefix, proxyTimeElapsed });
                    }
                }
            
                long val1, val2, val3;

                val1 = getPhysicalConnectionCount();
                val2 = getLogicalConnectionCount();
            
                if (val1 >= 0L && val2 >= 0L) {
                    method.invoke(logger,
                                  "{}physical/logical connections opened: {}/{}",
                                  (Object) new Object[]{ prefix, val1, val2 });
                }

                val1 = getPhysicalTimeElapsedMin();
                val2 = getPhysicalTimeElapsedAvg();
                val3 = getPhysicalTimeElapsedMax();

                if (val1 >= 0L && val2 >= 0L && val3 >= 0L) {
                    method.invoke(logger,
                                  "{}min/avg/max physical connection time (ms): {}/{}/{}",
                                  (Object) new Object[]{ prefix, val1, val2, val3 });
                }
            
                val1 = getLogicalTimeElapsedMin();
                val2 = getLogicalTimeElapsedAvg();
                val3 = getLogicalTimeElapsedMax();

                if (val1 >= 0L && val2 >= 0L && val3 >= 0L) {
                    method.invoke(logger,
                                  "{}min/avg/max logical connection time (ms): {}/{}/{}",
                                  (Object) new Object[]{ prefix, val1, val2, val3 });
                }
            
                val1 = getProxyTimeElapsedMin();
                val2 = getProxyTimeElapsedAvg();
                val3 = getProxyTimeElapsedMax();

                if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                    (val1 >= 0L || val2 > 0L || val3 > 0L)) {
                    method.invoke(logger,
                                  "{}min/avg/max proxy connection time (ms): {}/{}/{}",
                                  (Object) new Object[]{ prefix, val1, val2, val3 });
                }

                val1 = getProxyOpenSessionCount();
                val2 = getProxyCloseSessionCount();
                val3 = getProxyLogicalConnectionCount();
                
                if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                    (val1 >= 0L || val2 > 0L || val3 > 0L)) {
                    method.invoke(logger,
                                  "{}proxy sessions opened/closed: {}/{}; logical connections rejected while searching for optimal proxy session: {}",
                                  (Object) new Object[]{ prefix, val1, val2, val3 });
                }
            
                if (showPoolSizes) {
                    method.invoke(logger,
                                  "{}initial/min/max pool size: {}/{}/{}",
                                  (Object) new Object[]{ prefix,
                                                         pds.getInitialPoolSize(),
                                                         pds.getMinPoolSize(),
                                                         pds.getMaxPoolSize() });
                }

                if (!showTotals) {
                    // current values
                    val1 = pds.getActiveConnections();
                    val2 = pds.getIdleConnections();
                    val3 = pds.getTotalConnections();
                    
                    if (val1 >= 0L && val2 >= 0L && val3 >= 0L) {
                        method.invoke(logger,
                                      "{}current active/idle/total connections: {}/{}/{}",
                                      (Object) new Object[]{ prefix, val1, val2, val3 });
                    }
                } else {
                    val1 = getActiveConnectionsMin();
                    val2 = getActiveConnectionsAvg();
                    val3 = getActiveConnectionsMax();

                    if (val1 >= 0L && val2 >= 0L && val3 >= 0L) {
                        method.invoke(logger,
                                      "{}min/avg/max active connections: {}/{}/{}",
                                      (Object) new Object[]{ prefix, val1, val2, val3 });
                    }
                    
                    val1 = getIdleConnectionsMin();
                    val2 = getIdleConnectionsAvg();
                    val3 = getIdleConnectionsMax();

                    if (val1 >= 0L && val2 >= 0L && val3 >= 0L) {
                        method.invoke(logger,
                                      "{}min/avg/max idle connections: {}/{}/{}",
                                      (Object) new Object[]{ prefix, val1, val2, val3 });
                    }

                    val1 = getTotalConnectionsMin();
                    val2 = getTotalConnectionsAvg();
                    val3 = getTotalConnectionsMax();

                    if (val1 >= 0L && val2 >= 0L && val3 >= 0L) {
                        method.invoke(logger,
                                      "{}min/avg/max total connections: {}/{}/{}",
                                      (Object) new Object[]{ prefix, val1, val2, val3 });
                    }
                }
            }

            // show errors
            if (showErrors) {
                final Map<Properties, Long> errors = getErrors();

                if (errors.isEmpty()) {
                    logger.info("no connection exceptions signalled for {}", poolDescription);
                } else {
                    logger.warn("connection exceptions signalled in decreasing number of occurrences for {}:", poolDescription);
                
                    errors.entrySet().stream()
                        .sorted(Collections.reverseOrder(Map.Entry.comparingByValue())) // sort by decreasing number of errors
                        .forEach(e -> {
                                final Properties key = (Properties) e.getKey();
                                final String className = key.getProperty(PoolDataSourceStatistics.EXCEPTION_CLASS_NAME);
                                final String SQLErrorCode = key.getProperty(PoolDataSourceStatistics.EXCEPTION_SQL_ERROR_CODE);
                                final String SQLState = key.getProperty(PoolDataSourceStatistics.EXCEPTION_SQL_STATE);

                                if (SQLErrorCode == null || SQLState == null) {
                                    logger.warn("{}{} occurrences for (class={})",
                                                prefix,
                                                e.getValue(),
                                                className);
                                } else {
                                    logger.warn("{}{} occurrences for (class={}, error code={}, SQL state={})",
                                                prefix,
                                                e.getValue(),
                                                className,
                                                SQLErrorCode,
                                                SQLState);
                                }
                            });
                }
            }
        } catch (IllegalAccessException | InvocationTargetException e) {
            logger.error(exceptionToString(e));
        }
    }

    private static String exceptionToString(final Exception ex) {
        return String.format("{}: {}", ex.getClass().getName(), ex.getMessage());
    }
    
    // getter(s)

    public long getConnectionCount() {
        return getPhysicalConnectionCount() + getLogicalConnectionCount();
    }
            
    // all physical time elapsed stuff

    public long getPhysicalConnectionCount() {
        return physicalConnectionCount.get();
    }
            
    public long getPhysicalTimeElapsedMin() {
        return physicalTimeElapsedMin.get();
    }

    public long getPhysicalTimeElapsedMax() {
        return physicalTimeElapsedMax.get();
    }

    public long getPhysicalTimeElapsedAvg() {
        return physicalTimeElapsedAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
    }

    // all logical time elapsed stuff
    
    public long getLogicalConnectionCount() {
        return logicalConnectionCount.get();
    }

    public long getLogicalTimeElapsedMin() {
        return logicalTimeElapsedMin.get();
    }

    public long getLogicalTimeElapsedMax() {
        return logicalTimeElapsedMax.get();
    }

    public long getLogicalTimeElapsedAvg() {
        return logicalTimeElapsedAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
    }

    // all proxy time elapsed stuff

    public long getProxyLogicalConnectionCount() {
        return proxyLogicalConnectionCount.get();
    }

    public long getProxyOpenSessionCount() {
        return proxyOpenSessionCount.get();
    }
        
    public long getProxyCloseSessionCount() {
        return proxyCloseSessionCount.get();
    }
        
    public long getProxyTimeElapsedMin() {
        return proxyTimeElapsedMin.get();
    }

    public long getProxyTimeElapsedMax() {
        return proxyTimeElapsedMax.get();
    }

    public long getProxyTimeElapsedAvg() {
        return proxyTimeElapsedAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
    }
    
    // all connection related stuff

    public long getActiveConnectionsMin() {
        return activeConnectionsMin.get();
    }

    public long getActiveConnectionsMax() {
        return activeConnectionsMax.get();
    }

    public long getActiveConnectionsAvg() {
        return activeConnectionsAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
    }

    public long getIdleConnectionsMin() {
        return idleConnectionsMin.get();
    }

    public long getIdleConnectionsMax() {
        return idleConnectionsMax.get();
    }
        
    public long getIdleConnectionsAvg() {
        return idleConnectionsAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
    }
        
    public long getTotalConnectionsMin() {
        return totalConnectionsMin.get();
    }

    public long getTotalConnectionsMax() {
        return totalConnectionsMax.get();
    }

    public long getTotalConnectionsAvg() {
        return totalConnectionsAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
    }

    public Map<Properties, Long> getErrors() {
        final Map<Properties, Long> result = new HashMap();
            
        errors.forEach((k, v) -> result.put(k, Long.valueOf(v.get())));
            
        return result;
    }

    /**
     * @author Alexander_Sergeev
     *
     * See https://github.com/qbit-for-money/commons/blob/master/src/main/java/com/qbit/commons/model/AtomicBigDecimal.java
     */
    private final class AtomicBigDecimal {

        private final AtomicReference<BigDecimal> valueHolder = new AtomicReference<>();

        public AtomicBigDecimal(BigDecimal value) {
            valueHolder.set(value);
        }

        public BigDecimal get() {
            return valueHolder.get();
        }

        public BigDecimal addAndGet(final BigDecimal value) {
            while (true) {
                BigDecimal current = valueHolder.get();
                BigDecimal next = current.add(value);
                
                if (valueHolder.compareAndSet(current, next)) {
                    return next;
                }
            }
        }

        public BigDecimal setAndGet(final BigDecimal value) {
            while (true) {
                BigDecimal current = valueHolder.get();

                if (valueHolder.compareAndSet(current, value)) {
                    return value;
                }
            }
        }
    }
}
