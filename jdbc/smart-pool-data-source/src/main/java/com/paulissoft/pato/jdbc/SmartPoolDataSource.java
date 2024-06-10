package com.paulissoft.pato.jdbc;

import java.util.function.Supplier;
import lombok.NonNull;

public interface SmartPoolDataSource {

    /*
     * Statistics
     */
    
    public static PoolDataSourceStatistics[] updatePoolDataSourceStatistics(@NonNull final SimplePoolDataSource poolDataSource,
                                                                            final SimplePoolDataSource poolDataSourceOverflow,
                                                                            final PoolDataSourceStatistics poolDataSourceStatisticsTotal,
                                                                            final Supplier<Boolean> isClosedSupplier) {
        final PoolDataSourceConfiguration pdsConfig = poolDataSource.get();

        pdsConfig.determineConnectInfo(); // determine schema

        // level 3        
        final PoolDataSourceStatistics parentPoolDataSourceStatistics =
            new PoolDataSourceStatistics(() -> poolDataSource.getPoolDescription() + ": (all)",
                                         poolDataSourceStatisticsTotal,
                                         isClosedSupplier,
                                         poolDataSource::get);
        
        // level 4
        final PoolDataSourceStatistics poolDataSourceStatistics =
            new PoolDataSourceStatistics(() -> poolDataSource.getPoolDescription() + ": (only " + pdsConfig.getSchema() + ")",
                                         parentPoolDataSourceStatistics, // level 3
                                         isClosedSupplier,
                                         poolDataSource::get);

        PoolDataSourceStatistics poolDataSourceStatisticsOverflow = null;

        if (poolDataSourceOverflow != null) {
            final PoolDataSourceConfiguration pdsConfigOverflow = poolDataSourceOverflow.get();

            pdsConfigOverflow.determineConnectInfo(); // determine schema

            // level 4
            poolDataSourceStatisticsOverflow =
                new PoolDataSourceStatistics(() -> poolDataSourceOverflow.getPoolDescription() + ": (only " + pdsConfigOverflow.getSchema() + ")",
                                             parentPoolDataSourceStatistics, // level 3
                                             isClosedSupplier,
                                             poolDataSourceOverflow::get);
        }

        return new PoolDataSourceStatistics[] {parentPoolDataSourceStatistics, poolDataSourceStatistics, poolDataSourceStatisticsOverflow};
    }
}
