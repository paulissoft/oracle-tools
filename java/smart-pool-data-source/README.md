# Smart Pool Data Source

## Introduction

This Smart Pool Data Source has the following goals:
- let several pool data sources share a one common pool data source that does the hard work giving you the opportunity to reduce the number of connections
- every (non-shared) pool data source has information that is not common: username, password, pool sizes and so on
- the library is transparant in a Spring Boot environment: the number of (pool) data sources stays the same, only the creation changes
- keeping the common pool data source open: applications like Spring Boot try to close data sources but this library does NOT close the common pool data source

This Smart Pool Data Source library is especially meant for Oracle connections since Oracle has so called proxy connections, i.e. connections where you login to a schema using the credentials from another (proxy) account. This allows for everal pools to connect to the proxy account and then start a proxy session immediately after that using `OracleConnection.openProxySession()`.

Furthermore this smart pool data source extends:
- [The HikariCP data source HikariDataSource](https://www.javadoc.io/doc/com.zaxxer/HikariCP/2.7.8/com/zaxxer/hikari/HikariDataSource.html)
- [The Oracle Universal Connection Pool (UCP) data source PoolDataSource](https://javadoc.io/doc/com.oracle.database.jdbc/ucp/21.3.0.0/oracle/ucp/jdbc/PoolDataSource.html)

The architecture allows you to add other pool data sources easily by using delegation. The main requirements are that the pool data sources provide information about pool sizes.

## High Level Design

There is one main build method in class SmartPoolDataSource that needs:
1. [data source properties as derived from Spring Boot DataSourceProperties](https://docs.spring.io/spring-boot/docs/current/api/org/springframework/boot/autoconfigure/jdbc/DataSourceProperties.html)
2. a list of pool data source properties from either Hikari or Oracle

### Data source properties

These are the properties defined in Spring Boot class `DataSourceProperties`:
- String driverClassName
- String url
- String username
- String password
- String type

### Hikari pool data source properties

These are the properties defined in class `PoolDataSourceConfigurationHikari`:
- String poolName
- int maximumPoolSize
- int minimumIdle
- String dataSourceClassName
- boolean autoCommit
- long connectionTimeout
- long idleTimeout
- long maxLifetime
- String connectionTestQuery
- long initializationFailTimeout
- boolean isolateInternalQueries    
- boolean allowPoolSuspension
- boolean readOnly
- boolean registerMbeans
- long validationTimeout  
- long leakDetectionThreshold

### Oracle pool data source properties

These are the properties defined in class `PoolDataSourceConfigurationOracle`:
- String connectionPoolName
- int initialPoolSize
- int minPoolSize
- int maxPoolSize
- String connectionFactoryClassName
- boolean validateConnectionOnBorrow
- int abandonedConnectionTimeout
- int timeToLiveConnectionTimeout
- int inactiveConnectionTimeout
- int timeoutCheckInterval
- int maxStatements
- int connectionWaitTimeout
- long maxConnectionReuseTime
- int secondsToTrustIdleConnection
- int connectionValidationTimeout

### Join multiple pool data sources

Every time you build a smart pool data source (from data source properties and the list of pool data source properties) these steps are executed:
1. the type of data source is determined
2. the appropiate pool data source properties are used to build a smart pool data source
3. 

#### Determination of the data source type

It must be either the `SimplePoolDataSourceOracle` or `SimplePoolDataSourceHikari` class.

This can be specified in the Spring properties file:

```
spring.datasource.type=com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari
```

#### Build a smart pool data source

First, determine:
- the id using all properties except pool name and password
- the common id using all properties except username, password, pool name and pool sizes

The first question: is this id already cached (as SmartPoolDataSource)?

1. yes: return that one
2. no, but there is a SimplePoolDataSource for its id (or common id and the SmartPoolDataSource could be constructed, i.e. joined): return that one
3. no, but there is a SimplePoolDataSource for its common id does and and the SmartPoolDataSource could NOT be constructed (join did NOT work):
   create a SimplePoolDataSource and store it as the most specific, i.e. with the id
4. else, create a SimplePoolDataSource and store it with the common id

After steps 3 and 4 you just need to build a SmartPoolDataSource from the last stored SimplePoolDataSource.

