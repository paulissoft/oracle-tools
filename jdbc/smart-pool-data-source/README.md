# Smart Pool Data Source library

## Table of contents

1. [Introduction](#introduction)
   1. [Business case](#business-case)
   2. [What are the advantages of this library?](#what-are-the-advantages-of-this-library)
2. [High Level Design](#high-level-design)
   1. [Operations on the pool data sources](#operations-on-the-pool-data-sources)
   2. [Hikari pool data source properties](#hikari-pool-data-source-properties)
   3. [Oracle pool data source properties](#oracle-pool-data-source-properties)
   4. [Other operations](#other-operations)
3. [Pitfalls](#pitfalls)
4. [Conclusion](#conclusion)

## Introduction

Here I will describe the JDBC Smart Pool Data Source library, a library designed to operate in an Oracle database environment with several pools (each using a different schema in the same database) where the maximum number of connections may peak but where you want to keep your pool size small and fixed anyway. Typically in a Java Spring Boot application but not limited to that. This library just uses the JDBC data source pools [HikariCP](https://github.com/brettwooldridge/HikariCP) and [Oracle UCP](https://docs.oracle.com/en/database/oracle/oracle-database/23/jjucp/intro.html#GUID-DEC07CE5-F791-4234-BBF9-5C808169BCD2).

This library allows you to use different schemas (usernames) but unlike a more conventional approach with a connection pool for each schema, this one uses the same login credentials (JDBC URL, username, password) but it switches to the schema wanted by the Oracle statement `alter session set current_schema = <current_schema>` that is invoked each time a connection is validated (every connection pool vendor has such an operation). Please note that this comes with a little bit of overhead, compared to default connection ping methods.

### Business case

Let's start with the business case first.

A client of mine, [Blue Current](https://www.bluecurrent.nl), provides smart software, charge points, and services for electric vehicles (EV), electric cars usually. Charge points communicate with the central Oracle Cloud database when they charge an electric car. There are a few thousand Blue Current charge points in the Netherlands and it suffices to say that a fast and reliable communication is paramount. And let's not forget about the costs, since Oracle Cloud costs depend indirectly on the number of connections (actually it depends on the number of CPUs but every CPU has a maximum number of sessions).

Blue Current uses a Java Spring Boot application called Motown from [Infuse](https://infuse-ev.com). It uses the Java Persistence Api (JPA) to connect to database, Oracle is just one of the possible databases. There are 6 Oracle schemas (also known as accounts or users) where the data will be stored to and retrieved from. So, 6 JDBC data sources are needed. The default pool data source from [HikariCP](https://github.com/brettwooldridge/HikariCP) is used as a data source. A pool data source allows you to create a (fixed) maximum number of physical connections (a.k.a. the maximum pool count) and keep those connections in a pool, therefore decreasing the time to connect to the database since usually the (physical) connection is already there. Remember, creating a physical connection is expensive. Another characteristic of a pool data source is that you should not set the maximum number of physical connections too high, please read more about that in this article: [About Pool Sizing](https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing).

So how can we decrease the number of connections and thus costs?
1. by creating virtual pools that delegate the work to a shared pool.
2. since the maximum for each (virtual) pool is usually (too) high, the shared pool will probably need a smaller maximum.
3. by having just one large shared pool you have just one set of credentials (i.e. one user to connect to) and hence that user must be given all the rights to do the work (DML or even DDL). Please note that the user to connect to, need **not** be the schema to switch to.

The username property must be either `proxy_user[schema]` or `schema`. The library will split `proxy_user[schema]` into a login user and a current schema. For `schema` both login user and current schema will be the same. Please note that we do not need a real Oracle proxy account, this notation `proxy_user[schema]` just resembles logging in via a proxy account.

Furthermore, since the virtual connection pools are used to set other properties as well (as in Spring Boot), they must all be the same and the shared connection pool will have the same value (set when the first connection is created).

### What are the advantages of this library?

This Smart Pool Data Source library has the following goals:
- let several (virtual) pool data sources share a large pool data source that does the hard work giving you the opportunity to reduce the number of connections;
- the library is transparent in a Spring Boot environment: the number of (pool) data sources stays the same for the application;
- keep the shared pool data source open as long as possible: applications like Spring Boot try to close data sources when a thread is closed but this library does NOT close the shared pool data source unless all virtual pool data sources using it have been closed.

This Smart Pool Data Source library is meant for Oracle connections since Oracle has that `alter session set current_schema` operation.

Furthermore, this smart pool data source extends:
- [The HikariCP data source HikariDataSource](https://www.javadoc.io/doc/com.zaxxer/HikariCP/2.7.8/com/zaxxer/hikari/HikariDataSource.html)
- [The Oracle Universal Connection Pool (UCP) data source PoolDataSource](https://javadoc.io/doc/com.oracle.database.jdbc/ucp/21.3.0.0/oracle/ucp/jdbc/PoolDataSource.html)

The architecture allows you to add pool data sources from other vendors easily by using delegation.

## High Level Design

There are two pool data sources, each with a default constructor:
- SmartPoolDataSourceHikari
- SmartPoolDataSourceOracle

### Operations on the pool data sources

| Operation | Remark                                                                                                                                      |
|:----------|:--------------------------------------------------------------------------------------------------------------------------------------------|
| CHECK     | All virtual pool property values must be equal (if not an exception is raised).                                                             |
| DELEGATE  | Delegate an operation on a virtual pool data source to the shared pool data source.                                                         |
| SET       | All virtual pool property values must be equal (if not an exception is raised) and the first value is assigned to the shared pool property. |
| SUM       | All virtual pool property values are summed up and the total is assigned to the shared pool property.                                       |

### Hikari pool data source properties

Based on the `HikariDataSource` class.

The following properties can be set for the (virtual) pool data sources and will be consolidated into the shared pool data source.

| Property                  | Operation | Remark                                                                                                                                |
|:--------------------------|:----------|---------------------------------------------------------------------------------------------------------------------------------------|
| maximumPoolSize           | SUM       |                                                                                                                                       |
| minimumIdle               | SUM       |                                                                                                                                       |
| username                  | CHECK     | When a virtual pool username is set, the shared pool username is set too (splitting username into a login user and a current schema). |
| allowPoolSuspension       | SET       |                                                                                                                                       |
| autoCommit                | SET       |                                                                                                                                       |
| catalog                   | SET       |                                                                                                                                       |
| connectionInitSql         | SET       |                                                                                                                                       |
| connectionTimeout         | SET       |                                                                                                                                       |
| dataSourceClassName       | SET       |                                                                                                                                       |
| dataSourceJNDI            | SET       |                                                                                                                                       |
| driverClassName           | SET       |                                                                                                                                       |
| idleTimeout               | SET       |                                                                                                                                       |
| initializationFailTimeout | SET       |                                                                                                                                       |
| isolateInternalQueries    | SET       |                                                                                                                                       |
| jdbcUrl                   | SET       |                                                                                                                                       |
| leakDetectionThreshold    | SET       |                                                                                                                                       |
| loginTimeout              | SET       |                                                                                                                                       |
| maxLifetime               | SET       |                                                                                                                                       |
| readOnly                  | SET       |                                                                                                                                       |
| registerMbeans            | SET       |                                                                                                                                       |
| schema                    | SET       |                                                                                                                                       |
| transactionIsolation      | SET       |                                                                                                                                       |
| validationTimeout         | SET       |                                                                                                                                       |
| connectionTestQuery       | -         | Each virtual pool will have a `getConnectionTestQuery` method that returns `alter session set current_schema = <current_schema>`.     |
| password                  | -         | When a virtual pool password is set, the shared pool password is set too. Passwords will not be checked since the `getPassword` method may raise an exception (not secure). |
| poolName                  | -         | The shared pool name will not be set.                                                                                                 |

### Oracle pool data source properties

Based on the `PoolDataSourceImpl` class.

The following properties can be set for the (virtual) pool data sources and will be consolidated into the shared pool data source.

| Property                      | Operation | Remark                                                                                                                                 |
|:------------------------------|:----------|----------------------------------------------------------------------------------------------------------------------------------------|
| initialPoolSize               | SUM       |                                                                                                                                        |
| maxPoolSize                   | SUM       |                                                                                                                                        |
| minPoolSize                   | SUM       |                                                                                                                                        |
| user                          | CHECK     | When a virtual pool user is set, the shared pool user is set too (splitting username into a login user and a current schema).          |
| ONSConfiguration              | SET       |                                                                                                                                        |
| URL                           | SET       |                                                                                                                                        |
| abandonedConnectionTimeout    | SET       |                                                                                                                                        |
| connectionFactoryClassName    | SET       |                                                                                                                                        |
| connectionValidationTimeout   | SET       |                                                                                                                                        |
| dataSourceName                | SET       |                                                                                                                                        |
| fastConnectionFailoverEnabled | SET       |                                                                                                                                        |
| inactiveConnectionTimeout     | SET       |                                                                                                                                        |
| maxConnectionReuseCount       | SET       |                                                                                                                                        |
| maxConnectionReuseTime        | SET       |                                                                                                                                        |
| maxIdleTime                   | SET       |                                                                                                                                        |
| maxStatements                 | SET       |                                                                                                                                        |
| queryTimeout                  | SET       |                                                                                                                                        |
| secondsToTrustIdleConnection  | SET       |                                                                                                                                        |
| timeToLiveConnectionTimeout   | SET       |                                                                                                                                        |
| timeoutCheckInterval          | SET       |                                                                                                                                        |
| validateConnectionOnBorrow    | SET       | Property validateConnectionOnBorrow will be set to true for each virtual pool (used in conjunction with SQLForValidateConnection).     |
| SQLForValidateConnection      | -         | Each virtual pool will have a `getSQLForValidateConnection` method that returns `alter session set current_schema = <current_schema>`. |
| connectionPoolName            | -         | The shared pool name will not be set.                                                                                                  |
| connectionWaitTimeout         | -         | Deprecated. To be replaced by connectionWaitDurationInMillis.                                                                          |

### Other operations

All other operations excluding getting/setting properties as mentioned above will be delegated **except** these that will raise a `SQLFeatureNotSupportedException` exception:
- `Connection getConnection(String username, String password) throws SQLException`
- `Connection getConnection(Properties labels) throws SQLException` (Oracle only)
- `Connection getConnection(String username, String password, Properties labels) throws SQLException` (Oracle only)
- `void setConnectionTestQuery(String connectionTestQuery)` (Hikari only)
- `void setSQLForValidateConnection(String SQLstring)` (Oracle only)
- `void setValidateConnectionOnBorrow(boolean validateConnectionOnBorrow) throws SQLException` (Only for Oracle and when `validateConnectionOnBorrow` is false, meaning property `SQLForValidateConnection` will not be used)

So this library will only support the `getConnection()` method and it will **not** allow setting connection test statements (since that will be done by the library).

## Pitfalls

Due to the fact that the login user may not be able to issue DDL in other schemas, you must take care of Hibernate settings for DDL/DML operations. In Oracle 23ai you can do something like `grant select any table on schema testuser1 to testuser2;`. See also [Grant Schema Privileges, Oracle 23ai](https://oracle-base.com/articles/23/schema-privileges-23#grant-schema-privileges). That may work also for `grant create any table on schema testuser1 to testuser2;` (test!).

Here an example of a Spring Boot `application.yaml`:

```
# ===
# Hibernate
# ===

# possible values for hibernate.hbm2ddl.auto:
# - validate: validate the schema, makes no changes to the database.
# - create-only: database creation will be generated.
# - drop: database dropping will be generated.
# - update: update the schema.
# - create: creates the schema, destroying previous data.
# - create-drop: drop the schema when the SessionFactory is closed explicitly, typically when the application is stopped.
# - none: does nothing with the schema, makes no changes to the database

hibernate.hbm2ddl.auto=none
```

So when the login user has no rights to create, alter or destroy objects (DDL) in one of the current schemas used, the `hibernate.hbm2ddl.auto` property should be 'none' or 'validate'. In this situation you may need to manually update the objects (or use once the original Hikari/Oracle data sources to update).

## Conclusion

The Smart Pool Data Source library is meant for Oracle databases and it allows you to combine several virtual pool data sources in Java JDBC applications like Spring Boot. The virtual pools are just used to configure the properties. The real work is delegated to a shared pool data source whose properties are either summed up (virtual pool sizes) or set to a virtual property. This can reduce the number of connections (provided you limit the combined maximum pool size for the shared pool). In an Oracle Cloud environment this may reduce costs since they are related to the number of CPUs where each CPU has a limit to the maximum number of connections.

The usage of this smart pool is transparent in a Spring Boot environment. Just the type of the data source needs to change and you must include the current schema in the user(name) property.

## Links

### Testing with JMH

- [Continuous Benchmarking with JMH and JUnit](https://www.retit.de/continuous-benchmarking-with-jmh-and-junit-2/)
- [Java Microbenchmarks with JMH, Part 1](https://blog.avenuecode.com/java-microbenchmarks-with-jmh-part-1)
- [Java Microbenchmarks with JMH, Part 2](https://blog.avenuecode.com/java-microbenchmarks-with-jmh-part-2)
- [Java Microbenchmarks with JMH, Part 3](https://blog.avenuecode.com/java-microbenchmarks-with-jmh-part-3)
