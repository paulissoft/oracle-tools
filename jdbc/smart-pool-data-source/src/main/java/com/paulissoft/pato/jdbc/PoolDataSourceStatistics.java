package com.paulissoft.pato.jdbc;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.Consumer;
import java.util.function.Supplier;
import lombok.NonNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public final class PoolDataSourceStatistics implements AutoCloseable {

    // all static stuff
    
    static final String INDENT_PREFIX = "* ";

    public static final String EXCEPTION_CLASS_NAME = "class"; // should never be null

    public static final String EXCEPTION_SQL_ERROR_CODE = "SQL error code"; // should never be null

    public static final String EXCEPTION_SQL_STATE = "SQL state"; // may be null

    private static final int ROUND_SCALE = 32;

    private static final int DISPLAY_SCALE = 0;

    private static final int MIN_LEVEL = 1;

    private static final int MAX_LEVEL = 2;
    
    private static final int MAX_LEVEL_CONNECTION_STATISTICS = MAX_LEVEL; // was MAX_LEVEL - 1

    public static final PoolDataSourceStatistics poolDataSourceStatisticsGrandTotal = new PoolDataSourceStatistics(() -> "pool: (all)");

    private static final Logger logger = LoggerFactory.getLogger(PoolDataSourceStatistics.class);

    // GJP 2024-06-27 Disabled now since the application should show it (Spring Scheduler for instance)
    // GJP 2024-07-02 Enable again since Spring Schedule poses problems for Motown
    private static final boolean debugStatistics = logger.isDebugEnabled();

    private static final AtomicBoolean failOnInvalidStatistics = new AtomicBoolean(false);

    static {
        logger.info("Initializing {}", PoolDataSourceStatistics.class);
    }

    static void clear() {
        poolDataSourceStatisticsGrandTotal.reset();
    }
    
    // all instance stuff
    
    private final Supplier<String> descriptionSupplier;

    private final Supplier<Boolean> isClosedSupplier;

    private final int level;

    private final Supplier<PoolDataSourceConfiguration> pdsSupplier;

    private final AtomicLong firstUpdate = new AtomicLong(0L); // LocalDateTime in milliseconds

    private final AtomicLong lastUpdate = new AtomicLong(0L); // LocalDateTime in milliseconds

    private final AtomicLong lastShown = new AtomicLong(0L); // LocalDateTime in millseconds

    private final AtomicBoolean isUpdateable = new AtomicBoolean(true);
    
    // all physical time elapsed stuff
    
    private final Set<Connection> physicalConnections;

    private final AtomicLong physicalConnectionCount = new AtomicLong(0L);

    private final AtomicLong physicalTimeElapsedMin = new AtomicLong(Long.MAX_VALUE);
    
    private final AtomicLong physicalTimeElapsedMax = new AtomicLong(Long.MIN_VALUE);
    
    private final AtomicBigDecimal physicalTimeElapsedAvg = new AtomicBigDecimal(BigDecimal.ZERO);

    // all logical time elapsed stuff
    
    private final AtomicLong logicalConnectionCount = new AtomicLong(0L);

    private final AtomicLong logicalTimeElapsedMin = new AtomicLong(Long.MAX_VALUE);
    
    private final AtomicLong logicalTimeElapsedMax = new AtomicLong(Long.MIN_VALUE);
    
    private final AtomicBigDecimal logicalTimeElapsedAvg = new AtomicBigDecimal(BigDecimal.ZERO);

    // all proxy time elapsed stuff

    private final AtomicLong proxyLogicalConnectionCount = new AtomicLong(0L);
        
    private final AtomicLong proxyOpenSessionCount = new AtomicLong(0L);
        
    private final AtomicLong proxyCloseSessionCount = new AtomicLong(0L);

    private final AtomicLong proxyTimeElapsedMin = new AtomicLong(Long.MAX_VALUE);
    
    private final AtomicLong proxyTimeElapsedMax = new AtomicLong(Long.MIN_VALUE);
    
    private final AtomicBigDecimal proxyTimeElapsedAvg = new AtomicBigDecimal(BigDecimal.ZERO);

    // all connection related stuff (level <= MAX_LEVEL_CONNECTION_STATISTICS)

    private final AtomicLong activeConnectionsMin;
        
    private final AtomicLong activeConnectionsMax;

    private final AtomicBigDecimal activeConnectionsAvg;
            
    private final AtomicLong idleConnectionsMin;
        
    private final AtomicLong idleConnectionsMax;

    private final AtomicBigDecimal idleConnectionsAvg;
            
    private final AtomicLong totalConnectionsMin;
        
    private final AtomicLong totalConnectionsMax;

    private final AtomicBigDecimal totalConnectionsAvg;

    // the error attributes (error code and SQL state) and its count
    private final ConcurrentHashMap<Properties, AtomicLong> errors = new ConcurrentHashMap<>();

    private final PoolDataSourceStatistics parent;

    private final CopyOnWriteArraySet<PoolDataSourceStatistics> children;

    /*
     * Constructors
     */
    
    public PoolDataSourceStatistics(final Supplier<String> descriptionSupplier) {
        this(descriptionSupplier, null);
    }
        
    public PoolDataSourceStatistics(final Supplier<String> descriptionSupplier,
                                    final PoolDataSourceStatistics parent) {
        this(descriptionSupplier, parent, null, null);
    }
        
    public PoolDataSourceStatistics(final Supplier<String> descriptionSupplier,
                                    final PoolDataSourceStatistics parent,
                                    final Supplier<Boolean> isClosedSupplier,
                                    final Supplier<PoolDataSourceConfiguration> pdsSupplier) {
        this.descriptionSupplier = descriptionSupplier;
        this.parent = parent;
        this.isClosedSupplier = isClosedSupplier;
        this.pdsSupplier = pdsSupplier;

        // only the overall instance tracks note of physical connections
        if (parent == null) {
            // see https://www.geeksforgeeks.org/how-to-create-a-thread-safe-concurrenthashset-in-java/

            this.physicalConnections = ConcurrentHashMap.newKeySet();
            
            this.level = MIN_LEVEL;
        } else {
            this.physicalConnections = null;
            
            this.level = 1 + this.parent.level;
        }

        assert this.level >= MIN_LEVEL && this.level <= MAX_LEVEL : String.format("Level must be between %d and %d.", MIN_LEVEL, MAX_LEVEL);
        assert (this.level == MIN_LEVEL) == (this.parent == null) : String.format("Level is %d if and only if parent is null.", MIN_LEVEL);

        switch(this.level) {
        case MAX_LEVEL:
            this.children = null;
            break;
            
        default:
            this.children = new CopyOnWriteArraySet<>();
            break;
        }

        if (this.level > MAX_LEVEL_CONNECTION_STATISTICS) {
            this.activeConnectionsMin = null;
            this.activeConnectionsMax = null;
            this.activeConnectionsAvg = null;
            this.idleConnectionsMin = null;
            this.idleConnectionsMax = null;
            this.idleConnectionsAvg = null;
            this.totalConnectionsMin = null;
            this.totalConnectionsMax = null;
            this.totalConnectionsAvg = null;
        } else {
            this.activeConnectionsMin = new AtomicLong(Long.MAX_VALUE);
            this.activeConnectionsMax = new AtomicLong(Long.MIN_VALUE);
            this.activeConnectionsAvg = new AtomicBigDecimal(BigDecimal.ZERO);
            this.idleConnectionsMin = new AtomicLong(Long.MAX_VALUE);
            this.idleConnectionsMax = new AtomicLong(Long.MIN_VALUE);
            this.idleConnectionsAvg = new AtomicBigDecimal(BigDecimal.ZERO);
            this.totalConnectionsMin = new AtomicLong(Long.MAX_VALUE);
            this.totalConnectionsMax = new AtomicLong(Long.MIN_VALUE);
            this.totalConnectionsAvg = new AtomicBigDecimal(BigDecimal.ZERO);
        }

        assert (this.level == MAX_LEVEL) == (this.children == null) : String.format("Level is %d if and only if there are no children.", MAX_LEVEL);

        if (this.parent != null) {
            this.parent.children.add(this);
        }
    }

    private String getDescription() {
        if (descriptionSupplier != null) {
            return descriptionSupplier.get();
        } else {
            final PoolDataSourceConfiguration pds = getPoolDataSourceConfiguration();

            return pds != null ? pds.getPoolName() : null;
        }
    }
        
    boolean isClosed() {
        boolean result = true;

        if (!isUpdateable.get()) {
            result = true;
        } else if (isClosedSupplier != null) {
            result = isClosedSupplier.get();
        } else if (children != null) {
            // traverse the children: if one is not closed return false
            for (PoolDataSourceStatistics child : children) {
                if (!child.isClosed()) {
                    result = false;
                    break;
                }
            }
        }

        logger.debug("isClosed(): {}", result);
        
        return result;
    }

    private PoolDataSourceConfiguration getPoolDataSourceConfiguration() {
        return pdsSupplier != null ? pdsSupplier.get() : null;
    }        

    private static long now() {
        final LocalDateTime localDateTime = LocalDateTime.now();
        final ZonedDateTime zdt = ZonedDateTime.of(localDateTime, ZoneId.systemDefault());

        return zdt.toInstant().toEpochMilli();
    }

    private LocalDateTime long2LocalDateTime(final long epoch) {
        return epoch != 0L ? Instant.ofEpochMilli(epoch).atZone(ZoneId.systemDefault()).toLocalDateTime() : null;
    }
    
    public void updateStatistics(final SimplePoolDataSource pds,
                                 final Connection conn,
                                 final long timeElapsed,
                                 final boolean showStatistics) {
        try {
            if (pds != null && conn != null) {
                update(conn,
                       timeElapsed,
                       pds.getActiveConnections(),
                       pds.getIdleConnections(),
                       pds.getTotalConnections());
                if (showStatistics) {
                    showStatistics(timeElapsed, -1L, false);
                }
            }
        } catch (Exception ex) {
            // errors while updating / showing statistics must be ignored
            logger.error("Exception in updateStatistics():", ex);
        }
    }

    public void updateStatistics(final SimplePoolDataSource pds,
                                 final Connection conn,
                                 final long timeElapsed,
                                 final long proxyTimeElapsed,
                                 final boolean showStatistics,
                                 final int proxyLogicalConnectionCount,
                                 final int proxyOpenSessionCount,
                                 final int proxyCloseSessionCount) {
        try {
            update(conn,
                   timeElapsed,
                   proxyTimeElapsed,
                   proxyLogicalConnectionCount,
                   proxyOpenSessionCount,
                   proxyCloseSessionCount,
                   pds.getActiveConnections(),
                   pds.getIdleConnections(),
                   pds.getTotalConnections());
            if (showStatistics) {
                showStatistics(timeElapsed, proxyTimeElapsed, false);
            }
        } catch (Exception e) {
            // errors while updating / showing statistics must be ignored
            logger.error(SimplePoolDataSource.exceptionToString(e));
        }
    }

    private void update(final Connection conn,
                        final long timeElapsed,
                        final int activeConnections,
                        final int idleConnections,
                        final int totalConnections) throws SQLException {
        if (level != MAX_LEVEL || isClosed()) {
            return;
        }

        if (firstUpdate.get() == 0L) {
            firstUpdate.set(now());
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

        update(activeConnections, idleConnections, totalConnections);
    }

    void update(final Connection conn,
                final long timeElapsed,
                final long proxyTimeElapsed,
                final int proxyLogicalConnectionCount,
                final int proxyOpenSessionCount,
                final int proxyCloseSessionCount,
                final int activeConnections,
                final int idleConnections,
                final int totalConnections) throws SQLException {
        if (level != MAX_LEVEL || isClosed()) {
            return;
        }

        if (firstUpdate.get() == 0L) {
            firstUpdate.set(now());
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

        update(activeConnections, idleConnections, totalConnections);
    }

    private void update(final int activeConnections,
                        final int idleConnections,
                        final int totalConnections) /*throws SQLException*/ {
        // assert !(level != MAX_LEVEL || isClosed())
        final BigDecimal count = new BigDecimal(getConnectionCount());
        
        // update parent when connection statistics are not gathered for this level
        if (MAX_LEVEL_CONNECTION_STATISTICS == MAX_LEVEL) {
            update(activeConnections, idleConnections, totalConnections, this, count);
        } else {
            update(activeConnections, idleConnections, totalConnections, parent, count);
        }
    }

    private static void update(final int activeConnections,
                               final int idleConnections,
                               final int totalConnections,
                               final PoolDataSourceStatistics pdss,
                               final BigDecimal count) /*throws SQLException*/ {
        updateIterativeMean(count, activeConnections, pdss.activeConnectionsAvg);
        updateIterativeMean(count, idleConnections, pdss.idleConnectionsAvg);
        updateIterativeMean(count, totalConnections, pdss.totalConnectionsAvg);

        updateMinMax(activeConnections, pdss.activeConnectionsMin, pdss.activeConnectionsMax);
        updateMinMax(idleConnections, pdss.idleConnectionsMin, pdss.idleConnectionsMax);
        updateMinMax(totalConnections, pdss.totalConnectionsMin, pdss.totalConnectionsMax);

        pdss.lastUpdate.set(now());

        // Show statistics if necessary
        // GJP 2024-06-27 Disabled now since the application should show it (Spring Scheduler for instance)
        // GJP 2024-07-02 Enable again since Spring Schedule poses problems for Motown
        if (pdss.mustShowTotals()) {
            pdss.showStatistics(true);
        }
    }

    // GJP 2024-06-27 Disabled now since the application should show it (Spring Scheduler for instance)
    // GJP 2024-07-02 Enable again since Spring Schedule poses problems for Motown
    private boolean mustShowTotals() {
        // Show statistics if the last update moment is not equal to the last shown moment
        // When debugStatistics is true (i.e. debug enabled) the moment is minute else hour
        final LocalDateTime lastUpdate = long2LocalDateTime(this.lastUpdate.get());
        final LocalDateTime lastShown = long2LocalDateTime(this.lastShown.get());
        final int lastUpdateMoment = lastUpdate != null ? (debugStatistics ? lastUpdate.getMinute() : lastUpdate.getHour()) : -1;
        final int lastShownMoment = lastShown != null ? (debugStatistics ? lastShown.getMinute() : lastShown.getHour()) : -1;
        
        return lastUpdateMoment != lastShownMoment;
    }

    public void close() /*throws Exception*/ {
        if (isClosed()) {
            return;
        }
        
        logger.info("{} - Close initiated...", getDescription());

        try {
            if (isUpdateable.get()) {
                if (level == MAX_LEVEL) {
                    consolidate();
                }
                isUpdateable.set(false);
            }
        } finally {
            assert isClosed() : "Statistics should be closed now.";
            logger.info("{} - Close completed.", getDescription());
        } 
    }    
    
    private void consolidate() {
        /*
         * Show the statistics when this item is not closed AND
         * a) there are no children (level MAX_LEVEL) OR
         * b) there is more than one child OR
         * c) the only child has different statistics than its parent (i.e. snapshots different)
         */
        if (this.isClosed()) {
            return;
        }

        if (children == null ||
            children.size() != 1 ||
            !(new Snapshot(this)).equals(new Snapshot(children.iterator().next()))) {
            showStatistics(true);
        } else {
            logger.info("Not showing statistics since the only child (level = {}) has the same characteristics as its parent.", level);
        }

        if (this.parent == null) {
            return;
        }

        Snapshot
            childSnapshotBefore = null,
            parentSnapshotBefore = null,
            childSnapshotAfter = null,
            parentSnapshotAfter = null;

        if (debugStatistics) {
            childSnapshotBefore = new Snapshot(this);
            parentSnapshotBefore = new Snapshot(this.parent);
        }

        // update the parent before the child since updateMean1 is used,
        // i.e. those must be done before updateMean2
        if (this.level <= MAX_LEVEL_CONNECTION_STATISTICS) {
            updateMean1(this.getConnectionCount(), this.activeConnectionsAvg.get(),
                        this.parent.getConnectionCount(), this.parent.activeConnectionsAvg);
            updateMean1(this.getConnectionCount(), this.idleConnectionsAvg.get(),
                        this.parent.getConnectionCount(), this.parent.idleConnectionsAvg);
            updateMean1(this.getConnectionCount(), this.totalConnectionsAvg.get(),
                        this.parent.getConnectionCount(), this.parent.totalConnectionsAvg);

            updateMinMax(this.activeConnectionsMin.get(),
                         this.parent.activeConnectionsMin, this.parent.activeConnectionsMax);
            updateMinMax(this.activeConnectionsMax.get(),
                         this.parent.activeConnectionsMin, this.parent.activeConnectionsMax);
            updateMinMax(this.idleConnectionsMin.get(),
                         this.parent.idleConnectionsMin, this.parent.idleConnectionsMax);
            updateMinMax(this.idleConnectionsMax.get(),
                         this.parent.idleConnectionsMin, this.parent.idleConnectionsMax);
            updateMinMax(this.totalConnectionsMin.get(),
                         this.parent.totalConnectionsMin, this.parent.totalConnectionsMax);
            updateMinMax(this.totalConnectionsMax.get(),
                         this.parent.totalConnectionsMin, this.parent.totalConnectionsMax);
        }

        // connection count is the combination of physical and logical count, not a counter so do it before the others
        updateMean1(this.getConnectionCount(), this.proxyTimeElapsedAvg.get(),
                    this.parent.getConnectionCount(), this.parent.proxyTimeElapsedAvg);

        // now update parent counters
        updateMean2(this.getPhysicalConnectionCount(), this.physicalTimeElapsedAvg.get(),
                    this.parent.physicalConnectionCount, this.parent.physicalTimeElapsedAvg);
        updateMean2(this.getLogicalConnectionCount(), this.logicalTimeElapsedAvg.get(),
                    this.parent.logicalConnectionCount, this.parent.logicalTimeElapsedAvg);

        // supplying this min and max will update parent min and max
        updateMinMax(this.physicalTimeElapsedMin.get(),
                     this.parent.physicalTimeElapsedMin, this.parent.physicalTimeElapsedMax);
        updateMinMax(this.physicalTimeElapsedMax.get(),
                     this.parent.physicalTimeElapsedMin, this.parent.physicalTimeElapsedMax);
        
        updateMinMax(this.logicalTimeElapsedMin.get(),
                     this.parent.logicalTimeElapsedMin, this.parent.logicalTimeElapsedMax);
        updateMinMax(this.logicalTimeElapsedMax.get(),
                     this.parent.logicalTimeElapsedMin, this.parent.logicalTimeElapsedMax);

        updateMinMax(this.proxyTimeElapsedMin.get(),
                     this.parent.proxyTimeElapsedMin, this.parent.proxyTimeElapsedMax);
        updateMinMax(this.proxyTimeElapsedMax.get(),
                     this.parent.proxyTimeElapsedMin, this.parent.proxyTimeElapsedMax);
            
        this.parent.proxyLogicalConnectionCount.addAndGet(this.proxyLogicalConnectionCount.get());
        this.parent.proxyOpenSessionCount.addAndGet(this.proxyOpenSessionCount.get());
        this.parent.proxyCloseSessionCount.addAndGet(this.proxyCloseSessionCount.get());

        this.reset();

        if (debugStatistics) {
            childSnapshotAfter = new Snapshot(this);
            parentSnapshotAfter = new Snapshot(this.parent);

            checkBeforeAndAfter(childSnapshotBefore,
                                parentSnapshotBefore,
                                childSnapshotAfter,
                                parentSnapshotAfter);
        }

        // recursively
        this.parent.consolidate();
    }

    void reset() {
        firstUpdate.set(0L);
        lastUpdate.set(0L);
        lastShown.set(0L);
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

        if (level <= MAX_LEVEL_CONNECTION_STATISTICS) {
            activeConnectionsMin.set(Long.MAX_VALUE);
            activeConnectionsMax.set(Long.MIN_VALUE);
            activeConnectionsAvg.set(BigDecimal.ZERO);
            idleConnectionsMin.set(Long.MAX_VALUE);
            idleConnectionsMax.set(Long.MIN_VALUE);
            idleConnectionsAvg.set(BigDecimal.ZERO);
            totalConnectionsMin.set(Long.MAX_VALUE);
            totalConnectionsMax.set(Long.MIN_VALUE);
            totalConnectionsAvg.set(BigDecimal.ZERO);
        }

        errors.clear();
    }

    private boolean add(final Connection conn) throws SQLException {
        return ( parent != null ? parent.add(conn) : physicalConnections.add(conn.unwrap(Connection.class)) );
    }
    
    void signalSQLException(final SimplePoolDataSource pds, final SQLException ex) {        
        try {
            if (pds != null && ex != null) {
                final long nrOccurrences = signalSQLException(ex);

                if (nrOccurrences > 0L) {
                    // show the message
                    logger.error("getConnection() raised occurrence # {} for this SQL exception: class={}, error code={}, SQL state={}. " +
                                 "Pool: {}, error message: {}",
                                 nrOccurrences,
                                 ex.getClass().getSimpleName(),
                                 ex.getErrorCode(),
                                 ex.getSQLState(), // may be null
                                 pds.getPoolName(),
                                 ex.getMessage());
                }
            }
        } catch (Exception e) {
            logger.error("Exception in signalSQLException():", e);
        }
    }

    private long signalSQLException(final SQLException ex) {
        if (ex == null || isClosed()) {
            return -1L;
        }
        
        final Properties attrs = new Properties();
        final String className = ex.getClass().getName();
        final String SQLErrorCode = String.valueOf(ex.getErrorCode());
        final String SQLState = ex.getSQLState();

        attrs.setProperty(EXCEPTION_CLASS_NAME, className);
        if (SQLErrorCode != null) { // should not be necessary
            attrs.setProperty(EXCEPTION_SQL_ERROR_CODE, SQLErrorCode);
        }
        if (SQLState != null) {
            attrs.setProperty(EXCEPTION_SQL_STATE, SQLState);
        }
            
        return this.errors.computeIfAbsent(attrs, msg -> new AtomicLong(0)).incrementAndGet();
    }
        
    void signalException(final SimplePoolDataSource pds, final Exception ex) {        
        try {
            if (pds != null && ex != null) {
                final long nrOccurrences = signalException(ex);

                if (nrOccurrences > 0L) {
                    // show the message
                    logger.error("getConnection() raised occurrence # {} for this exception: class={}. Pool: {}, error message: {}",
                                 nrOccurrences,
                                 ex.getClass().getSimpleName(),
                                 pds.getPoolName(),
                                 ex.getMessage());
                }
            }
        } catch (Exception e) {
            logger.error("Exception in signalException():", e);
        }
    }

    private long signalException(final Exception ex) {
        if (ex == null || isClosed()) {
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

    private static void updateMean1(final long count1,
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

    private static void updateMean2(final long count1,
                                    final BigDecimal avg1,
                                    final AtomicLong count2,
                                    final AtomicBigDecimal avg2) {
        updateMean1(count1, avg1, count2.get(), avg2);
        if (count1 > 0L) {
            count2.addAndGet(count1);
        }
    }

    private static void updateMinMax(final long value, final AtomicLong min, final AtomicLong max) {
        if (value >= 0 && value != Long.MAX_VALUE) {
            if (value < min.get()) {
                min.set(value);
            }
            if (value > max.get()) {
                max.set(value);
            }
        }
    }

    public void showStatistics() {
        try {
            showStatistics(true);
        } catch (Exception ex) {
            // errors while updating / showing statistics must be ignored
            logger.error("Exception in showStatistics():", ex);
        }
    }
    
    private void showStatistics(final boolean showTotals) {
        showStatistics(-1L, -1L, showTotals);
    }
    
    private void showStatistics(final long timeElapsed,
                                final long proxyTimeElapsed,
                                final boolean showTotals) {
        if (!showTotals && !logger.isDebugEnabled()) {
            return;
        }
        
        final Consumer<String> method = showTotals ? logger::info : logger::debug;
        final boolean showPoolSizes = level <= MAX_LEVEL_CONNECTION_STATISTICS;
        final boolean showErrors = showTotals && level <= MAX_LEVEL_CONNECTION_STATISTICS;
        final String prefix = INDENT_PREFIX;
        final String poolDescription = getDescription();
        final PoolDataSourceConfiguration pds = showPoolSizes ? getPoolDataSourceConfiguration() : null;

        try {
            if (method != null) {
                method.accept(String.format("Statistics for %s (level %d):", poolDescription, level));

                final LocalDateTime firstUpdate = long2LocalDateTime(this.firstUpdate.get());
                final LocalDateTime lastUpdate = long2LocalDateTime(this.lastUpdate.get());

                if (firstUpdate != null && lastUpdate != null) {
                    method.accept(String.format("%sfirst updated at: %s",
                                                prefix, firstUpdate.truncatedTo(ChronoUnit.SECONDS).format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)));
                    method.accept(String.format("%slast  updated at: %s",
                                                prefix, lastUpdate.truncatedTo(ChronoUnit.SECONDS).format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)));
                }
            
                if (!showTotals) {
                    if (timeElapsed >= 0L) {
                        method.accept(String.format("%stime needed to open last connection (ms): %d",
                                                    prefix, timeElapsed));
                    }
                    if (proxyTimeElapsed >= 0L) {
                        method.accept(String.format("%stime needed to open last proxy connection (ms): %d",
                                                    prefix, proxyTimeElapsed));
                    }
                }
            
                long val1, val2, val3;

                val1 = getPhysicalConnectionCount();
                val2 = getLogicalConnectionCount();

                if (val1 == 0L && val2 == 0L) {
                    // don't use method here 
                    logger.info("No connections created for {}", poolDescription);
                } else {
                    if ((val1 >= 0L && val2 >= 0L) &&
                        (val1 > 0L || val2 > 0L)) {
                        method.accept(String.format("%sphysical/logical connections opened: %d/%d",
                                                    prefix, val1, val2));
                    }

                    val1 = getPhysicalTimeElapsedMin();
                    val2 = getPhysicalTimeElapsedAvg();
                    val3 = getPhysicalTimeElapsedMax();

                    if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                        (val1 > 0L || val2 > 0L || val3 > 0L)) {
                        method.accept(String.format("%smin/avg/max active connections: %d/%d/%d",
                                                    prefix, val1, val2, val3));
                    }
            
                    val1 = getLogicalTimeElapsedMin();
                    val2 = getLogicalTimeElapsedAvg();
                    val3 = getLogicalTimeElapsedMax();

                    if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                        (val1 > 0L || val2 > 0L || val3 > 0L)) {
                        method.accept(String.format("%smin/avg/max logical connection time (ms): %d/%d/%d",
                                                    prefix, val1, val2, val3));
                    }
            
                    val1 = getProxyTimeElapsedMin();
                    val2 = getProxyTimeElapsedAvg();
                    val3 = getProxyTimeElapsedMax();

                    if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                        (val1 > 0L || val2 > 0L || val3 > 0L)) {
                        method.accept(String.format("%smin/avg/max proxy connection time (ms): %d/%d/%d",
                                                    prefix, val1, val2, val3));
                    }

                    val1 = getProxyOpenSessionCount();
                    val2 = getProxyCloseSessionCount();
                    val3 = getProxyLogicalConnectionCount();
                
                    if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                        (val1 > 0L || val2 > 0L || val3 > 0L)) {
                        method.accept(String.format("%sproxy sessions opened/closed: %d/%d; " +
                                                    "logical connections rejected while searching for optimal proxy session: %d",
                                                    prefix, val1, val2, val3));
                    }
            
                    if (showPoolSizes && pds != null) {
                        method.accept(String.format("%sinitial/min/max pool size: %d/%d/%d",
                                                    prefix,
                                                    pds.getInitialPoolSize(),
                                                    pds.getMinPoolSize(),
                                                    pds.getMaxPoolSize()));
                    }

                    if (showTotals) {
                        val1 = getActiveConnectionsMin();
                        val2 = getActiveConnectionsAvg();
                        val3 = getActiveConnectionsMax();

                        if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                            (val1 > 0L || val2 > 0L || val3 > 0L)) {
                            method.accept(String.format("%smin/avg/max active connections: %d/%d/%d",
                                                        prefix, val1, val2, val3));
                        }
                    
                        val1 = getIdleConnectionsMin();
                        val2 = getIdleConnectionsAvg();
                        val3 = getIdleConnectionsMax();

                        if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                            (val1 > 0L || val2 > 0L || val3 > 0L)) {
                            method.accept(String.format("%smin/avg/max idle connections: %d/%d/%d",
                                                        prefix, val1, val2, val3));
                        }

                        val1 = getTotalConnectionsMin();
                        val2 = getTotalConnectionsAvg();
                        val3 = getTotalConnectionsMax();

                        if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                            (val1 > 0L || val2 > 0L || val3 > 0L)) {
                            method.accept(String.format("%smin/avg/max total connections: %d/%d/%d",
                                                        prefix, val1, val2, val3));
                        }
                    }
                }
            }

            // show errors
            if (showErrors) {
                final Map<Properties, Long> errors = getErrors();

                // don't use method here 

                if (errors.isEmpty()) {
                    logger.info("No connection exceptions signalled for {}", poolDescription);
                } else {
                    logger.warn("Connection exceptions signalled in decreasing number of occurrences for {}:", poolDescription);
                
                    errors.entrySet().stream()
                        .sorted(Collections.reverseOrder(Map.Entry.comparingByValue())) // sort by decreasing number of errors
                        .forEach(e -> {
                                final Properties key = e.getKey();
                                final String className = key.getProperty(PoolDataSourceStatistics.EXCEPTION_CLASS_NAME);
                                final String SQLErrorCode = key.getProperty(PoolDataSourceStatistics.EXCEPTION_SQL_ERROR_CODE);
                                final String SQLState = key.getProperty(PoolDataSourceStatistics.EXCEPTION_SQL_STATE);

                                if (SQLErrorCode == null && SQLState == null) {
                                    logger.warn("{}getConnection() raised {} occurrences for this exception: class={}",
                                                prefix,
                                                e.getValue(),
                                                className);
                                } else {
                                    logger.warn("{}getConnection() raised {} occurrences for this SQL exception: class={}, error code={}, SQL state={}",
                                                prefix,
                                                e.getValue(),
                                                className,
                                                SQLErrorCode,
                                                SQLState);
                                }
                            });
                }
            }
        } finally {
            lastShown.set(now());
        }
    }
    
    // getter(s)

    protected long getConnectionCount() {
        return getPhysicalConnectionCount() + getLogicalConnectionCount();
    }
            
    // all physical time elapsed stuff

    protected long getPhysicalConnectionCount() {
        return physicalConnectionCount.get();
    }
            
    protected long getPhysicalTimeElapsedMin() {
        return physicalTimeElapsedMin.get();
    }

    protected long getPhysicalTimeElapsedMax() {
        return physicalTimeElapsedMax.get();
    }

    protected long getPhysicalTimeElapsedAvg() {
        return physicalTimeElapsedAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
    }

    protected long getPhysicalTimeElapsed() {
        return (new BigDecimal(physicalConnectionCount.get())).multiply(physicalTimeElapsedAvg.get()).setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
    }

    // all logical time elapsed stuff
    
    protected long getLogicalConnectionCount() {
        return logicalConnectionCount.get();
    }

    protected long getLogicalTimeElapsedMin() {
        return logicalTimeElapsedMin.get();
    }

    protected long getLogicalTimeElapsedMax() {
        return logicalTimeElapsedMax.get();
    }

    protected long getLogicalTimeElapsedAvg() {
        return logicalTimeElapsedAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
    }

    protected long getLogicalTimeElapsed() {
        return (new BigDecimal(logicalConnectionCount.get())).multiply(logicalTimeElapsedAvg.get()).setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
    }

    // all proxy time elapsed stuff

    protected long getProxyLogicalConnectionCount() {
        return proxyLogicalConnectionCount.get();
    }

    protected long getProxyOpenSessionCount() {
        return proxyOpenSessionCount.get();
    }
        
    protected long getProxyCloseSessionCount() {
        return proxyCloseSessionCount.get();
    }
        
    protected long getProxyTimeElapsedMin() {
        return proxyTimeElapsedMin.get();
    }

    protected long getProxyTimeElapsedMax() {
        return proxyTimeElapsedMax.get();
    }

    protected long getProxyTimeElapsedAvg() {
        return proxyTimeElapsedAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
    }
    
    protected long getProxyTimeElapsed() {
        return (new BigDecimal(getConnectionCount())).multiply(proxyTimeElapsedAvg.get()).setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
    }
    
    // all connection related stuff

    protected long getActiveConnectionsMin() {
        return activeConnectionsMin != null ? activeConnectionsMin.get() : Long.MAX_VALUE;
    }

    protected long getActiveConnectionsMax() {
        return activeConnectionsMax != null ? activeConnectionsMax.get() : Long.MIN_VALUE;
    }

    protected long getActiveConnectionsAvg() {
        return activeConnectionsAvg != null ? activeConnectionsAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue() : 0L;
    }

    protected long getIdleConnectionsMin() {
        return idleConnectionsMin != null ? idleConnectionsMin.get() : Long.MAX_VALUE;
    }

    protected long getIdleConnectionsMax() {
        return idleConnectionsMax != null ? idleConnectionsMax.get() : Long.MIN_VALUE;
    }
        
    protected long getIdleConnectionsAvg() {
        return idleConnectionsAvg != null ? idleConnectionsAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue() : 0L;
    }
        
    protected long getTotalConnectionsMin() {
        return totalConnectionsMin != null ? totalConnectionsMin.get() : Long.MAX_VALUE;
    }

    protected long getTotalConnectionsMax() {
        return totalConnectionsMax != null ? totalConnectionsMax.get() : Long.MIN_VALUE;
    }

    protected long getTotalConnectionsAvg() {
        return totalConnectionsAvg != null ? totalConnectionsAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue() : 0L;
    }

    protected Map<Properties, Long> getErrors() {
        final Map<Properties, Long> result = new HashMap<>();
            
        errors.forEach((k, v) -> result.put(k, v.get()));
            
        return result;
    }

    public static void setFailOnInvalidStatistics(final boolean failOnInvalidStatistics) {
        PoolDataSourceStatistics.failOnInvalidStatistics.set(failOnInvalidStatistics);
    }

    static void checkBeforeAndAfter(final Snapshot childSnapshotBefore,
                                    final Snapshot parentSnapshotBefore,
                                    final Snapshot childSnapshotAfter,
                                    final Snapshot parentSnapshotAfter) {
        checkTotalBeforeAndAfter(childSnapshotBefore.physicalConnectionCount,
                                 childSnapshotBefore.physicalTimeElapsed,
                                 parentSnapshotBefore.physicalConnectionCount,
                                 parentSnapshotBefore.physicalTimeElapsed,
                                 childSnapshotAfter.physicalConnectionCount,
                                 childSnapshotAfter.physicalTimeElapsed,
                                 parentSnapshotAfter.physicalConnectionCount,
                                 parentSnapshotAfter.physicalTimeElapsed);
        checkTotalBeforeAndAfter(childSnapshotBefore.logicalConnectionCount,
                                childSnapshotBefore.logicalTimeElapsed,
                                parentSnapshotBefore.logicalConnectionCount,
                                parentSnapshotBefore.logicalTimeElapsed,
                                childSnapshotAfter.logicalConnectionCount,
                                childSnapshotAfter.logicalTimeElapsed,
                                parentSnapshotAfter.logicalConnectionCount,
                                parentSnapshotAfter.logicalTimeElapsed);
        checkTotalBeforeAndAfter(childSnapshotBefore.connectionCount,
                                childSnapshotBefore.proxyTimeElapsed,
                                parentSnapshotBefore.connectionCount,
                                parentSnapshotBefore.proxyTimeElapsed,
                                childSnapshotAfter.connectionCount,
                                childSnapshotAfter.proxyTimeElapsed,
                                parentSnapshotAfter.connectionCount,
                                parentSnapshotAfter.proxyTimeElapsed);
        checkMinMaxBeforeAndAfter(childSnapshotBefore.physicalTimeElapsedMin,
                                  childSnapshotBefore.physicalTimeElapsedMax,
                                  parentSnapshotBefore.physicalTimeElapsedMin,
                                  parentSnapshotBefore.physicalTimeElapsedMax,
                                  childSnapshotAfter.physicalTimeElapsedMin,
                                  childSnapshotAfter.physicalTimeElapsedMax,
                                  parentSnapshotAfter.physicalTimeElapsedMin,
                                  parentSnapshotAfter.physicalTimeElapsedMax);
        checkMinMaxBeforeAndAfter(childSnapshotBefore.logicalTimeElapsedMin,
                                  childSnapshotBefore.logicalTimeElapsedMax,
                                  parentSnapshotBefore.logicalTimeElapsedMin,
                                  parentSnapshotBefore.logicalTimeElapsedMax,
                                  childSnapshotAfter.logicalTimeElapsedMin,
                                  childSnapshotAfter.logicalTimeElapsedMax,
                                  parentSnapshotAfter.logicalTimeElapsedMin,
                                  parentSnapshotAfter.logicalTimeElapsedMax);
        checkMinMaxBeforeAndAfter(childSnapshotBefore.proxyTimeElapsedMin,
                                  childSnapshotBefore.proxyTimeElapsedMax,
                                  parentSnapshotBefore.proxyTimeElapsedMin,
                                  parentSnapshotBefore.proxyTimeElapsedMax,
                                  childSnapshotAfter.proxyTimeElapsedMin,
                                  childSnapshotAfter.proxyTimeElapsedMax,
                                  parentSnapshotAfter.proxyTimeElapsedMin,
                                  parentSnapshotAfter.proxyTimeElapsedMax);
        checkCountBeforeAndAfter(childSnapshotBefore.proxyLogicalConnectionCount,
                                 parentSnapshotBefore.proxyLogicalConnectionCount,
                                 childSnapshotAfter.proxyLogicalConnectionCount,
                                 parentSnapshotAfter.proxyLogicalConnectionCount);
        checkCountBeforeAndAfter(childSnapshotBefore.proxyOpenSessionCount,
                                 parentSnapshotBefore.proxyOpenSessionCount,
                                 childSnapshotAfter.proxyOpenSessionCount,
                                 parentSnapshotAfter.proxyOpenSessionCount);
        checkCountBeforeAndAfter(childSnapshotBefore.proxyCloseSessionCount,
                                 parentSnapshotBefore.proxyCloseSessionCount,
                                 childSnapshotAfter.proxyCloseSessionCount,
                                 parentSnapshotAfter.proxyCloseSessionCount);
        checkMinMaxBeforeAndAfter(childSnapshotBefore.activeConnectionsMin,
                                  childSnapshotBefore.activeConnectionsMax,
                                  parentSnapshotBefore.activeConnectionsMin,
                                  parentSnapshotBefore.activeConnectionsMax,
                                  childSnapshotAfter.activeConnectionsMin,
                                  childSnapshotAfter.activeConnectionsMax,
                                  parentSnapshotAfter.activeConnectionsMin,
                                  parentSnapshotAfter.activeConnectionsMax);
        checkMinMaxBeforeAndAfter(childSnapshotBefore.idleConnectionsMin,
                                  childSnapshotBefore.idleConnectionsMax,
                                  parentSnapshotBefore.idleConnectionsMin,
                                  parentSnapshotBefore.idleConnectionsMax,
                                  childSnapshotAfter.idleConnectionsMin,
                                  childSnapshotAfter.idleConnectionsMax,
                                  parentSnapshotAfter.idleConnectionsMin,
                                  parentSnapshotAfter.idleConnectionsMax);
        checkMinMaxBeforeAndAfter(childSnapshotBefore.totalConnectionsMin,
                                  childSnapshotBefore.totalConnectionsMax,
                                  parentSnapshotBefore.totalConnectionsMin,
                                  parentSnapshotBefore.totalConnectionsMax,
                                  childSnapshotAfter.totalConnectionsMin,
                                  childSnapshotAfter.totalConnectionsMax,
                                  parentSnapshotAfter.totalConnectionsMin,
                                  parentSnapshotAfter.totalConnectionsMax);
    }

    static void checkTotalBeforeAndAfter(final long childConnectionCountBefore,
                                         final long childTimeElapsedBefore,
                                         final long parentConnectionCountBefore,
                                         final long parentTimeElapsedBefore,
                                         final long childConnectionCountAfter,
                                         final long childTimeElapsedAfter,
                                         final long parentConnectionCountAfter,
                                         final long parentTimeElapsedAfter) {
        checkCountBeforeAndAfter(childConnectionCountBefore,
                                 parentConnectionCountBefore,
                                 childConnectionCountAfter,
                                 parentConnectionCountAfter);

        final long diffThreshold = 10L; // 10 milliseconds
        final long totalBefore = (childTimeElapsedBefore + parentTimeElapsedBefore);
        final long totalAfter = (childTimeElapsedAfter + parentTimeElapsedAfter);
        int nr = 0;

        try {
            nr++;
            assert Math.abs(totalBefore - totalAfter) <= diffThreshold
                : String.format("Absolute difference between total before (%d) and total after (%d) must be at most %d.",
                                totalBefore,
                                totalAfter,
                                diffThreshold);
            nr++;
            assert childTimeElapsedAfter == 0L
                : String.format("Child time elapsed after is %d but must be 0.", childTimeElapsedAfter);
        } catch (AssertionError ex) {
            logger.error(">checkTotalBeforeAndAfter()");
            logger.error("assertion # {} failed", nr);
            logger.error("childConnectionCountBefore={}; childTimeElapsedBefore={}",
                         childConnectionCountBefore,
                         childTimeElapsedBefore);
            logger.error("parentConnectionCountBefore={}; parentTimeElapsedBefore={}",
                         parentConnectionCountBefore,
                         parentTimeElapsedBefore);
            logger.error("childConnectionCountAfter={}; childTimeElapsedAfter={}",
                         childConnectionCountAfter,
                         childTimeElapsedAfter);
            logger.error("parentConnectionCountAfter={}; parentTimeElapsedAfter={}",
                         parentConnectionCountAfter,
                         parentTimeElapsedAfter);
            logger.error("totalBefore={}; totalAfter={}; abs(diff)={}; diffThreshold: {}",
                         totalBefore,
                         totalAfter,
                         Math.abs(totalBefore - totalAfter),
                         diffThreshold);
            logger.error("<checkTotalBeforeAndAfter()");

            if (failOnInvalidStatistics.get()) {
                throw ex;
            }
        }
    }

    static void checkMinMaxBeforeAndAfter(final long childMinBefore,
                                          final long childMaxBefore,
                                          final long parentMinBefore,
                                          final long parentMaxBefore,
                                          final long childMinAfter,
                                          final long childMaxAfter,
                                          final long parentMinAfter,
                                          final long parentMaxAfter) {
        int nr = 0;
        
        try {
            ++nr;
            assert (childMinBefore == Long.MAX_VALUE ||
                    childMaxBefore == Long.MIN_VALUE ||
                    childMinBefore <= childMaxBefore)
                : String.format("Child min before (%d) should be at most child max before (%d).", childMinBefore, childMaxBefore);
            // child values are reset after
            ++nr;
            assert childMinAfter == Long.MAX_VALUE : String.format("Child min after (%d) should be the maximum value.", childMinAfter);
            ++nr;
            assert childMaxAfter == Long.MIN_VALUE : String.format("Child max after (%d) should be the minimum value.", childMaxAfter);         
            ++nr;
            assert (parentMinBefore == Long.MAX_VALUE ||
                    parentMaxBefore == Long.MIN_VALUE ||
                    parentMinBefore <= parentMaxBefore)
                : String.format("Parent min before (%d) should be at most parent max before (%d).", parentMinBefore, parentMaxBefore);
            // parent min after must be at most parent min before (when that was set)
            ++nr;
            assert (parentMinBefore == Long.MAX_VALUE ||
                    parentMinAfter <= parentMinBefore)
                : String.format("Parent min after (%d) should be at most parent min before (%d).", parentMinAfter, parentMinBefore);
            ++nr;
            assert (parentMinAfter == Long.MAX_VALUE ||
                    parentMaxAfter == Long.MIN_VALUE ||
                    parentMinAfter <= parentMaxAfter)
                : String.format("Parent min after (%d) should be at most parent max after (%d).", parentMinAfter, parentMaxAfter);
            // parent max after must be at least parent max before (when that was set)
            ++nr;
            assert (parentMaxBefore == Long.MIN_VALUE ||
                    parentMaxAfter >= parentMaxBefore)
                : String.format("Parent max after (%d) should be at least parent max before (%d).", parentMaxAfter, parentMaxBefore);
        } catch (AssertionError ex) {
            logger.error(">checkMinMaxBeforeAndAfter()");
            logger.error("assertion # {} failed", nr);
            logger.error("childMinBefore={}; childMaxBefore={}; parentMinBefore={}; parentMaxBefore={}",
                         childMinBefore,
                         childMaxBefore,
                         parentMinBefore,
                         parentMaxBefore);
            logger.error("childMinAfter={}; childMaxAfter={}; parentMinAfter={}; parentMaxAfter={}",
                         childMinAfter,
                         childMaxAfter,
                         parentMinAfter,
                         parentMaxAfter);
            logger.error("<checkMinMaxBeforeAndAfter()");

            if (failOnInvalidStatistics.get()) {
                throw ex;
            }
        }
    }
    
    static void checkCountBeforeAndAfter(final long childCountBefore,
                                         final long parentCountBefore,
                                         final long childCountAfter,
                                         final long parentCountAfter) {
        int nr = 0;

        try {
            ++nr;
            assert (childCountBefore + parentCountBefore ==
                    childCountAfter + parentCountAfter)
                : String.format("Child count before (%d) + parent count before (%d) should be equal to the child count after (%d) + parent count after (%d).",
                                childCountBefore,
                                parentCountBefore,
                                childCountAfter,
                                parentCountAfter);
            ++nr;
            assert (childCountAfter == 0L) : String.format("Child count after (%d) should be 0.", childCountAfter);
        } catch (AssertionError ex) {
            logger.error(">checkCountBeforeAndAfter()");
            logger.error("assertion # {} failed", nr);
            logger.error("childCountBefore={}; parentCountBefore={}",
                         childCountBefore,
                         parentCountBefore);
            logger.error("childCountAfter={}; parentCountAfter={}",
                         childCountAfter,
                         parentCountAfter);
            logger.error("<checkCountBeforeAndAfter()");

            if (failOnInvalidStatistics.get()) {
                throw ex;
            }
        }
    }

    /**
     * @author Alexander_Sergeev
     *
     * See <a href="https://github.com/qbit-for-money/commons/blob/master/src/main/java/com/qbit/commons/model/AtomicBigDecimal.java">...</a>
     */
    private static final class AtomicBigDecimal {

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

    // a data class
    public static final class Snapshot {
        public final long physicalConnectionCount;
        
        public final long physicalTimeElapsed;

        public final long physicalTimeElapsedMin;

        public final long physicalTimeElapsedMax;

        public final long logicalConnectionCount;

        public final long logicalTimeElapsed;

        public final long logicalTimeElapsedMin;

        public final long logicalTimeElapsedMax;

        public final long connectionCount;

        public final long proxyLogicalConnectionCount;

        public final long proxyOpenSessionCount;

        public final long proxyCloseSessionCount;

        public final long proxyTimeElapsed;

        public final long proxyTimeElapsedMin;

        public final long proxyTimeElapsedMax;

        public final long activeConnectionsMin;
        
        public final long activeConnectionsMax;

        public final long idleConnectionsMin;
        
        public final long idleConnectionsMax;

        public final long totalConnectionsMin;
        
        public final long totalConnectionsMax;

        Snapshot(final PoolDataSourceStatistics poolDataSourceStatistics) {
            physicalConnectionCount = poolDataSourceStatistics.getPhysicalConnectionCount();
            physicalTimeElapsed = poolDataSourceStatistics.getPhysicalTimeElapsed();
            logicalConnectionCount = poolDataSourceStatistics.getLogicalConnectionCount();
            logicalTimeElapsed = poolDataSourceStatistics.getLogicalTimeElapsed();
            connectionCount = poolDataSourceStatistics.getConnectionCount();
            proxyTimeElapsed = poolDataSourceStatistics.getProxyTimeElapsed();
            physicalTimeElapsedMin = poolDataSourceStatistics.getPhysicalTimeElapsedMin();
            physicalTimeElapsedMax = poolDataSourceStatistics.getPhysicalTimeElapsedMax();
            logicalTimeElapsedMin = poolDataSourceStatistics.getLogicalTimeElapsedMin();
            logicalTimeElapsedMax = poolDataSourceStatistics.getLogicalTimeElapsedMax();
            proxyTimeElapsedMin = poolDataSourceStatistics.getProxyTimeElapsedMin();
            proxyTimeElapsedMax = poolDataSourceStatistics.getProxyTimeElapsedMax();
            proxyLogicalConnectionCount = poolDataSourceStatistics.getProxyLogicalConnectionCount();
            proxyOpenSessionCount = poolDataSourceStatistics.getProxyOpenSessionCount();
            proxyCloseSessionCount = poolDataSourceStatistics.getProxyCloseSessionCount();
            activeConnectionsMin = poolDataSourceStatistics.getActiveConnectionsMin();
            activeConnectionsMax = poolDataSourceStatistics.getActiveConnectionsMax();
            idleConnectionsMin = poolDataSourceStatistics.getIdleConnectionsMin();
            idleConnectionsMax = poolDataSourceStatistics.getIdleConnectionsMax();
            totalConnectionsMin = poolDataSourceStatistics.getTotalConnectionsMin();
            totalConnectionsMax = poolDataSourceStatistics.getTotalConnectionsMax();
        }

        // Suppress this warning:
        // Class com.paulissoft.pato.jdbc.PoolDataSourceStatistics.Snapshot overrides equals, but neither it nor any superclass overrides hashCode method
        @SuppressWarnings("EmptyMethod")
        @Override
        public int hashCode() {
            return super.hashCode();
        }
        
        @Override
        public boolean equals(Object obj) {
            if (obj == null || !(obj instanceof Snapshot)) {
                return false;
            }
            
            final Snapshot other = (Snapshot) obj;
        
            return
                this.physicalConnectionCount == other.physicalConnectionCount &&
                this.physicalTimeElapsed == other.physicalTimeElapsed &&
                this.physicalTimeElapsedMin == other.physicalTimeElapsedMin &&
                this.physicalTimeElapsedMax == other.physicalTimeElapsedMax &&
                this.logicalConnectionCount == other.logicalConnectionCount &&
                this.logicalTimeElapsed == other.logicalTimeElapsed &&
                this.logicalTimeElapsedMin == other.logicalTimeElapsedMin &&
                this.logicalTimeElapsedMax == other.logicalTimeElapsedMax &&
                this.connectionCount == other.connectionCount &&
                this.proxyLogicalConnectionCount == other.proxyLogicalConnectionCount &&
                this.proxyOpenSessionCount == other.proxyOpenSessionCount &&
                this.proxyCloseSessionCount == other.proxyCloseSessionCount &&
                this.proxyTimeElapsed == other.proxyTimeElapsed &&
                this.proxyTimeElapsedMin == other.proxyTimeElapsedMin &&
                this.proxyTimeElapsedMax == other.proxyTimeElapsedMax &&
                this.activeConnectionsMin == other.activeConnectionsMin &&
                this.activeConnectionsMax == other.activeConnectionsMax &&
                this.idleConnectionsMin == other.idleConnectionsMin &&
                this.idleConnectionsMax == other.idleConnectionsMax &&
                this.totalConnectionsMin == other.totalConnectionsMin &&
                this.totalConnectionsMax == other.totalConnectionsMax;
        }
    }    

    @NonNull
    public final Snapshot getSnapshot() {
        return new Snapshot(this);
    }

    public final Snapshot getSnapshot(final int level) {
        assert level >= MIN_LEVEL && level <= MAX_LEVEL : String.format("Level must be between %d and %d.", MIN_LEVEL, MAX_LEVEL);

        PoolDataSourceStatistics instance = this;

        while (instance != null && instance.level > level) {
            instance = instance.parent;
        }

        return instance != null && instance.level == level ? new Snapshot(instance) : null;
    }
}
