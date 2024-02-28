package com.paulissoft.pato.jdbc;


class PoolDataSourceConfigurationCommonId extends PoolDataSourceConfigurationId {

    PoolDataSourceConfigurationCommonId(final PoolDataSourceConfiguration poolDataSourceConfiguration) {
        final PoolDataSourceConfiguration copy = poolDataSourceConfiguration.toBuilder().build(); // a copy

        copy.keepCommonDataSourceConfiguration();
        if (copy.isUseFixedUsernamePassword()) {
            // username like bc_proxy[bodomain] to bc_proxy
            copy.determineConnectInfo();
            if (copy.getProxyUsername() != null) {
                copy.setUsername(copy.getProxyUsername());
            }
        }
        
        this.id = copy.toString();
    }
}
