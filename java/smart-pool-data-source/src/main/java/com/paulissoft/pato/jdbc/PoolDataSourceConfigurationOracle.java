package com.paulissoft.pato.jdbc;

import javax.sql.DataSource;
import java.sql.SQLException;
import lombok.Data;
import lombok.EqualsAndHashCode;
//**/import lombok.NoArgsConstructor;
import lombok.ToString;
import lombok.experimental.SuperBuilder;
import lombok.extern.slf4j.Slf4j;
//**/import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
//**/import org.apache.commons.lang3.builder.ToStringStyle;
import oracle.ucp.jdbc.PoolDataSource;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;


@Slf4j
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
//**/@NoArgsConstructor
@SuperBuilder(toBuilder = true)
@Component
@ConfigurationProperties(prefix = "spring.datasource.oracleucp")
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
        log.debug("setUser({})", paramString);
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

    void copyTo(final DataSource dataSource) {
        copyTo((PoolDataSource) dataSource);
    }

    private void copyTo(final PoolDataSource poolDataSource) {
        int nr = 0;
        final int maxNr = 17;
        
        do {
            try {
                /* this.driverClassName is ignored */
                switch(nr) {
                case 0: poolDataSource.setURL(this.getUrl()); break;
                case 1:
                    log.debug("poolDataSource.setUser({})", this.getUsername());
                    poolDataSource.setUser(this.getUsername());
                    break;
                case 2: poolDataSource.setPassword(this.getPassword()); break;
                case 3: /* connection pool name is not copied here */ break;
                case 4: poolDataSource.setInitialPoolSize(this.getInitialPoolSize()); break;
                case 5: poolDataSource.setMinPoolSize(this.getMinPoolSize()); break;
                case 6: poolDataSource.setMaxPoolSize(this.getMaxPoolSize()); break;
                case 7: poolDataSource.setConnectionFactoryClassName(this.getConnectionFactoryClassName()); break;
                case 8: poolDataSource.setValidateConnectionOnBorrow(this.getValidateConnectionOnBorrow()); break;
                case 9: poolDataSource.setAbandonedConnectionTimeout(this.getAbandonedConnectionTimeout()); break;
                case 10: poolDataSource.setTimeToLiveConnectionTimeout(this.getTimeToLiveConnectionTimeout()); break;
                case 11: poolDataSource.setInactiveConnectionTimeout(this.getInactiveConnectionTimeout()); break;
                case 12: poolDataSource.setTimeoutCheckInterval(this.getTimeoutCheckInterval()); break;
                case 13: poolDataSource.setMaxStatements(this.getMaxStatements()); break;
                case 14: poolDataSource.setConnectionWaitTimeout(this.getConnectionWaitTimeout()); break;
                case 15: poolDataSource.setMaxConnectionReuseTime(this.getMaxConnectionReuseTime()); break;
                case 16: poolDataSource.setSecondsToTrustIdleConnection(this.getSecondsToTrustIdleConnection()); break;
                case 17: poolDataSource.setConnectionValidationTimeout(this.getConnectionValidationTimeout()); break;
                default:
                    throw new IllegalArgumentException(String.format("Wrong value for nr (%d): must be between 0 and %d", nr, maxNr));
                }
            } catch (Exception ex) {
                log.warn("nr: {}; exception: {}", nr, SimplePoolDataSource.exceptionToString(ex));
            }
        } while (++nr <= maxNr);
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
