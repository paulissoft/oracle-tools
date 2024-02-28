package com.paulissoft.pato.jdbc;


class PoolDataSourceConfigurationId {

    protected String id;

    // necessary for PoolDataSourceConfigurationCommonId constructor
    PoolDataSourceConfigurationId() {
    }
    
    PoolDataSourceConfigurationId(final PoolDataSourceConfiguration poolDataSourceConfiguration) {
        final PoolDataSourceConfiguration copy = poolDataSourceConfiguration.toBuilder().build(); // a copy

        copy.keepIdConfiguration();
        
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
