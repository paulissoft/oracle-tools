package com.paulissoft.pato.jdbc;


public class PoolDataSourceConfigurationCommonId extends PoolDataSourceConfigurationId {

    public PoolDataSourceConfigurationCommonId(final PoolDataSourceConfiguration poolDataSourceConfiguration) {
        final PoolDataSourceConfiguration copy = poolDataSourceConfiguration.toBuilder().build(); // a copy

        copy.keepCommonIdConfiguration();
        if (copy.isFixedUsernamePassword()) {
            if (copy.getProxyUsername() != null) {
                copy.setUsername(copy.getProxyUsername());
            }
        }
        
        this.id.delete(0, this.id.length());
        this.id.append(copy);
    }
}
