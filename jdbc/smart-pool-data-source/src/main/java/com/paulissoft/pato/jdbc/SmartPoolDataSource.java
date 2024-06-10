package com.paulissoft.pato.jdbc;

import lombok.NonNull;

public interface SmartPoolDataSource {

    /*
     * Statistics
     */
    
    protected static PoolDataSourceStatistics[] updatePoolDataSourceStatistics(@NonNull final SimplePoolDataSource poolDataSource,
                                                                               final SimplePoolDataSource poolDataSourceOverflow) {
        final PoolDataSourceConfiguration pdsConfig = poolDataSource.get();

        pdsConfig.determineConnectInfo(); // determine schema

        // level 3        
        final PoolDataSourceStatistics parentPoolDataSourceStatistics =
            new PoolDataSourceStatistics(() -> poolDataSource.getPoolDescription() + ": (all)",
                                         poolDataSourceStatisticsTotal,
                                         () -> !poolDataSource.isOpen(),
                                         poolDataSource::get);
        
        // level 4
        final PoolDataSourceStatistics poolDataSourceStatistics =
            new PoolDataSourceStatistics(() -> poolDataSource.getPoolDescription() + ": (only " + pdsConfig.getSchema() + ")",
                                         parentPoolDataSourceStatistics, // level 3
                                         () -> !poolDataSource.isOpen(),
                                         poolDataSource::get);

        PoolDataSourceStatistics poolDataSourceStatistics = null;

        if (poolDataSourceOverflow != null) {
            final PoolDataSourceConfiguration pdsConfigOverflow = poolDataSourceOverflow.get();

            pdsConfigOverflow.determineConnectInfo(); // determine schema

            // level 4
            poolDataSourceStatisticsOverflow =
                new PoolDataSourceStatistics(() -> poolDataSourceOverflow.getPoolDescription() + ": (only " + pdsConfigOverflow.getSchema() + ")",
                                             parentPoolDataSourceStatistics, // level 3
                                             () -> !poolDataSourceOverflow.isOpen(),
                                             poolDataSourceOverflow::get);
        }

        return PoolDataSourceStatistics[] {parentPoolDataSourceStatistics, poolDataSourceStatistics, poolDataSourceStatisticsOverflow};
    }
}
