package com.paulissoft.pato.jdbc;


class PoolDataSourceConfigurationId {

    protected final StringBuffer id;

    // necessary for PoolDataSourceConfigurationCommonId constructor
    PoolDataSourceConfigurationId() {
        this.id = new StringBuffer();
    }
    
    PoolDataSourceConfigurationId(final PoolDataSourceConfiguration poolDataSourceConfiguration) {
        final PoolDataSourceConfiguration copy = poolDataSourceConfiguration.toBuilder().build(); // a copy

        copy.keepIdConfiguration();
        
        this.id = new StringBuffer(copy.toString());
    }

    @Override
    public boolean equals(Object obj) {
        if (obj == null || !(obj instanceof PoolDataSourceConfigurationId)) {
            return false;
        }

        final PoolDataSourceConfigurationId other = (PoolDataSourceConfigurationId) obj;
        
        return other.toString().equals(this.toString());
    }

    @Override
    public int hashCode() {
        return this.toString().hashCode();
    }

    @Override
    public String toString() {
        return id.toString();
    }
}
