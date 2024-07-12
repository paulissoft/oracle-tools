package com.paulissoft.pato.jdbc;

import java.sql.SQLException;

import javax.sql.DataSource;

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

    private long connectionWaitDurationInMillis;

    private long maxConnectionReuseTime;

    private int secondsToTrustIdleConnection;

    private int connectionValidationTimeout;

    public PoolDataSourceConfigurationOracle() {
        // super();
        final Class<DataSource> cls = getType();

        assert (cls == null || SimplePoolDataSourceOracle.class.isAssignableFrom(cls))
            : "Type must be assignable from SimplePoolDataSourceOracle";
    }

    public static PoolDataSourceConfigurationOracle build(String url,
                                                          String username,
                                                          String password,
                                                          String type) {
        return PoolDataSourceConfigurationOracle
            .builder()
            .url(url)
            .username(username)
            .password(password)
            .type(type)
            .build();
    }

    protected static PoolDataSourceConfigurationOracle build(String url,
                                                             String username,
                                                             String password,
                                                             String type,
                                                             String connectionPoolName,
                                                             int initialPoolSize,
                                                             int minPoolSize,
                                                             int maxPoolSize,
                                                             String connectionFactoryClassName,
                                                             boolean validateConnectionOnBorrow,
                                                             int abandonedConnectionTimeout,
                                                             int timeToLiveConnectionTimeout,
                                                             int inactiveConnectionTimeout,
                                                             int timeoutCheckInterval,
                                                             int maxStatements,
                                                             long connectionWaitDurationInMillis,
                                                             long maxConnectionReuseTime,
                                                             int secondsToTrustIdleConnection,
                                                             int connectionValidationTimeout) {
        return PoolDataSourceConfigurationOracle
            .builder()
            .url(url)
            .username(username)
            .password(password)
            .type(type)
            .connectionPoolName(connectionPoolName)
            .initialPoolSize(initialPoolSize)
            .minPoolSize(minPoolSize)
            .maxPoolSize(maxPoolSize)
            .connectionFactoryClassName(connectionFactoryClassName)
            .validateConnectionOnBorrow(validateConnectionOnBorrow)
            .abandonedConnectionTimeout(abandonedConnectionTimeout)
            .timeToLiveConnectionTimeout(timeToLiveConnectionTimeout)
            .inactiveConnectionTimeout(inactiveConnectionTimeout)
            .timeoutCheckInterval(timeoutCheckInterval)
            .maxStatements(maxStatements)
            .connectionWaitDurationInMillis(connectionWaitDurationInMillis)
            .maxConnectionReuseTime(maxConnectionReuseTime)
            .secondsToTrustIdleConnection(secondsToTrustIdleConnection)
            .connectionValidationTimeout(connectionValidationTimeout)
            .build();
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

    public long getConnectionTimeout() {
        return getConnectionWaitDurationInMillis();
    }
    
    // copy parent fields
    @Override
    public void copyFrom(final PoolDataSourceConfiguration poolDataSourceConfiguration) {
        super.copyFrom(poolDataSourceConfiguration);

        // not used for Oracle
        setDriverClassName(null);
    }

    public static void set(final PoolDataSourcePropertiesSettersOracle pdsDst,
                           final PoolDataSourceConfigurationOracle pdsSrc) {
        log.debug(">set(pdsSrc={})", pdsSrc);

        int nr = 0;
        final int maxNr = 17;
        
        do {
            try {
                /* this.driverClassName is ignored */
                switch(nr) {
                case  0: pdsDst.setURL(pdsSrc.getUrl()); break;
                case  1: pdsDst.setUser(pdsSrc.getUsername()); break;
                case  2: pdsDst.setPassword(pdsSrc.getPassword()); break;
                case  3: pdsDst.setConnectionPoolName(pdsSrc.getConnectionPoolName()); break;
                case  4: pdsDst.setInitialPoolSize(pdsSrc.getInitialPoolSize()); break;
                case  5: pdsDst.setMinPoolSize(pdsSrc.getMinPoolSize()); break;
                case  6: pdsDst.setMaxPoolSize(pdsSrc.getMaxPoolSize()); break;
                case  7:
                    if (pdsSrc.getConnectionFactoryClassName() != null) {
                        pdsDst.setConnectionFactoryClassName(pdsSrc.getConnectionFactoryClassName());
                    }
                    break;
                case  8: pdsDst.setValidateConnectionOnBorrow(pdsSrc.getValidateConnectionOnBorrow()); break;
                case  9: pdsDst.setAbandonedConnectionTimeout(pdsSrc.getAbandonedConnectionTimeout()); break;
                case 10: pdsDst.setTimeToLiveConnectionTimeout(pdsSrc.getTimeToLiveConnectionTimeout()); break;
                case 11: pdsDst.setInactiveConnectionTimeout(pdsSrc.getInactiveConnectionTimeout()); break;
                case 12: pdsDst.setTimeoutCheckInterval(pdsSrc.getTimeoutCheckInterval()); break;
                case 13: pdsDst.setMaxStatements(pdsSrc.getMaxStatements()); break;
                case 14: pdsDst.setConnectionWaitDurationInMillis(pdsSrc.getConnectionWaitDurationInMillis()); break;
                case 15: pdsDst.setMaxConnectionReuseTime(pdsSrc.getMaxConnectionReuseTime()); break;
                case 16: pdsDst.setSecondsToTrustIdleConnection(pdsSrc.getSecondsToTrustIdleConnection()); break;
                case 17: pdsDst.setConnectionValidationTimeout(pdsSrc.getConnectionValidationTimeout()); break;
                default:
                    throw new IllegalArgumentException(String.format("Wrong value for nr (%d): must be between 0 and %d", nr, maxNr));
                }
            } catch (Exception ex) {
                log.warn("nr: {}; exception: {}", nr, SimplePoolDataSource.exceptionToString(ex));
            }
        } while (++nr <= maxNr);

        log.debug("<set()");
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
