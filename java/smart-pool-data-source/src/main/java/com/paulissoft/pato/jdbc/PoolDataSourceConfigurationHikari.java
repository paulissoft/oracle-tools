package com.paulissoft.pato.jdbc;

import com.zaxxer.hikari.HikariDataSource;
import lombok.Data;
import lombok.EqualsAndHashCode;
//**/import lombok.NoArgsConstructor;
import lombok.ToString;
import lombok.experimental.SuperBuilder;
import lombok.extern.slf4j.Slf4j;
//**/import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
//**/import org.apache.commons.lang3.builder.ToStringStyle;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;


@Slf4j
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
//**/@NoArgsConstructor
@SuperBuilder(toBuilder = true)
@Component
@ConfigurationProperties(prefix = "spring.datasource.hikari")
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

    //*TBD*/
    /*
    @Override
    public String getPoolName() {
        return poolName;
    }
    */

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
        return false;
    }

    /*
     * NOTE 2.
     *
     * The combination of singleSessionProxyModel true and fixedUsernamePassword false does not work.
     * So when singleSessionProxyModel is true, fixedUsernamePassword must be true as well.
     */

    @Override
    public boolean isFixedUsernamePassword() {
        return true;
    }
    
    public PoolDataSourceConfigurationHikari() {
        // super();

        if (getType() == null) {
            setType(SimplePoolDataSourceHikari.class.getName());
        }
        
        final Class cls = getType();

        log.debug("PoolDataSourceConfigurationHikari type: {}", cls);

        assert(cls != null && SimplePoolDataSourceHikari.class.isAssignableFrom(cls));
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

    void copy(final HikariDataSource hikariDataSource) {
        int nr = 0;
        final int maxNr = 18;
        
        do {
            try {
                switch(nr) {
                case 0: hikariDataSource.setDriverClassName(this.getDriverClassName()); break;
                case 1: hikariDataSource.setJdbcUrl(this.getUrl()); break;
                case 2: hikariDataSource.setUsername(this.getUsername()); break;
                case 3: hikariDataSource.setPassword(this.getPassword()); break;
                case 4: /* connection pool name is not copied here */ break;
                case 5: hikariDataSource.setMaximumPoolSize(this.getMaximumPoolSize()); break;
                case 6: hikariDataSource.setMinimumIdle(this.getMinimumIdle()); break;
                case 7: hikariDataSource.setAutoCommit(this.isAutoCommit()); break;
                case 8: hikariDataSource.setConnectionTimeout(this.getConnectionTimeout()); break;
                case 9: hikariDataSource.setIdleTimeout(this.getIdleTimeout()); break;
                case 10: hikariDataSource.setMaxLifetime(this.getMaxLifetime()); break;
                case 11: hikariDataSource.setConnectionTestQuery(this.getConnectionTestQuery()); break;
                case 12: hikariDataSource.setInitializationFailTimeout(this.getInitializationFailTimeout()); break;
                case 13: hikariDataSource.setIsolateInternalQueries(this.isIsolateInternalQueries()); break;
                case 14: hikariDataSource.setAllowPoolSuspension(this.isAllowPoolSuspension()); break;
                case 15: hikariDataSource.setReadOnly(this.isReadOnly()); break;
                case 16: hikariDataSource.setRegisterMbeans(this.isRegisterMbeans()); break;
                case 17: hikariDataSource.setValidationTimeout(this.getValidationTimeout()); break;
                case 18: hikariDataSource.setLeakDetectionThreshold(this.getLeakDetectionThreshold()); break;
                default:
                    throw new IllegalArgumentException(String.format("Wrong value for nr (%d): must be between 0 and %d", nr, maxNr));
                }
            } catch (Exception ex) {
                log.warn("nr: {}; exception: {}", nr, SimplePoolDataSource.exceptionToString(ex));
            }
        } while (++nr <= maxNr);
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
