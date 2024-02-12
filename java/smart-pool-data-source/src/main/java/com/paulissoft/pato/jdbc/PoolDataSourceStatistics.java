package com.paulissoft.pato.jdbc;

import java.math.BigDecimal;
import java.util.concurrent.atomic.AtomicReference;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import oracle.jdbc.OracleConnection;

public class PoolDataSourceStatistics {

    private final int ROUND_SCALE = 32;

    private final int DISPLAY_SCALE = 0;

    private AtomicLong logicalConnectionCount = new AtomicLong();

    private AtomicLong logicalConnectionCountProxy = new AtomicLong();
        
    private AtomicLong openProxySessionCount = new AtomicLong();
        
    private AtomicLong closeProxySessionCount = new AtomicLong();

    private AtomicLong timeElapsedMin = new AtomicLong(Long.MAX_VALUE);
    
    private AtomicLong timeElapsedMax = new AtomicLong(Long.MIN_VALUE);
    
    private AtomicBigDecimal timeElapsedAvg = new AtomicBigDecimal(BigDecimal.ZERO);

    private AtomicLong timeElapsedProxyMin = new AtomicLong(Long.MAX_VALUE);
    
    private AtomicLong timeElapsedProxyMax = new AtomicLong(Long.MIN_VALUE);
    
    private AtomicBigDecimal timeElapsedProxyAvg = new AtomicBigDecimal(BigDecimal.ZERO);

    private AtomicLong activeConnectionsMin = new AtomicLong(Long.MAX_VALUE);
        
    private AtomicLong activeConnectionsMax = new AtomicLong(Long.MIN_VALUE);

    private AtomicBigDecimal activeConnectionsAvg = new AtomicBigDecimal(BigDecimal.ZERO);
            
    private AtomicLong idleConnectionsMin = new AtomicLong(Long.MAX_VALUE);
        
    private AtomicLong idleConnectionsMax = new AtomicLong(Long.MIN_VALUE);

    private AtomicBigDecimal idleConnectionsAvg = new AtomicBigDecimal(BigDecimal.ZERO);
            
    private AtomicLong totalConnectionsMin = new AtomicLong(Long.MAX_VALUE);
        
    private AtomicLong totalConnectionsMax = new AtomicLong(Long.MIN_VALUE);

    private AtomicBigDecimal totalConnectionsAvg = new AtomicBigDecimal(BigDecimal.ZERO);

    private Set<OracleConnection> physicalConnections;

    // the error attributes (error code and SQL state) and its count
    private ConcurrentHashMap<Properties, AtomicLong> errors = new ConcurrentHashMap<>();

    public PoolDataSourceStatistics() {
        // see https://www.geeksforgeeks.org/how-to-create-a-thread-safe-concurrenthashset-in-java/
        final ConcurrentHashMap<Connection, Integer> dummy = new ConcurrentHashMap<>();
 
        physicalConnections = dummy.newKeySet();
    }
        
    void update(final Connection conn,
                          final long timeElapsed) throws SQLException {
        update(conn, timeElapsed, -1, -1, -1);
    }

    void update(final Connection conn,
                final long timeElapsed,
                final int activeConnections,
                final int idleConnections,
                final int totalConnections) throws SQLException {
        physicalConnections.add(conn.unwrap(OracleConnection.class));
            
        // We must use count and avg from the same connection so just synchronize.
        // If we don't synchronize we risk to get the average and count from different connections.
        synchronized (this) {                
            final BigDecimal count = new BigDecimal(this.logicalConnectionCount.incrementAndGet());

            updateIterativeMean(count, timeElapsed, timeElapsedAvg);
            updateIterativeMean(count, activeConnections, activeConnectionsAvg);
            updateIterativeMean(count, idleConnections, idleConnectionsAvg);
            updateIterativeMean(count, totalConnections, totalConnectionsAvg);
        }

        // The rest is using AtomicLong, hence concurrent.
        updateMinMax(timeElapsed, timeElapsedMin, timeElapsedMax);
        updateMinMax(activeConnections, activeConnectionsMin, activeConnectionsMax);
        updateMinMax(idleConnections, idleConnectionsMin, idleConnectionsMax);
        updateMinMax(totalConnections, totalConnectionsMin, totalConnectionsMax);
    }

    void update(final Connection conn,
                final long timeElapsed,
                final long timeElapsedProxy,
                final int logicalConnectionCountProxy,
                final int openProxySessionCount,
                final int closeProxySessionCount) throws SQLException {
        physicalConnections.add(conn.unwrap(OracleConnection.class));
            
        // We must use count and avg from the same connection so just synchronize.
        // If we don't synchronize we risk to get the average and count from different connections.
        synchronized (this) {                
            final BigDecimal count = new BigDecimal(this.logicalConnectionCount.incrementAndGet());

            updateIterativeMean(count, timeElapsed, timeElapsedAvg);
            updateIterativeMean(count, timeElapsedProxy, timeElapsedProxyAvg);
        }

        // The rest is using AtomicLong, hence concurrent.
        updateMinMax(timeElapsed, timeElapsedMin, timeElapsedMax);
        updateMinMax(timeElapsedProxy, timeElapsedProxyMin, timeElapsedProxyMax);
            
        this.logicalConnectionCountProxy.addAndGet(logicalConnectionCountProxy);
        this.openProxySessionCount.addAndGet(openProxySessionCount);
        this.closeProxySessionCount.addAndGet(closeProxySessionCount);
    }

    long signalSQLException(final SQLException ex) {
        final Properties attrs = new Properties();

        attrs.setProperty("error code", String.valueOf(ex.getErrorCode()));
        attrs.setProperty("SQL state", ex.getSQLState());
            
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
            this.getLogicalConnectionCountProxy() == compareTo.getLogicalConnectionCountProxy() &&
            this.getOpenProxySessionCount() == compareTo.getOpenProxySessionCount() &&
            this.getCloseProxySessionCount() == compareTo.getCloseProxySessionCount();
    }
        
    // getter(s)

    public long getPhysicalConnectionCount() {
        return physicalConnections.size();
    }
            
    public long getLogicalConnectionCount() {
        return logicalConnectionCount.get();
    }

    public long getLogicalConnectionCountProxy() {
        return logicalConnectionCountProxy.get();
    }

    public long getOpenProxySessionCount() {
        return openProxySessionCount.get();
    }
        
    public long getCloseProxySessionCount() {
        return closeProxySessionCount.get();
    }
        
    public long getTimeElapsedMin() {
        return timeElapsedMin.get();
    }

    public long getTimeElapsedMax() {
        return timeElapsedMax.get();
    }

    public long getTimeElapsedAvg() {
        return timeElapsedAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
    }

    public long getTimeElapsedProxyMin() {
        return timeElapsedProxyMin.get();
    }

    public long getTimeElapsedProxyMax() {
        return timeElapsedProxyMax.get();
    }

    public long getTimeElapsedProxyAvg() {
        return timeElapsedProxyAvg.get().setScale(DISPLAY_SCALE, RoundingMode.HALF_UP).longValue();
    }

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
