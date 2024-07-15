# Smart Pool Data Source library

## Table of contents

1. [Introduction](#introduction)
   1. [Business case](#business-case)
   2. [How can we combine pools?](#how-can-we-combine-pools)
      1. [Get a default connection](#get-a-default-connection)
      2. [Get a connection with supplied credentials](#get-a-connection-with-supplied-credentials)
      3. [An overflow pool and the Oracle Universal Connection Pool (UCP)](#an-overflow-pool-and-the-oracle-universal-connection-pool-ucp)
      4. [An overflow pool and Hikari](#an-overflow-pool-and-hikari)
   3. [What pool statistics are needed?](#what-pool-statistics-are-needed)
   4. [What are the advantages of this library?](#what-are-the-advantages-of-this-library)
2. [High Level Design](#high-level-design)
   1. [Data source properties](#data-source-properties)
   2. [Hikari pool data source properties](#hikari-pool-data-source-properties)
   3. [Oracle pool data source properties](#oracle-pool-data-source-properties)
3. [Conclusion](#conclusion)

## Introduction

Here I will describe the JDBC Smart Pool Data Source library, a library designed to operate in an environment with one or more pools where the maximum number of connections may peak but where you want to keep your pool size small and fixed anyway. Typically in a Java Spring Boot application but not limited to that. This library just uses the JDBC data source pools [HikariCP](https://github.com/brettwooldridge/HikariCP) and [Oracle UCP](https://docs.oracle.com/en/database/oracle/oracle-database/23/jjucp/intro.html#GUID-DEC07CE5-F791-4234-BBF9-5C808169BCD2).

This library does that by creating:
* fixed pool(s) (minimum pool size equals maximum pool size)
* one (shared) dynamic pool per common set of pool characteristics (same URL, same pool properties and so on but not *necessarily* the same username) 

A dynamic pool will **only** be created when there is an overflow for a pool (i.e. the maximum pool size is not equal to the minimum pool size).

An example may make things more clear: let's say you have (originally) two pools with a minimum and maximum pool size of 10 and 15 respectively (same URL, same username and password and so on). Now when you use this library you will get three pools: the two original pools with a minimum and maximum of 10 and a dynamic pool shared by these two with a minimum pool size of 0 and a maximum of 10 (2 * 5). So in total you will still have 20 as minimum pool size and 30 as maximum pool size. The library will use the dynamic pool only when the fixed pool is full (i.e. no idle connections) and the dynamic connections will be closed as fast as possible in order to keep the minimum number of physical connections small.

Furthermore, since analyzing pool behaviour is quite difficult (in order to determine the optimal minimum and maximum pool size), this library calculates and displays pool statistics regularly. Hence, you can start with a simple and basic pool data source type (also part of this library), collect the pool statistics and then you can determine the optimal minimum and maximum pool size (that may differ per pool). After that, you can use the smart pool data source to have a more optimal way of using your resources.

### Business case

Let's start with the business case first.

A client of mine, [Blue Current](https://www.bluecurrent.nl), provides smart software, charge points, and services for electric vehicles (EV), electric cars usually. Charge points communicate with the central Oracle Cloud database when they charge an electric car. There are a few thousand Blue Current charge points in the Netherlands and it suffices to say that a fast and reliable communication is paramount. And let's not forget about the costs, since Oracle Cloud costs depend indirectly on the number of connections (actually it depends on the number of CPUs but every CPU has a maximum number of sessions).

Blue Current uses a Java Spring Boot application called Motown from [Infuse](https://infuse-ev.com). It uses the Java Persistence Api (JPA) to connect to database, Oracle is just one of the possible databases. There are 6 Oracle schemas (also known as accounts or users) where the data will be stored to and retrieved from. So, 6 JDBC data sources are needed. The default pool data source from [HikariCP](https://github.com/brettwooldridge/HikariCP) is used as a data source. A pool data source allows you to create a (fixed) maximum number of physical connections (a.k.a. the maximum pool count) and keep those connections in a pool, therefore decreasing the time to connect to the database since usually the (physical) connection is already there. Remember, creating a physical connection is expensive. Another characteristic of a pool data source is that you should not set the maximum number of physical connections too high, please read more about that in this article: [About Pool Sizing](https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing).

So how can we decrease the number of connections and thus costs?
1. by reducing the maximum number of physical connections per pool, however that has already been tried and the number of SQL errors increased by doing this. And it is really a trial and error process, something you do not want to do (for a long period) with a mission-critical application.
2. by having small fixed pools for the regular work and overflow pools for the peak periods: these overflow pools should really needs a lower maximum pool size.
3. by having just one large pool but then you can have just one set of credentials (i.e. one schema) and hence you must give that schema all the rights to query and manipulate objects from the other schemas including DDL: from a security perspective not the best option.

So the second option, overflow pools, seems the best option.

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

#### An overflow pool and the Oracle Universal Connection Pool (UCP)

The idea here is to define all pool characteristics through configuration. In the case of a Spring Boot application this is rather easy: use the annotation `@ConfigurationProperties`.
Every pool has some specific properties like username, password, pool name and maximum pool size, but also generic properties like the JDBC url, timeout settings and so on. When the generic properties are the same, that can be used to create one shared overflow pool where the maximum pool sizes will be accumulated.

The smart pool data source for Oracle UCP can have two pools:
* always a fixed pool of type `SimplePoolDataSourceOracle` that is a subclass of the standard Oracle UCP pool data source with pool statistics gathering added.
* optionally a dynamic pool of the same type but **only** if the minimum and maximum pool size is not equal

When a connection is requested:
1. when the fixed pool has idle connections (or there is no dynamic pool): use the fixed pool and the default credentials, i.e. use `getConnection()`
2. when the fixed pool has no idle connections and there is a dynamic pool: use the dynamic pool **but** with the credentials of the fixed pool i.e. use `getConnection(String username, String password)`. Please note that also the schema is passed just for verification.

When an exception occurs indicating that a connection time-out has occurred, the other pool will be used to get a connection (if there are two pools).

#### An overflow pool and Hikari

We just saw that it was rather easy to use UCP. But Hikari does not support connections with specific credentials, only the default credentials. 

So, we can just say that Hikari does not support a pool with different users. Unless, Oracle can help us...

And, yes Oracle can help us here. Oracle has the following functionality: [Proxy User Authentication and Connect Through in Oracle Databases](https://oracle-base.com/articles/misc/proxy-users-and-connect-through).

So this means that when you want to connect to users X, Y and Z, you can do that through proxy user P.

```
create user P identified by "<password of P>";
grant create session to P;

alter user X grant connect through P;
alter user Y grant connect through P;
alter user Z grant connect through P;
```

Now you can connect in SQL\*Plus as X like this:

```
SQL> connect P[X]/<password of P>
```

This will lead to exactly one session (one entry in `v$session`).

But the Hikari pool can only have one user, so it will be use `P` that will be the username to connect to. And the schema to connect to later will be provided by the fixed pool. Therefore you need to invoke the JDBC method `OracleConnection.openProxySession()`, that will get you a proxy session to the schema wanted. But, at the expense of a second session (in `v$session`). See also [the OracleConnection class](https://docs.oracle.com/en/database/oracle/oracle-database/23/jajdb/oracle/jdbc/OracleConnection.html).

Although half of these (overflow) sessions do nothing, they may be counted in the Oracle Cloud as stated before (a maximum of sessions per CPU). 
So we can reduce the number of sessions by using an overflow pool but not as much as with an UCP overflow pool.

But there is a clever trick to optimize, i.e. decrease the number of sessions: among the user schemas there is always one that is used most (as can be determined by the pool statistics).
Assume that user X is that user. Now let user X just connect without a proxy (username `X`), and let the other users connect through X (i.e. username `X[Y]` and `X[Z]`).

So we get:

```
alter user Y grant connect through X;
alter user Z grant connect through X;
```

So the usernames will become: `X`, `X[Y]` and `X[Z]`. The smart pool data source for Hikari will determine that they have one (initial) username to connect to: `X`.

The same connection request procedure as for UCP is followed. The only difference is that the schema passed for the overflow pool is really needed to open a proxy session.

### What pool statistics are needed?

The solution must provide easy to analyze statistics such as:
- the number of connections: active, idle and total (active + idle);
- the minimum, average and maximum elapsed time for getting a connection from the pool;
- number of connections per schema;
- the latter broken down into physical, logical and proxy connections.

This must be gathered for two levels:
1. grand total (all types combined)
2. per pool data source

Pool statistics are displayed in debugging mode on every connection request (only level 2) and when an original pool data source closes. In the latter case the statistics are consolidated to the next lower level. Please note that a combined pool is considered closed when all original pools joined to the combined pool have been closed.

### What are the advantages of this library?

This Smart Pool Data Source library has the following goals:
- let several pool data sources share an overflow pool data source that does the hard work giving you the opportunity to reduce the number of connections;
- every (non-shared) pool data source has information that is not common: username, password, pool sizes and so on;
- the library is transparent in a Spring Boot environment: the number of (pool) data sources stays the same for the application, only the creation changes;
- keep the overflow pool data source open as long as possible: applications like Spring Boot try to close data sources when a thread is closed but this library does NOT close the overflow pool data source unless all pool data sources using it have been closed.

This Smart Pool Data Source library is especially meant for Oracle connections since Oracle has so-called proxy connections, i.e. connections where you log in to a schema using the credentials from another (proxy) account. This allows for several pools to connect to the proxy account and then start a proxy session immediately after that using `OracleConnection.openProxySession()`.

Furthermore, this smart pool data source extends:
- [The HikariCP data source HikariDataSource](https://www.javadoc.io/doc/com.zaxxer/HikariCP/2.7.8/com/zaxxer/hikari/HikariDataSource.html)
- [The Oracle Universal Connection Pool (UCP) data source PoolDataSource](https://javadoc.io/doc/com.oracle.database.jdbc/ucp/21.3.0.0/oracle/ucp/jdbc/PoolDataSource.html)

The architecture allows you to add other pool data sources easily by using delegation. The main requirement is that the pool data sources provide information about pool sizes.

## High Level Design

You can create a smart pool data source with either a default constructor or a set of data source properties.

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

## Conclusion

The Smart Pool Data Source library allows you to have small fixed pool data sources in Java JDBC applications like Spring Boot next to one or more overflow pools. This can reduce the number of connections (provided you limit the combined maximum pool size for the overflow pool). In an Oracle Cloud environment this may reduce costs also since they are related to the number of CPUs where each CPU has a limit to the maximum number of connections.

The usage of this smart pool is transparant in a Spring Boot environment. Just the type of the data source needs to change.

Another advantage is that the library shows pool statistics for up to two levels, and they are displayed regularly (at least every hour) and when staring or closing. This allows you to more easily fine tune the pool sizes.

## Links

### Testing with JMH

- [Continuous Benchmarking with JMH and JUnit](https://www.retit.de/continuous-benchmarking-with-jmh-and-junit-2/)
- [Java Microbenchmarks with JMH, Part 1](https://blog.avenuecode.com/java-microbenchmarks-with-jmh-part-1)
- [Java Microbenchmarks with JMH, Part 2](https://blog.avenuecode.com/java-microbenchmarks-with-jmh-part-2)
- [Java Microbenchmarks with JMH, Part 3](https://blog.avenuecode.com/java-microbenchmarks-with-jmh-part-3)
