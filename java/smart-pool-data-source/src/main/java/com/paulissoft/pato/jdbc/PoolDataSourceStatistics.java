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
import java.util.Iterator;
import java.util.Map;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;
import oracle.jdbc.OracleConnection;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.function.Supplier;
import java.time.LocalDateTime;


public class PoolDataSourceStatistics {

    // all static stuff
    
    static final String INDENT_PREFIX = "* ";

    public static final String EXCEPTION_CLASS_NAME = "class";

    public static final String EXCEPTION_SQL_ERROR_CODE = "SQL error code";

    public static final String EXCEPTION_SQL_STATE = "SQL state";

    private static final int ROUND_SCALE = 32;

    private static final int DISPLAY_SCALE = 0;

    private static Method loggerInfo;

    private static Method loggerDebug;

    static final PoolDataSourceStatistics poolDataSourceStatisticsGrandTotal = new PoolDataSourceStatistics(() -> "pool: (all)");

    private static final Logger logger = LoggerFactory.getLogger(PoolDataSourceStatistics.class);

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
    
    private Supplier<String> descriptionSupplier = null;

    private Supplier<Boolean> isClosedSupplier = null;

    private int level;

    private LocalDateTime accumulatedSince = LocalDateTime.now();
    
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

    // all connection related stuff (level 3 and less)

    private AtomicLong activeConnectionsMin = null;
        
    private AtomicLong activeConnectionsMax = null;

    private AtomicBigDecimal activeConnectionsAvg = null;
            
    private AtomicLong idleConnectionsMin = null;
        
    private AtomicLong idleConnectionsMax = null;

    private AtomicBigDecimal idleConnectionsAvg = null;
            
    private AtomicLong totalConnectionsMin = null;
        
    private AtomicLong totalConnectionsMax = null;

    private AtomicBigDecimal totalConnectionsAvg = null;

    // the error attributes (error code and SQL state) and its count
    private ConcurrentHashMap<Properties, AtomicLong> errors = new ConcurrentHashMap<>();

    private PoolDataSourceStatistics parent = null;

    private CopyOnWriteArraySet<PoolDataSourceStatistics> children = null;

    public PoolDataSourceStatistics(final Supplier<String> descriptionSupplier) {
        this(descriptionSupplier, null);
    }
        
    public PoolDataSourceStatistics(final Supplier<String> descriptionSupplier,
                                    final PoolDataSourceStatistics parent) {
        this(descriptionSupplier, parent, null);
    }
        
    public PoolDataSourceStatistics(final Supplier<String> descriptionSupplier,
                                    final PoolDataSourceStatistics parent,
                                    final Supplier<Boolean> isClosedSupplier) {
        this.descriptionSupplier = descriptionSupplier;
        this.parent = parent;
        this.isClosedSupplier = isClosedSupplier;

        // only the overall instance tracks note of physical connections
        if (parent == null) {
            // see https://www.geeksforgeeks.org/how-to-create-a-thread-safe-concurrenthashset-in-java/
            final ConcurrentHashMap<Connection, Integer> dummy = new ConcurrentHashMap<>();
 
            this.physicalConnections = dummy.newKeySet();

            this.level = 1;
        } else {
            this.level = 1 + this.parent.level;
        }

        assert(this.level >= 1 && this.level <= 4);
        assert((this.level == 1) == (this.parent == null));

        switch(this.level) {
        case 4:
            break;
            
        default:
            this.children = new CopyOnWriteArraySet();
            this.activeConnectionsMin = new AtomicLong(Long.MAX_VALUE);
            this.activeConnectionsMax = new AtomicLong(Long.MIN_VALUE);
            this.activeConnectionsAvg = new AtomicBigDecimal(BigDecimal.ZERO);
            this.idleConnectionsMin = new AtomicLong(Long.MAX_VALUE);
            this.idleConnectionsMax = new AtomicLong(Long.MIN_VALUE);
            this.idleConnectionsAvg = new AtomicBigDecimal(BigDecimal.ZERO);
            this.totalConnectionsMin = new AtomicLong(Long.MAX_VALUE);
            this.totalConnectionsMax = new AtomicLong(Long.MIN_VALUE);
            this.totalConnectionsAvg = new AtomicBigDecimal(BigDecimal.ZERO);
            break;
        }

        assert((this.level == 4) == (this.children == null));

        if (this.parent != null) {
            this.parent.children.add(this);
        }
    }

    private String getDescription() {
        return descriptionSupplier != null ? descriptionSupplier.get() : null;
    }
        
    boolean isClosed() {
        if (isClosedSupplier != null) {
            return isClosedSupplier.get();
        } else if (children != null) {
            // traverse the children: if one is not closed return false
            for (final Iterator<PoolDataSourceStatistics> i = children.iterator(); i.hasNext(); ) {
                if (!i.next().isClosed()) {
                    return false;
                }
            }
        }
        return true;
    }
        
    void update(final Connection conn,
                final long timeElapsed) throws SQLException {
        if (level != 4 || isClosed()) {
            return;
        }
        
        final boolean isPhysicalConnection = add(conn);
        final BigDecimal count = new BigDecimal(isPhysicalConnection ?
                                                this.physicalConnectionCount.incrementAndGet() :
                                                this.logicalConnectionCount.incrementAndGet());

        if (isPhysicalConnection) {
            updateIterativeMean(count, timeElapsed, physicalTimeElapsedAvg);
        } else {
            updateIterativeMean(count, timeElapsed, logicalTimeElapsedAvg);
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
        if (level != 4 || isClosed()) {
            return;
        }

        final boolean isPhysicalConnection = add(conn);
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
        if (level != 4 || isClosed()) {
            return;
        }

        final BigDecimal count = new BigDecimal(getConnectionCount());

        // update parent
        updateIterativeMean(count, activeConnections, parent.activeConnectionsAvg);
        updateIterativeMean(count, idleConnections, parent.idleConnectionsAvg);
        updateIterativeMean(count, totalConnections, parent.totalConnectionsAvg);

        updateMinMax(activeConnections, parent.activeConnectionsMin, parent.activeConnectionsMax);
        updateMinMax(idleConnections, parent.idleConnectionsMin, parent.idleConnectionsMax);
        updateMinMax(totalConnections, parent.totalConnectionsMin, parent.totalConnectionsMax);
    }

    void close() {
        if (level != 4) {
            return;
        }
    
        copyToParents(this, this.parent, false);
        copyToParents(this.parent, this.parent.parent, true);

        this.reset();
    }
    
    private static void copyToParents(final PoolDataSourceStatistics childLevelX,
                                      final PoolDataSourceStatistics parentLevelY,
                                      final boolean connectionStatistics) {
        if (parentLevelY == null) {
            return;
        }

        if (!connectionStatistics && childLevelX.level == 4) {
            updateMean(childLevelX.getPhysicalConnectionCount(), childLevelX.physicalTimeElapsedAvg.get(),
                       parentLevelY.physicalConnectionCount, parentLevelY.physicalTimeElapsedAvg);
            updateMean(childLevelX.getLogicalConnectionCount(), childLevelX.logicalTimeElapsedAvg.get(),
                       parentLevelY.logicalConnectionCount, parentLevelY.logicalTimeElapsedAvg);
            // connection count is the combination of physical and logical count, not a counter
            updateMean(childLevelX.getConnectionCount(), childLevelX.proxyTimeElapsedAvg.get(),
                       parentLevelY.getConnectionCount(), parentLevelY.proxyTimeElapsedAvg);

            // supplying this min and max will update parent min and max
            updateMinMax(childLevelX.physicalTimeElapsedMin.get(), parentLevelY.physicalTimeElapsedMin, parentLevelY.physicalTimeElapsedMax);
            updateMinMax(childLevelX.physicalTimeElapsedMax.get(), parentLevelY.physicalTimeElapsedMin, parentLevelY.physicalTimeElapsedMax);
        
            updateMinMax(childLevelX.logicalTimeElapsedMin.get(), parentLevelY.logicalTimeElapsedMin, parentLevelY.logicalTimeElapsedMax);
            updateMinMax(childLevelX.logicalTimeElapsedMax.get(), parentLevelY.logicalTimeElapsedMin, parentLevelY.logicalTimeElapsedMax);

            updateMinMax(childLevelX.proxyTimeElapsedMin.get(), parentLevelY.proxyTimeElapsedMin, parentLevelY.proxyTimeElapsedMax);
            updateMinMax(childLevelX.proxyTimeElapsedMax.get(), parentLevelY.proxyTimeElapsedMin, parentLevelY.proxyTimeElapsedMax);
            
            parentLevelY.proxyLogicalConnectionCount.addAndGet(childLevelX.proxyLogicalConnectionCount.get());
            parentLevelY.proxyOpenSessionCount.addAndGet(childLevelX.proxyOpenSessionCount.get());
            parentLevelY.proxyCloseSessionCount.addAndGet(childLevelX.proxyCloseSessionCount.get());
        } else if (connectionStatistics && childLevelX.level == 3) {
            updateMean(childLevelX.getConnectionCount(), childLevelX.activeConnectionsAvg.get(),
                       parentLevelY.getConnectionCount(), parentLevelY.activeConnectionsAvg);
            updateMean(childLevelX.getConnectionCount(), childLevelX.idleConnectionsAvg.get(),
                       parentLevelY.getConnectionCount(), parentLevelY.idleConnectionsAvg);
            updateMean(childLevelX.getConnectionCount(), childLevelX.totalConnectionsAvg.get(),
                       parentLevelY.getConnectionCount(), parentLevelY.totalConnectionsAvg);

            updateMinMax(childLevelX.activeConnectionsMin.get(), parentLevelY.activeConnectionsMin, parentLevelY.activeConnectionsMax);
            updateMinMax(childLevelX.activeConnectionsMax.get(), parentLevelY.activeConnectionsMin, parentLevelY.activeConnectionsMax);
            updateMinMax(childLevelX.idleConnectionsMin.get(), parentLevelY.idleConnectionsMin, parentLevelY.idleConnectionsMax);
            updateMinMax(childLevelX.idleConnectionsMax.get(), parentLevelY.idleConnectionsMin, parentLevelY.idleConnectionsMax);
            updateMinMax(childLevelX.totalConnectionsMin.get(), parentLevelY.totalConnectionsMin, parentLevelY.totalConnectionsMax);
            updateMinMax(childLevelX.totalConnectionsMax.get(), parentLevelY.totalConnectionsMin, parentLevelY.totalConnectionsMax);
        }

        // recursively
        copyToParents(childLevelX, parentLevelY.parent, connectionStatistics);
    }

    private void reset() {
        if (level != 4) {
            return;
        }

        accumulatedSince = LocalDateTime.now();
        physicalConnectionCount.set(0L);
        physicalTimeElapsedMin.set(Long.MAX_VALUE);    
        physicalTimeElapsedMax.set(Long.MIN_VALUE);    
        physicalTimeElapsedAvg.set(BigDecimal.ZERO);
        logicalConnectionCount.set(0L);
        logicalTimeElapsedMin.set(Long.MAX_VALUE);   
        logicalTimeElapsedMax.set(Long.MIN_VALUE);
        logicalTimeElapsedAvg.set(BigDecimal.ZERO);
        proxyLogicalConnectionCount.set(0L);        
        proxyOpenSessionCount.set(0L);        
        proxyCloseSessionCount.set(0L);
        proxyTimeElapsedMin.set(Long.MAX_VALUE);    
        proxyTimeElapsedMax.set(Long.MIN_VALUE);    
        proxyTimeElapsedAvg.set(BigDecimal.ZERO);
        errors.clear();
    }

    private boolean add(final Connection conn) throws SQLException {
        return ( parent != null ? parent.add(conn) : physicalConnections.add(conn.unwrap(OracleConnection.class)) );
    }
    
    long signalSQLException(final SQLException ex) {
        if (isClosed()) {
            return -1L;
        }
        
        final Properties attrs = new Properties();

        attrs.setProperty(EXCEPTION_CLASS_NAME, ex.getClass().getName());
        attrs.setProperty(EXCEPTION_SQL_ERROR_CODE, String.valueOf(ex.getErrorCode()));
        attrs.setProperty(EXCEPTION_SQL_STATE, ex.getSQLState());
            
        return this.errors.computeIfAbsent(attrs, msg -> new AtomicLong(0)).incrementAndGet();
    }
        
    long signalException(final Exception ex) {
        if (isClosed()) {
            return -1L;
        }
        
        final Properties attrs = new Properties();

        attrs.setProperty(EXCEPTION_CLASS_NAME, ex.getClass().getName());
            
        return this.errors.computeIfAbsent(attrs, msg -> new AtomicLong(0)).incrementAndGet();
    }
        
    // Iterative Mean, see https://www.heikohoffmann.de/htmlthesis/node134.html
                
    // See https://stackoverflow.com/questions/4591206/
    //   arithmeticexception-non-terminating-decimal-expansion-no-exact-representable
    // to prevent this error: Non-terminating decimal expansion; no exact representable decimal result.
    private static void updateIterativeMean(final BigDecimal count,
                                            final long value,
                                            final AtomicBigDecimal avg) {
        if (value >= 0L) {
            avg.addAndGet(new BigDecimal(value).subtract(avg.get()).divide(count,
                                                                           ROUND_SCALE,
                                                                           RoundingMode.HALF_UP));
        }
    }

    private static void updateMean(final long count1,
                                   final BigDecimal avg1,
                                   final AtomicLong count2,
                                   final AtomicBigDecimal avg2) {
        updateMean(count1, avg1, count2.get(), avg2);
        if (count2.get() > 0L) {
            count2.addAndGet(count1);
        }
    }

    private static void updateMean(final long count1,
                                   final BigDecimal avg1,
                                   final long count2,
                                   final AtomicBigDecimal avg2) {
        if (count1 < 0L || count2 < 0L || count1 + count2 <= 0L) {
            return;
        }
        
        final BigDecimal value1 = (new BigDecimal(count1)).multiply(avg1);
        final BigDecimal value2 = (new BigDecimal(count2)).multiply(avg2.get());
        final BigDecimal count = new BigDecimal(count1 + count2);
        
        avg2.setAndGet(value1.add(value2).divide(count,
                                                 ROUND_SCALE,
                                                 RoundingMode.HALF_UP));
    }

    private static void updateMinMax(final long value, final AtomicLong min, final AtomicLong max) {
        if (value >= 0) {
            if (value < min.get()) {
                min.set(value);
            }
            if (value > max.get()) {
                max.set(value);
            }
        }
    }

    private boolean countersEqual(final PoolDataSourceStatistics compareTo) {
        return
            this.getPhysicalConnectionCount() == compareTo.getPhysicalConnectionCount() &&
            this.getLogicalConnectionCount() == compareTo.getLogicalConnectionCount() &&
            this.getProxyLogicalConnectionCount() == compareTo.getProxyLogicalConnectionCount() &&
            this.getProxyOpenSessionCount() == compareTo.getProxyOpenSessionCount() &&
            this.getProxyCloseSessionCount() == compareTo.getProxyCloseSessionCount();
    }

    public void showStatistics(final SimplePoolDataSource pds,
                               final boolean showTotals) {
        showStatistics(pds, -1L, -1L, showTotals);
    }
    
    public void showStatistics(final SimplePoolDataSource pds,
                               final long timeElapsed,
                               final long proxyTimeElapsed,
                               final boolean showTotals) {
        if (!showTotals && !logger.isDebugEnabled()) {
            return;
        }
        
        final Method method = (showTotals ? loggerInfo : loggerDebug);
        final boolean showPoolSizes = level <= 3;
        final boolean showErrors = showTotals && level <= 3;
        final String prefix = INDENT_PREFIX;
        final String poolDescription = String.format("{} (level {}, accumulated since {})",
                                                     getDescription(),
                                                     level,
                                                     accumulatedSince);

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
            
                if (showPoolSizes && pds != null) {
                    method.invoke(logger,
                                  "{}initial/min/max pool size: {}/{}/{}",
                                  (Object) new Object[]{ prefix,
                                                         pds.getInitialPoolSize(),
                                                         pds.getMinPoolSize(),
                                                         pds.getMaxPoolSize() });
                }

                if (!showTotals && pds != null) {
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

        if (showTotals && parent != null && !countersEqual(parent)) { // recursively but only if there are different statistics
            parent.showStatistics(null, -1L, -1L, showTotals);
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
        return activeConnectionsMin != null ? activeConnectionsMin.get() : -1L;
    }

    public long getActiveConnectionsMax() {
        return activeConnectionsMax != null ? activeConnectionsMax.get() : -1L;
    }

    public long getActiveConnectionsAvg() {
        return activeConnectionsAvg != null ? activeConnectionsAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue() : -1L;
    }

    public long getIdleConnectionsMin() {
        return idleConnectionsMin != null ? idleConnectionsMin.get() : -1L;
    }

    public long getIdleConnectionsMax() {
        return idleConnectionsMax != null ? idleConnectionsMax.get() : -1L;
    }
        
    public long getIdleConnectionsAvg() {
        return idleConnectionsAvg != null ? idleConnectionsAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue() : -1L;
    }
        
    public long getTotalConnectionsMin() {
        return totalConnectionsMin != null ? totalConnectionsMin.get() : -1L;
    }

    public long getTotalConnectionsMax() {
        return totalConnectionsMax != null ? totalConnectionsMax.get() : -1L;
    }

    public long getTotalConnectionsAvg() {
        return totalConnectionsAvg != null ? totalConnectionsAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue() : -1L;
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

        public void set(final BigDecimal value) {
            setAndGet(value);
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
