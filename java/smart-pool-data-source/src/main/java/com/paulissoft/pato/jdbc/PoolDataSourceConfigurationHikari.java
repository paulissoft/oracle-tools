package com.paulissoft.pato.jdbc;

import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
//import lombok.ToString;
import lombok.experimental.SuperBuilder;
import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Data
@EqualsAndHashCode(callSuper = true)
//@ToString(callSuper = true)
@NoArgsConstructor
@SuperBuilder(toBuilder = true)
@ConfigurationProperties
public class PoolDataSourceConfigurationHikari extends PoolDataSourceConfiguration {

    // properties that may differ, i.e. are ignored
    
    private String poolName;
    
    private int maximumPoolSize;
        
    private int minimumIdle;

    // properties that may NOT differ, i.e. must be common

    private String dataSourceClassName;

    private boolean autoCommit;
    
    private long connectionTimeout;
    
    private long idleTimeout;
    
    private long maxLifetime;
    
    private String connectionTestQuery;
    
    private long initializationFailTimeout;
    
    private boolean isolateInternalQueries;
    
    private boolean allowPoolSuspension;
    
    private boolean readOnly;
    
    private boolean registerMbeans;
    
    private long validationTimeout;
    
    private long leakDetectionThreshold;

    void clearCommonDataSourceConfiguration() {
        super.clearCommonDataSourceConfiguration();
        this.poolName = null;
        this.maximumPoolSize = 0;
        this.minimumIdle = 0;
    }

    @Override
    void clearPoolName() {
        this.poolName = null;
    }

    @Override
    public String toString() {
        ReflectionToStringBuilder rtsb = new ReflectionToStringBuilder(this, ToStringStyle.JSON_STYLE);
        
        rtsb.setExcludeNullValues(true);
        
        return rtsb.toString();
    }
}
