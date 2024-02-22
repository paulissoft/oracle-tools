# Smart Pool Data Source

## Introduction

### Business case

Let's start with the business case first.

A client of mine, [Blue Current](https://www.bluecurrent.nl), provides smart software, charge points, and services for electric vehicles (EV), electric cars usually. Charge points communicate with the central Oracle Cloud database when they charge an electric car. There are a few thousand Blue Current charge points in the Netherlands and suffices to say, a fast, reliable communication is paramount. And let's not forget about the costs, since Oracle Cloud costs depend indirectly on the number of connections (actually it depends on the number of CPUs but every CPU has a maximum number of sessions).

Blue Current uses a Java Spring Boot application called Motown from [Infuse](https://infuse-ev.com). It uses the Java Persistence Api (JPA) to connect to database, Oracle is just one of the possibilities. There are 6 Oracle schemas (also accounts or users) where the data will be stored to and retrieved from. So, 6 JDBC data sources are needed. The default pool data source from [HikariCP](https://github.com/brettwooldridge/HikariCP) is used as a data source. A pool data source allows you to create a (fixed) maximum number of physical connections (a.k.a. the maximum pool count) and keep those connections in a pool, therefore decreasing the time to connect to the database since usually the (physical) connection is already there. Remember, creating a physical connection is expensive. Another characteristic of a pool data source is that you should not set the maximum number of physical connections too high, please read more about that in this article: [About Pool Sizing](https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing).

So how can we can we decrease the number of connections and thus costs?
1. reducing the maximum number of physical connections per pool, however that has already been tried and the number of SQL errors increased by doing this. And it is really a trial and error process, something you do not like to do too long with a mission critical application.
2. combine pools so there will be less pools but with a higher (combined) maximum pool size count: since not all pools will always have the number of active sessions equal to the maximum pool count (i.e. no idle connections) this seems the most viable option.

So the second option, combining pools, seems the best option.

But how can we do that and maybe more important, how can we tune the combined pool via pool statistics?

### How can we combine pools?

### What pool statistics are needed?

The solution must provide easy to analyze statistics such as:
- the number of connections: active, idle and total (active + idle);
- the minimum, average and maximum elapsed time for getting a connection from the pool;
- the latter broken down into physical, logical and proxy connections.

This must be gathered for four levels:
1. grand total (all types combined)
2. total for all pool data sources of a certain type (i.e. Hikari or Oracle)
3. total per combined pool data source
4. per original pool data source

Pool statistics are displayed in debugging mode on every connection request (only level 4) and when an original pool data source closes. In the latter case the statistics are consolidated to the next lower level. And that continues as long as the lower level is also just closed. Please note that a combined pool is considered closed when all original pools joined to the combined pool have been closed.

### What are the advantages of this solution?

This Smart Pool Data Source has the following goals:
- let several pool data sources share a one common pool data source that does the hard work giving you the opportunity to reduce the number of connections
- every (non-shared) pool data source has information that is not common: username, password, pool sizes and so on
- the library is transparent in a Spring Boot environment: the number of (pool) data sources stays the same, only the creation changes
- keeping the common pool data source open: applications like Spring Boot try to close data sources but this library does NOT close the common pool data source

This Smart Pool Data Source library is especially meant for Oracle connections since Oracle has so called proxy connections, i.e. connections where you login to a schema using the credentials from another (proxy) account. This allows for several pools to connect to the proxy account and then start a proxy session immediately after that using `OracleConnection.openProxySession()`.

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
2. the appropriate pool data source properties are used to build a smart pool data source
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

