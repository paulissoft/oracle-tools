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
import java.util.Iterator;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.BiConsumer;
import java.util.function.Supplier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class PoolDataSourceStatistics {

    // all static stuff
    
    static final String INDENT_PREFIX = "* ";

    public static final String EXCEPTION_CLASS_NAME = "class";

    public static final String EXCEPTION_SQL_ERROR_CODE = "SQL error code";

    public static final String EXCEPTION_SQL_STATE = "SQL state";

    private static final int ROUND_SCALE = 32;

    private static final int DISPLAY_SCALE = 0;

    static final PoolDataSourceStatistics poolDataSourceStatisticsGrandTotal = new PoolDataSourceStatistics(() -> "pool: (all)");

    private static final Logger logger = LoggerFactory.getLogger(PoolDataSourceStatistics.class);

    private static final boolean checkStatistics = logger.isDebugEnabled();

    private static boolean failOnInvalidStatistics = false;

    static {
        logger.info("Initializing {}", PoolDataSourceStatistics.class.toString());
    }

    static void clear() {
        poolDataSourceStatisticsGrandTotal.reset();
    }
    
    // all instance stuff
    
    private final Supplier<String> descriptionSupplier;

    private final Supplier<Boolean> isClosedSupplier;

    private final int level;

    private final Supplier<PoolDataSourceConfiguration> pdsSupplier;

    private final AtomicLong firstUpdate = new AtomicLong(0L);

    private final AtomicLong lastUpdate = new AtomicLong(0L);

    private final AtomicLong lastShown = new AtomicLong(0L);
    
    // all physical time elapsed stuff
    
    private final Set<Connection> physicalConnections;

    private final AtomicLong physicalConnectionCount = new AtomicLong();

    private final AtomicLong physicalTimeElapsedMin = new AtomicLong(Long.MAX_VALUE);
    
    private final AtomicLong physicalTimeElapsedMax = new AtomicLong(Long.MIN_VALUE);
    
    private final AtomicBigDecimal physicalTimeElapsedAvg = new AtomicBigDecimal(BigDecimal.ZERO);

    // all logical time elapsed stuff
    
    private final AtomicLong logicalConnectionCount = new AtomicLong();

    private final AtomicLong logicalTimeElapsedMin = new AtomicLong(Long.MAX_VALUE);
    
    private final AtomicLong logicalTimeElapsedMax = new AtomicLong(Long.MIN_VALUE);
    
    private final AtomicBigDecimal logicalTimeElapsedAvg = new AtomicBigDecimal(BigDecimal.ZERO);

    // all proxy time elapsed stuff

    private final AtomicLong proxyLogicalConnectionCount = new AtomicLong();
        
    private final AtomicLong proxyOpenSessionCount = new AtomicLong();
        
    private final AtomicLong proxyCloseSessionCount = new AtomicLong();

    private final AtomicLong proxyTimeElapsedMin = new AtomicLong(Long.MAX_VALUE);
    
    private final AtomicLong proxyTimeElapsedMax = new AtomicLong(Long.MIN_VALUE);
    
    private final AtomicBigDecimal proxyTimeElapsedAvg = new AtomicBigDecimal(BigDecimal.ZERO);

    // all connection related stuff (level 3 and less)

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
            
            //final ConcurrentHashMap<Connection, Integer> dummy = new ConcurrentHashMap<>();
            //this.physicalConnections = dummy.newKeySet();
 
            this.physicalConnections = ConcurrentHashMap.newKeySet();
            
            this.level = 1;
        } else {
            this.physicalConnections = null;
            
            this.level = 1 + this.parent.level;
        }

        assert(this.level >= 1 && this.level <= 4);
        assert((this.level == 1) == (this.parent == null));

        switch(this.level) {
        case 4:
            this.children = null;
            this.activeConnectionsMin = null;
            this.activeConnectionsMax = null;
            this.activeConnectionsAvg = null;
            this.idleConnectionsMin = null;
            this.idleConnectionsMax = null;
            this.idleConnectionsAvg = null;
            this.totalConnectionsMin = null;
            this.totalConnectionsMax = null;
            this.totalConnectionsAvg = null;
            break;
            
        default:
            this.children = new CopyOnWriteArraySet<PoolDataSourceStatistics>();
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
        boolean result = true;
                     
        if (isClosedSupplier != null) {
            result = isClosedSupplier.get();
        } else if (children != null) {
            // traverse the children: if one is not closed return false
            for (final Iterator<PoolDataSourceStatistics> i = children.iterator(); i.hasNext(); ) {
                if (!i.next().isClosed()) {
                    result = false;
                    break;
                }
            }
        }

        return result;
    }

    private PoolDataSourceConfiguration getPoolDataSourceConfiguration() {
        return pdsSupplier != null ? pdsSupplier.get() : null;
    }        

    private long now() {
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
            update(conn,
                   timeElapsed,
                   pds.getActiveConnections(),
                   pds.getIdleConnections(),
                   pds.getTotalConnections());
            if (showStatistics) {
                showStatistics(timeElapsed, -1, false);
            }
        } catch (Exception e) {
            // errors while updating / showing statistics must be ignored
            logger.error(SimplePoolDataSource.exceptionToString(e));
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

    void update(final Connection conn,
                final long timeElapsed,
                final int activeConnections,
                final int idleConnections,
                final int totalConnections) throws SQLException {
        if (level != 4 || isClosed()) {
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
        if (level != 4 || isClosed()) {
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
        final BigDecimal count = new BigDecimal(getConnectionCount());

        // update parent
        updateIterativeMean(count, activeConnections, parent.activeConnectionsAvg);
        updateIterativeMean(count, idleConnections, parent.idleConnectionsAvg);
        updateIterativeMean(count, totalConnections, parent.totalConnectionsAvg);

        updateMinMax(activeConnections, parent.activeConnectionsMin, parent.activeConnectionsMax);
        updateMinMax(idleConnections, parent.idleConnectionsMin, parent.idleConnectionsMax);
        updateMinMax(totalConnections, parent.totalConnectionsMin, parent.totalConnectionsMax);

        lastUpdate.set(now());

        // Show statistics if necessary
        if (mustShowTotals()) {
            showStatistics(true);
        }
    }

    private boolean mustShowTotals() {
        // Show statistics if the last update moment is not equal to the last shown moment
        // When checkStatistics is true (i.e. debug enabled) the moment is minute else hour
        final LocalDateTime lastUpdate = long2LocalDateTime(this.lastUpdate.get());
        final LocalDateTime lastShown = long2LocalDateTime(this.lastShown.get());
        final int lastUpdateMoment = lastUpdate != null ? ( checkStatistics ? lastUpdate.getMinute() : lastUpdate.getHour() ) : -1;
        final int lastShownMoment = lastShown != null ? (checkStatistics ? lastShown.getMinute() : lastShown.getHour()) : -1;
        
        return lastUpdateMoment != lastShownMoment;
    }

    void close() {
        if (level != 4) {
            return;
        }

        logger.debug(">close({})", getDescription());

        consolidate();

        logger.debug("<close()");
    }    
    
    private void consolidate() {
        /*
         * Show the statistics when this item is closed AND
         * a) there are no children (level 4) OR
         * b) there is more than 1 child OR
         * c) the only child has different statistics than its parent (i.e. snapshots different)
         */
        if (!this.isClosed()) {
            return;
        }

        if (children == null ||
            children.size() != 1 ||
            !(new Snapshot(this)).equals(new Snapshot(children.iterator().next()))) {
            showStatistics(true);
        }

        if (this.parent == null) {
            return;
        }

        Snapshot
            childSnapshotBefore = null,
            parentSnapshotBefore = null,
            childSnapshotAfter = null,
            parentSnapshotAfter = null;

        if (checkStatistics) {
            childSnapshotBefore = new Snapshot(this);
            parentSnapshotBefore = new Snapshot(this.parent);
        }

        // update the parent before the child since updateMean1 is used,
        // i.e. those must be done before updateMean2
        if (this.level <= 3) {
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

        if (checkStatistics) {
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

        if (level <= 3) {
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
            final long nrOccurrences = 0;

            if (nrOccurrences > 0) {
                signalSQLException(ex);
                // show the message
                logger.error("While connecting to {} this was occurrence # {} for this SQL exception: (error code={}, SQL state={}, {})",
                             pds.getUsername(),
                             nrOccurrences,
                             ex.getErrorCode(),
                             ex.getSQLState(),
                             SimplePoolDataSource.exceptionToString(ex));
            }
        } catch (Exception e) {
            logger.error(SimplePoolDataSource.exceptionToString(e));
        }
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
        
    void signalException(final SimplePoolDataSource pds, final Exception ex) {        
        try {
            final long nrOccurrences = 0;

            if (nrOccurrences > 0) {
                signalException(ex);
                // show the message
                logger.error("While connecting to {} this was occurrence # {} for this exception: ({})",
                             pds.getUsername(),
                             nrOccurrences,
                             SimplePoolDataSource.exceptionToString(ex));
            }
        } catch (Exception e) {
            logger.error(SimplePoolDataSource.exceptionToString(e));
        }
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

    private void showStatistics(final boolean showTotals) {
        showStatistics(-1L, -1L, showTotals);
    }
    
    private void showStatistics(final long timeElapsed,
                                final long proxyTimeElapsed,
                                final boolean showTotals) {
        if (!showTotals && !logger.isDebugEnabled()) {
            return;
        }
        
        final BiConsumer<String, Object> method = showTotals ? logger::info : logger::debug;
        final boolean showPoolSizes = level <= 3;
        final boolean showErrors = showTotals && level <= 3;
        final String prefix = INDENT_PREFIX;
        final String poolDescription = getDescription();
        final PoolDataSourceConfiguration pds = showPoolSizes ? getPoolDataSourceConfiguration() : null;

        try {
            if (method != null) {
                method.accept("Statistics for {} (level {}):",
                              (Object) new Object[]{ poolDescription, level });

                final LocalDateTime firstUpdate = long2LocalDateTime(this.firstUpdate.get());
                final LocalDateTime lastUpdate = long2LocalDateTime(this.lastUpdate.get());

                if (firstUpdate != null && lastUpdate != null) {
                    method.accept("{}first updated at: {}",
                                  (Object) new Object[]{ prefix, firstUpdate.truncatedTo(ChronoUnit.SECONDS).format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) });
                    method.accept("{}last  updated at: {}",
                                  (Object) new Object[]{ prefix, lastUpdate.truncatedTo(ChronoUnit.SECONDS).format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) });
                }
            
                if (!showTotals) {
                    if (timeElapsed >= 0L) {
                        method.accept(                                      "{}time needed to open last connection (ms): {}",
                                      (Object) new Object[]{ prefix, timeElapsed });
                    }
                    if (proxyTimeElapsed >= 0L) {
                        method.accept(                                      "{}time needed to open last proxy connection (ms): {}",
                                      (Object) new Object[]{ prefix, proxyTimeElapsed });
                    }
                }
            
                long val1, val2, val3;

                val1 = getPhysicalConnectionCount();
                val2 = getLogicalConnectionCount();
            
                if ((val1 >= 0L && val2 >= 0L) &&
                    (val1 >= 0L || val2 > 0L)) {
                    method.accept("{}physical/logical connections opened: {}/{}",
                                  (Object) new Object[]{ prefix, val1, val2 });
                }

                val1 = getPhysicalTimeElapsedMin();
                val2 = getPhysicalTimeElapsedAvg();
                val3 = getPhysicalTimeElapsedMax();

                if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                    (val1 >= 0L || val2 > 0L || val3 > 0L)) {
                    method.accept("{}min/avg/max physical connection time (ms): {}/{}/{}",
                                  (Object) new Object[]{ prefix, val1, val2, val3 });
                }
            
                val1 = getLogicalTimeElapsedMin();
                val2 = getLogicalTimeElapsedAvg();
                val3 = getLogicalTimeElapsedMax();

                if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                    (val1 >= 0L || val2 > 0L || val3 > 0L)) {
                    method.accept("{}min/avg/max logical connection time (ms): {}/{}/{}",
                                  (Object) new Object[]{ prefix, val1, val2, val3 });
                }
            
                val1 = getProxyTimeElapsedMin();
                val2 = getProxyTimeElapsedAvg();
                val3 = getProxyTimeElapsedMax();

                if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                    (val1 >= 0L || val2 > 0L || val3 > 0L)) {
                    method.accept("{}min/avg/max proxy connection time (ms): {}/{}/{}",
                                  (Object) new Object[]{ prefix, val1, val2, val3 });
                }

                val1 = getProxyOpenSessionCount();
                val2 = getProxyCloseSessionCount();
                val3 = getProxyLogicalConnectionCount();
                
                if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                    (val1 >= 0L || val2 > 0L || val3 > 0L)) {
                    method.accept("{}proxy sessions opened/closed: {}/{}; logical connections rejected while searching for optimal proxy session: {}",
                                  (Object) new Object[]{ prefix, val1, val2, val3 });
                }
            
                if (showPoolSizes && pds != null) {
                    method.accept("{}initial/min/max pool size: {}/{}/{}",
                                  (Object) new Object[]{ prefix,
                                                         pds.getInitialPoolSize(),
                                                         pds.getMinPoolSize(),
                                                         pds.getMaxPoolSize() });
                }

                if (showTotals) {
                    val1 = getActiveConnectionsMin();
                    val2 = getActiveConnectionsAvg();
                    val3 = getActiveConnectionsMax();

                    if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                        (val1 >= 0L || val2 > 0L || val3 > 0L)) {
                        method.accept("{}min/avg/max active connections: {}/{}/{}",
                                      (Object) new Object[]{ prefix, val1, val2, val3 });
                    }
                    
                    val1 = getIdleConnectionsMin();
                    val2 = getIdleConnectionsAvg();
                    val3 = getIdleConnectionsMax();

                    if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                        (val1 >= 0L || val2 > 0L || val3 > 0L)) {
                        method.accept("{}min/avg/max idle connections: {}/{}/{}",
                                      (Object) new Object[]{ prefix, val1, val2, val3 });
                    }

                    val1 = getTotalConnectionsMin();
                    val2 = getTotalConnectionsAvg();
                    val3 = getTotalConnectionsMax();

                    if ((val1 >= 0L && val2 >= 0L && val3 >= 0L) &&
                        (val1 >= 0L || val2 > 0L || val3 > 0L)) {
                        method.accept("{}min/avg/max total connections: {}/{}/{}",
                                      (Object) new Object[]{ prefix, val1, val2, val3 });
                    }
                }
            }

            // show errors
            if (showErrors) {
                final Map<Properties, Long> errors = getErrors();

                if (errors.isEmpty()) {
                    logger.info("No connection exceptions signalled for {}", poolDescription);
                } else {
                    logger.warn("Connection exceptions signalled in decreasing number of occurrences for {}:", poolDescription);
                
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
        } finally {
            lastShown.set(now());
        }
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

    public long getPhysicalTimeElapsed() {
        return (new BigDecimal(physicalConnectionCount.get())).multiply(physicalTimeElapsedAvg.get()).setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
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

    public long getLogicalTimeElapsed() {
        return (new BigDecimal(logicalConnectionCount.get())).multiply(logicalTimeElapsedAvg.get()).setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
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
    
    public long getProxyTimeElapsed() {
        return (new BigDecimal(getConnectionCount())).multiply(proxyTimeElapsedAvg.get()).setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
    }
    
    // all connection related stuff

    public long getActiveConnectionsMin() {
        return activeConnectionsMin != null ? activeConnectionsMin.get() : Long.MAX_VALUE;
    }

    public long getActiveConnectionsMax() {
        return activeConnectionsMax != null ? activeConnectionsMax.get() : Long.MIN_VALUE;
    }

    public long getActiveConnectionsAvg() {
        return activeConnectionsAvg != null ? activeConnectionsAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue() : 0L;
    }

    public long getIdleConnectionsMin() {
        return idleConnectionsMin != null ? idleConnectionsMin.get() : Long.MAX_VALUE;
    }

    public long getIdleConnectionsMax() {
        return idleConnectionsMax != null ? idleConnectionsMax.get() : Long.MIN_VALUE;
    }
        
    public long getIdleConnectionsAvg() {
        return idleConnectionsAvg != null ? idleConnectionsAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue() : 0L;
    }
        
    public long getTotalConnectionsMin() {
        return totalConnectionsMin != null ? totalConnectionsMin.get() : Long.MAX_VALUE;
    }

    public long getTotalConnectionsMax() {
        return totalConnectionsMax != null ? totalConnectionsMax.get() : Long.MIN_VALUE;
    }

    public long getTotalConnectionsAvg() {
        return totalConnectionsAvg != null ? totalConnectionsAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue() : 0L;
    }

    public Map<Properties, Long> getErrors() {
        final Map<Properties, Long> result = new HashMap<>();
            
        errors.forEach((k, v) -> result.put(k, Long.valueOf(v.get())));
            
        return result;
    }

    public static void setFailOnInvalidStatistics(final boolean failOnInvalidStatistics) {
        PoolDataSourceStatistics.failOnInvalidStatistics = failOnInvalidStatistics;
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
            assert(Math.abs(totalBefore - totalAfter) <= diffThreshold);
            nr++;
            assert(childTimeElapsedAfter == 0L);
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

            if (failOnInvalidStatistics) {
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
            assert(childMinBefore == Long.MAX_VALUE ||
                   childMaxBefore == Long.MIN_VALUE ||
                   childMinBefore <= childMaxBefore);
            // child values are reset after
            ++nr;
            assert(childMinAfter == Long.MAX_VALUE);
            ++nr;
            assert(childMaxAfter == Long.MIN_VALUE);
        
            ++nr;
            assert(parentMinBefore == Long.MAX_VALUE ||
                   parentMaxBefore == Long.MIN_VALUE ||
                   parentMinBefore <= parentMaxBefore);
            // parent min after must be at most parent min before (when that was set)
            ++nr;
            assert(parentMinBefore == Long.MAX_VALUE ||
                   parentMinAfter <= parentMinBefore);
            ++nr;
            assert(parentMinAfter == Long.MAX_VALUE ||
                   parentMaxAfter == Long.MIN_VALUE ||
                   parentMinAfter <= parentMaxAfter);
            // parent max after must be at least parent max before (when that was set)
            ++nr;
            assert(parentMaxBefore == Long.MIN_VALUE ||
                   parentMaxAfter >= parentMaxBefore);
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

            if (failOnInvalidStatistics) {
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
            assert(childCountBefore + parentCountBefore ==
                   childCountAfter + parentCountAfter);
            ++nr;
            assert(childCountBefore + parentCountBefore ==
                   childCountAfter + parentCountAfter);
            ++nr;
            assert(childCountAfter == 0L);
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

            if (failOnInvalidStatistics) {
                throw ex;
            }
        }
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

    private final class Snapshot {
        private long physicalConnectionCount;
        
        private long physicalTimeElapsed;

        private long physicalTimeElapsedMin;

        private long physicalTimeElapsedMax;

        private long logicalConnectionCount;

        private long logicalTimeElapsed;

        private long logicalTimeElapsedMin;

        private long logicalTimeElapsedMax;

        private long connectionCount;

        private long proxyLogicalConnectionCount;

        private long proxyOpenSessionCount;

        private long proxyCloseSessionCount;

        private long proxyTimeElapsed;

        private long proxyTimeElapsedMin;

        private long proxyTimeElapsedMax;

        private long activeConnectionsMin;
        
        private long activeConnectionsMax;

        private long idleConnectionsMin;
        
        private long idleConnectionsMax;

        private long totalConnectionsMin;
        
        private long totalConnectionsMax;

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
}
