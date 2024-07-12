package com.paulissoft.pato.jdbc;

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
public class PoolDataSourceConfigurationHikari
    extends PoolDataSourceConfiguration
    implements PoolDataSourcePropertiesSettersHikari, PoolDataSourcePropertiesGettersHikari {

    public static final boolean SINGLE_SESSION_PROXY_MODEL = false;
    
    public static final boolean FIXED_USERNAME_PASSWORD = true;

    private static final int MIN_MAXIMUM_POOL_SIZE = 1;

    private static final long MIN_VALIDATION_TIMEOUT = 250L;

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

    public static PoolDataSourceConfigurationHikari build(String driverClassName,
                                                          String url,
                                                          String username,
                                                          String password,
                                                          String type) {
        final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari =
            PoolDataSourceConfigurationHikari
            .builder()
            .driverClassName(driverClassName)
            .url(url)
            .username(username)
            .password(password)
            .type(type)
            .build();

        log.debug("PoolDataSourceConfigurationHikari.build() = {}", poolDataSourceConfigurationHikari);
        
        return poolDataSourceConfigurationHikari;
    }

    protected static PoolDataSourceConfigurationHikari build(String driverClassName,
                                                             String url,
                                                             String username,
                                                             String password,
                                                             String type,
                                                             String poolName,
                                                             int maximumPoolSize,
                                                             int minimumIdle,
                                                             String dataSourceClassName,
                                                             boolean autoCommit,
                                                             long connectionTimeout,
                                                             long idleTimeout,
                                                             long maxLifetime,
                                                             String connectionTestQuery,
                                                             long initializationFailTimeout,
                                                             boolean isolateInternalQueries,
                                                             boolean allowPoolSuspension,
                                                             boolean readOnly,
                                                             boolean registerMbeans,    
                                                             long validationTimeout,
                                                             long leakDetectionThreshold) {
        final PoolDataSourceConfigurationHikari poolDataSourceConfigurationHikari =
            PoolDataSourceConfigurationHikari
            .builder()
            .driverClassName(driverClassName)
            .url(url)
            .username(username)
            .password(password)
            .type(type)
            .poolName(poolName)
            .maximumPoolSize(maximumPoolSize)
            .minimumIdle(minimumIdle)
            .autoCommit(autoCommit)
            .connectionTimeout(connectionTimeout)
            .idleTimeout(idleTimeout)
            .maxLifetime(maxLifetime)
            .connectionTestQuery(connectionTestQuery)
            .initializationFailTimeout(initializationFailTimeout)
            .isolateInternalQueries(isolateInternalQueries)
            .allowPoolSuspension(allowPoolSuspension)
            .readOnly(readOnly)
            .registerMbeans(registerMbeans)
            .validationTimeout(validationTimeout)
            .leakDetectionThreshold(leakDetectionThreshold)
            .build();

        log.debug("PoolDataSourceConfigurationHikari.build() = {}", poolDataSourceConfigurationHikari);

        return poolDataSourceConfigurationHikari;
    }

    public void setJdbcUrl(String jdbcUrl) {
        setUrl(jdbcUrl);
    }
  
    public String getJdbcUrl() {
        return getUrl();
    }

    @Override
    public int getInitialPoolSize() {
        return minimumIdle;
    }

    @Override
    public int getMinPoolSize() {
        return minimumIdle;
    }

    @Override
    public int getMaxPoolSize() {
        return maximumPoolSize;
    }
    
    /*
     * NOTE 1.
     *
     * HikariCP does not support getConnection(String username, String password) so set
     * singleSessionProxyModel to false and fixedUsernamePassword to true so the
     * common properties will include the proxy user name ("bc_proxy" from "bc_proxy[bodomain]")
     * if any else just the username. Meaning "bc_proxy[bodomain]", "bc_proxy[boauth]" and so one
     * will have ONE common pool data source.
     *
     * See also https://github.com/brettwooldridge/HikariCP/issues/231
     */

    @Override
    public boolean isSingleSessionProxyModel() {
        return SINGLE_SESSION_PROXY_MODEL;
    }

    /*
     * NOTE 2.
     *
     * The combination of singleSessionProxyModel true and fixedUsernamePassword false does not work.
     * So when singleSessionProxyModel is true, fixedUsernamePassword must be true as well.
     */

    @Override
    public boolean isFixedUsernamePassword() {
        return FIXED_USERNAME_PASSWORD;
    }
    
    public PoolDataSourceConfigurationHikari() {
        // super();
        final Class<DataSource> cls = getType();

        assert (cls == null || SimplePoolDataSourceHikari.class.isAssignableFrom(cls))
            : "Type must be assignable from SimplePoolDataSourceHikari";
    }

    public static void set(final PoolDataSourcePropertiesSettersHikari pdsDst,
                           final PoolDataSourceConfigurationHikari pdsSrc) {
        log.debug(">set(pdsSrc={})", pdsSrc);
        
        int nr = 0;
        final int maxNr = 18;
        
        do {
            try {
                switch(nr) {
                case  0: pdsDst.setDriverClassName(pdsSrc.getDriverClassName()); break;
                case  1: pdsDst.setJdbcUrl(pdsSrc.getUrl()); break;
                case  2: pdsDst.setUsername(pdsSrc.getUsername()); break;
                case  3: pdsDst.setPassword(pdsSrc.getPassword()); break;
                case  4: pdsDst.setPoolName(pdsSrc.getPoolName()); break;
                case  5:
                    if (pdsSrc.getMaximumPoolSize() >= MIN_MAXIMUM_POOL_SIZE) {
                        pdsDst.setMaximumPoolSize(pdsSrc.getMaximumPoolSize());
                    }
                    break;
                case  6: pdsDst.setMinimumIdle(pdsSrc.getMinimumIdle()); break;
                case  7: pdsDst.setAutoCommit(pdsSrc.isAutoCommit()); break;
                case  8: pdsDst.setConnectionTimeout(pdsSrc.getConnectionTimeout()); break;
                case  9: pdsDst.setIdleTimeout(pdsSrc.getIdleTimeout()); break;
                case 10: pdsDst.setMaxLifetime(pdsSrc.getMaxLifetime()); break;
                case 11: pdsDst.setConnectionTestQuery(pdsSrc.getConnectionTestQuery()); break;
                case 12: pdsDst.setInitializationFailTimeout(pdsSrc.getInitializationFailTimeout()); break;
                case 13: pdsDst.setIsolateInternalQueries(pdsSrc.isIsolateInternalQueries()); break;
                case 14: pdsDst.setAllowPoolSuspension(pdsSrc.isAllowPoolSuspension()); break;
                case 15: pdsDst.setReadOnly(pdsSrc.isReadOnly()); break;
                case 16: pdsDst.setRegisterMbeans(pdsSrc.isRegisterMbeans()); break;
                case 17:
                    if (pdsSrc.getValidationTimeout() >= MIN_VALIDATION_TIMEOUT) {
                        pdsDst.setValidationTimeout(pdsSrc.getValidationTimeout());
                    }
                    break;
                case 18: pdsDst.setLeakDetectionThreshold(pdsSrc.getLeakDetectionThreshold()); break;
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
        this.poolName = null;
        this.maximumPoolSize = 0;
        this.minimumIdle = 0;
    }

    @Override
    void keepIdConfiguration() {
        super.keepIdConfiguration();
        this.poolName = null;
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
