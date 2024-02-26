package com.paulissoft.pato.jdbc;


class PoolDataSourceConfigurationId {

    private String id;

    PoolDataSourceConfigurationId(final PoolDataSourceConfiguration poolDataSourceConfiguration) {
        this(poolDataSourceConfiguration, false);
    }

    PoolDataSourceConfigurationId(final PoolDataSourceConfiguration poolDataSourceConfiguration,
                                  final boolean onlyCommonDataSourceConfiguration) {
        final PoolDataSourceConfiguration copy = poolDataSourceConfiguration.toBuilder().build(); // a copy

        if (onlyCommonDataSourceConfiguration) {
            copy.clearCommonDataSourceConfiguration();
            if (copy.getUseFixedUsernamePassword()) {
                // username like bc_proxy[bodomain] to bc_proxy
                copy.determineConnectInfo();
                if (copy.getProxyUsername() != null) {
                    copy.setUsername(copy.getProxyUsername());
                }
            }
        } else {
            copy.clearNonIdConfiguration();
        }
        
        this.id = copy.toString();
    }

    @Override
    public boolean equals(Object obj) {
        if (obj == null || !(obj instanceof PoolDataSourceConfigurationId)) {
            return false;
        }

        final PoolDataSourceConfigurationId other = (PoolDataSourceConfigurationId) obj;
        
        return other.id.equals(this.id);
    }

    @Override
    public int hashCode() {
        return this.id.hashCode();
    }

    @Override
    public String toString() {
        return id;
    }
}
