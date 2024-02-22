# Smart Pool Data Source library

## Introduction

Here I will describe the JDBC Smart Pool Data Source library, a library designed to reduce the number of pools and thus connections as well as a solution to keep the pool open as long as possible making application recovery faster.

### Business case

Let's start with the business case first.

A client of mine, [Blue Current](https://www.bluecurrent.nl), provides smart software, charge points, and services for electric vehicles (EV), electric cars usually. Charge points communicate with the central Oracle Cloud database when they charge an electric car. There are a few thousand Blue Current charge points in the Netherlands and suffices to say, a fast, reliable communication is paramount. And let's not forget about the costs, since Oracle Cloud costs depend indirectly on the number of connections (actually it depends on the number of CPUs but every CPU has a maximum number of sessions).

Blue Current uses a Java Spring Boot application called Motown from [Infuse](https://infuse-ev.com). It uses the Java Persistence Api (JPA) to connect to database, Oracle is just one of the possibilities. There are 6 Oracle schemas (also accounts or users) where the data will be stored to and retrieved from. So, 6 JDBC data sources are needed. The default pool data source from [HikariCP](https://github.com/brettwooldridge/HikariCP) is used as a data source. A pool data source allows you to create a (fixed) maximum number of physical connections (a.k.a. the maximum pool count) and keep those connections in a pool, therefore decreasing the time to connect to the database since usually the (physical) connection is already there. Remember, creating a physical connection is expensive. Another characteristic of a pool data source is that you should not set the maximum number of physical connections too high, please read more about that in this article: [About Pool Sizing](https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing).

So how can we decrease the number of connections and thus costs?
1. by reducing the maximum number of physical connections per pool, however that has already been tried and the number of SQL errors increased by doing this. And it is really a trial and error process, something you do not like to do too long with a mission critical application.
2. by combining pools and thus reduce the number of pools: since pools will usually have idle connections, the combined pool will have more of them so the maximum pool size can be reduced.

So the second option, combining pools, seems the best option.

But how can we do that and maybe more important, how can we tune the combined pool via pool statistics?

### How can we combine pools?

First from [javax.sql.DataSource](https://docs.oracle.com/javase/8/docs/api/javax/sql/DataSource.html):

#### Get a default connection 

```
Connection getConnection() throws SQLException

Attempts to establish a connection with the data source that this DataSource object represents.
```

#### Get a connection with supplied credentials

```
Connection getConnection(String username, String password) throws SQLException

Attempts to establish a connection with the data source that this DataSource object represents.
```

Not all pool data sources support this. Hikari for instance doesn't: there this method is deprecated. Oracle Universal Connection Pool ([UCP](https://docs.oracle.com/en/database/oracle/oracle-database/23/jjucp/intro.html#GUID-DEC07CE5-F791-4234-BBF9-5C808169BCD2)) on the other hand supports this method.

#### How can Oracle Universal Connection Pool (UCP) combine pools?

The idea here is to define all pool characteristics thru configuration. In the case of a Spring Boot application this is rather easy: use the annotation `@ConfigurationProperties`.
Every pool has some specific properties like username, password, pool name and maximum pool size, but also generic properties like the JDBC url, timeout settings and so on. When the generic properties are the same, that can be used to create one common pool where the maximum pool sizes will be accumulated.

So we will have a situation where there are several smart pools who are joined together to an actual combined and rather simple pool. The smart pools each contain the credential information needed to create a physical connection (or get a logical connection with the same credentials). They delegate the work of getting a connection to the simple pool.

So the smart pool also gets a (default) connection via `getConnection()` but only after the smart pool data source library first sets the default credentials via `PoolDataSource.setUser()` and `PoolDataSource.setPassword()`. See also [the Oracle PoolDataSource interface](https://javadoc.io/doc/com.oracle.database.jdbc/ucp/21.3.0.0/oracle/ucp/jdbc/PoolDataSource.html).

#### How can we let Hikari combine pools?

We just saw that it was rather easy to use UCP. But Hikari does not support connections with specific credentials, only the defaults. 

Yeah, you can just set the default user and password like UCP but the connection returned is not guaranteed to have the correct username. Remember that all connections are created at start-up using the credentials at that time. So when it was user X and you ask for user Y now, you will get a user X session. Unless, unless, you ask for every connection while there are still connections available and then when there is none left, you close a physical connection (you can get a physical connection from a logical connection by unwrapping) and then ask again a connection for user Y. Maybe then Hikari will then create a physical connection to Y and return that. And then you do not have to forget to release all logical connections you asked before. Not really a pleasant scenario. 

So, we can just say that Hikari does not support a pool with different users. Unless, Oracle can help us...

And, yes Oracle can help us here. Oracle has the following functionality: [Proxy User Authentication and Connect Through in Oracle Databases](https://oracle-base.com/articles/misc/proxy-users-and-connect-through).

So this means that when you want to connect to users X, Y and Z, you can do that thru proxy user P.

```
create user P identified by <password of P>;
grant create session to P;

alter user X grant connect through P;
alter user Y grant connect through P;
alter user Z grant connect through P;
```

Now you can connect in SQL\*Plus as X like this:

```
SQL> connect P[X]/<password of P>
```

This will lead to one session (one entry in `v$session`).

But if we have three pools with user names `P[X]`, `P[Y]` and `P[Z]`, then we will have three different user names again.

Please note that in UCP this is a correct way of setting up one pool with credentials of just one (proxy) user.

Is there any other solution?

When you have a normal connection to the proxy user and you invoke then the JDBC method `OracleConnection.openProxySession()`, you will get a proxy session to the schema wanted. But, at the expense of a second session (in `v$session`). See also [the OracleConnection class](https://docs.oracle.com/en/database/oracle/oracle-database/23/jajdb/oracle/jdbc/OracleConnection.html).

Although half of these sessions do nothing, they may be counted in the Oracle Cloud as stated before (a maximum of sessions per CPU). 
So we win some with combining pools but we lose a lot by using proxy sessions? 

Well, there is a clever trick to optimize, i.e. decrease the number of sessions: among the user schemas there is always one that is used most (as can be determined by the pool statistics).

Let that user (say X) just connect without a proxy, and let the other users connect thru X.

So we get:

```
alter user Y grant connect through X;
alter user Z grant connect through X;
```

And the user names will become: `X`, `X[Y]` and `X[Z]`.

So the smart pool data source must include the (initial) user to connect to (here `X`) in its common information for Hikari (or other pool implementations that also do not support getting a connection with multiple credentials in one pool). This is unlike pools like UCP where the connect information can be ignored since UCP is able to handle that well.

The algorithm for getting a connection for Hikari is a little bit more complex:
1. get a connection: this can be a normal session or a proxy session;
2. if the current schema (`java.sql.Connection.getSchema()`) is equal to the schema wanted we are done;
3. next, if it is a proxy session, close that proxy session (and if the resulting current schema is the schema wanted we are done);
4. last, open a proxy session for the schema wanted (and the resulting schema must be the same).

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

### What are the advantages of this library?

This Smart Pool Data Source library has the following goals:
- let several pool data sources share a one common pool data source that does the hard work giving you the opportunity to reduce the number of connections;
- every (non-shared) pool data source has information that is not common: username, password, pool sizes and so on;
- the library is transparent in a Spring Boot environment: the number of (pool) data sources stays the same, only the creation changes;
- keep the common pool data source open as long as possible: applications like Spring Boot try to close data sources when a thread is closed but this library does NOT close the common pool data source.

This Smart Pool Data Source library is especially meant for Oracle connections since Oracle has so called proxy connections, i.e. connections where you login to a schema using the credentials from another (proxy) account. This allows for several pools to connect to the proxy account and then start a proxy session immediately after that using `OracleConnection.openProxySession()`.

Furthermore, this smart pool data source extends:
- [The HikariCP data source HikariDataSource](https://www.javadoc.io/doc/com.zaxxer/HikariCP/2.7.8/com/zaxxer/hikari/HikariDataSource.html)
- [The Oracle Universal Connection Pool (UCP) data source PoolDataSource](https://javadoc.io/doc/com.oracle.database.jdbc/ucp/21.3.0.0/oracle/ucp/jdbc/PoolDataSource.html)

The architecture allows you to add other pool data sources easily by using delegation. The main requirement is that the pool data sources provide information about pool sizes.

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

#### Determination of the data source type

It must be either the `SimplePoolDataSourceOracle` or `SimplePoolDataSourceHikari` class.

This can be specified in the Spring properties file:

```
spring.datasource.type=com.paulissoft.pato.jdbc.SimplePoolDataSourceHikari
```

#### Build a smart pool data source

First, determine:
- the id using all properties except pool name and password;
- the common id using all properties except password, pool name and pool sizes;
- for Oracle (proxy) username is not part of the common properties but for Hikari it must be included since Hikari smart pools must share the same (proxy) username, see the discussion above.

The first question: is this id already cached (as SmartPoolDataSource)?

1. yes: return that one
2. no, but there is a SimplePoolDataSource for its id (or common id and the SmartPoolDataSource could be constructed, i.e. joined): return that one
3. no, but there is a SimplePoolDataSource for its common id does and and the SmartPoolDataSource could NOT be constructed (join did NOT work):
   create a SimplePoolDataSource and store it as the most specific, i.e. with the id
4. else, create a SimplePoolDataSource and store it with the common id

After steps 3 and 4 you just need to build a SmartPoolDataSource from the last stored SimplePoolDataSource.
