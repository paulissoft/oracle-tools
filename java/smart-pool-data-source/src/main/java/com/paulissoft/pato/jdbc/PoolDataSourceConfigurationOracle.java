package com.paulissoft.pato.jdbc;

import java.sql.SQLException;
import lombok.Data;
import lombok.EqualsAndHashCode;
//**/import lombok.NoArgsConstructor;
import lombok.ToString;
import lombok.experimental.SuperBuilder;
import lombok.extern.slf4j.Slf4j;
//**/import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
//**/import org.apache.commons.lang3.builder.ToStringStyle;


@Slf4j
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
//**/@NoArgsConstructor
@SuperBuilder(toBuilder = true)
public class PoolDataSourceConfigurationOracle
    extends PoolDataSourceConfiguration
    implements PoolDataSourcePropertiesSettersOracle, PoolDataSourcePropertiesGettersOracle {

    // properties that may differ, i.e. are ignored
    
    private String connectionPoolName;

    private int initialPoolSize;

    private int minPoolSize;

    private int maxPoolSize;

    // properties that may NOT differ, i.e. must be common
        
    private String connectionFactoryClassName;

    private boolean validateConnectionOnBorrow;

    // Interface oracle.ucp.jdbc.PoolDataSource has getValidateConnectionOnBorrow(), not isValidateConnectionOnBorrow().
    // Since Lombok does not support it easily,
    // just create getValidateConnectionOnBorrow() and make isValidateConnectionOnBorrow() private.
    public boolean getValidateConnectionOnBorrow() {
        return validateConnectionOnBorrow;
    }

    private boolean isValidateConnectionOnBorrow() {
        return validateConnectionOnBorrow;
    }        

    private int abandonedConnectionTimeout;

    private int timeToLiveConnectionTimeout;

    private int inactiveConnectionTimeout;

    private int timeoutCheckInterval;

    private int maxStatements;

    private int connectionWaitTimeout;

    private long maxConnectionReuseTime;

    private int secondsToTrustIdleConnection;

    private int connectionValidationTimeout;

    public PoolDataSourceConfigurationOracle() {
        // super();
        
        if (getType() == null) {
            setType(SimplePoolDataSourceOracle.class.getName());
        }
        
        final Class cls = getType();

        log.debug("PoolDataSourceConfigurationOracle type: {}", cls);

        assert(cls != null && SimplePoolDataSourceOracle.class.isAssignableFrom(cls));
    }

    public void setURL(String paramString) throws SQLException {
        setUrl(paramString);
    }
  
    public String getURL() {
        return getUrl();
    }
  
    public void setUser(String paramString) throws SQLException {
        setUsername(paramString);
    }
  
    public String getUser() {
        return getUsername();
    }
  
    @Override
    public String getPoolName() {
        return connectionPoolName;
    }

    // copy parent fields
    @Override
    public void copyFrom(final PoolDataSourceConfiguration poolDataSourceConfiguration) {
        super.copyFrom(poolDataSourceConfiguration);

        // not used for Oracle
        setDriverClassName(null);
    }

    @Override
    void keepCommonIdConfiguration() {
        super.keepCommonIdConfiguration();
        this.connectionPoolName = null;
        this.initialPoolSize = 0;
        this.minPoolSize = 0;
        this.maxPoolSize = 0;
    }

    @Override
    void keepIdConfiguration() {
        super.keepIdConfiguration();
        this.connectionPoolName = null;
    }

//**/    @Override
//**/    public String toString() {
//**/        ReflectionToStringBuilder rtsb = new ReflectionToStringBuilder(this, ToStringStyle.JSON_STYLE);
//**/        
//**/        rtsb.setExcludeNullValues(true);
//**/        
//**/        return rtsb.toString();
//**/    }
}
