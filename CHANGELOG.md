# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Types of changes:
- **Added** for new features.
- **Changed** for changes in existing functionality.
- **Deprecated** for soon-to-be removed features.
- **Removed** for now removed features.
- **Fixed** for any bug fixes.
- **Security** in case of vulnerabilities.

## [Unreleased]

- [Some private synonyms are not recognised during DDL export.](https://github.com/paulissoft/oracle-tools/issues/195)

## [4.3.0] - 2025-02-05

### Added

- [Create a git workflow script.](https://github.com/paulissoft/oracle-tools/issues/194)

### Fixed

- [The Flyway purge operation fails.](https://github.com/paulissoft/oracle-tools/issues/193)

## [4.2.0] - 2025-01-10

### Added

- [It is necessary to purge the Flyway history table.](https://github.com/paulissoft/oracle-tools/issues/192)

## [4.1.3] - 2025-01-09

### Fixed

- [DDL generation fails with ORA-65114: space usage in container is too high.](https://github.com/paulissoft/oracle-tools/issues/191)

## [4.1.2] - 2025-01-07

### Fixed

- [File install.sql is not created even though it should.](https://github.com/paulissoft/oracle-tools/issues/189)
- [Generating DDL files takes a long time when sorting by dependencies is used.](https://github.com/paulissoft/oracle-tools/issues/190)

## [4.1.1] - 2024-12-30

### Fixed

- [The package PKG_DDL_DEFS is not granted to PUBLIC.](https://github.com/paulissoft/oracle-tools/issues/188)

## [4.1.0] - 2024-12-29

### Added

- [Reduce the number of circular dependencies for DDL generation code.](https://github.com/paulissoft/oracle-tools/issues/90)

### Changed

- [The DDL generator need not add grants to ADMIN for a Cloud database.](https://github.com/paulissoft/oracle-tools/issues/187)
- [When a DBMS_PARALLEL_EXECUTE task fails it should NOT be dropped for further investigation.](https://github.com/paulissoft/oracle-tools/issues/186)

### Fixed

- [While generating DDL grants to tables/packages (without DDL for the table/package) are ignored.](https://github.com/paulissoft/oracle-tools/issues/185)
- [When generating DDL foreign keys to other schemas are not found anymore.](https://github.com/paulissoft/oracle-tools/issues/184)
- [The instead of trigger UI_APEX_MESSAGES_TRG for view UI_APEX_MESSAGES_V is not added to file db/app/ui/src/full/R__10.VIEW.UI_APEX_MESSAGES_V.sql.](https://github.com/paulissoft/oracle-tools/issues/154)

## [4.0.0] - 2024-12-09

### Added

- [Create an Oracle admin package to recompile all invalid objects in the whole database.](https://github.com/paulissoft/oracle-tools/issues/180)
- [Create a CFG package to better support DDL/DML in incremental Flyway scripts.](https://github.com/paulissoft/oracle-tools/issues/181)

### Changed

- [Use Podman instead of Docker inside Jenkins.](https://github.com/paulissoft/oracle-tools/issues/169)
- [Improve DDL generation performance.](https://github.com/paulissoft/oracle-tools/issues/182)

## [3.4.0] - 2024-09-17

### Added

- [Add dry run to Oracle package MSG_SCHEDULER_PKG.](https://github.com/paulissoft/oracle-tools/issues/170)
- [Add statistics to Java class simple pool data source.](https://github.com/paulissoft/oracle-tools/issues/171)
- [Main classes for Java JDBC pool data source should start with SmartPoolDataSource.](https://github.com/paulissoft/oracle-tools/issues/172)
- [Add Oracle package PKG_REPLICATE_UTIL for replicating sources from one schema to another.](https://github.com/paulissoft/oracle-tools/issues/173)
- [Add max retries, retry delay and retention time to MSG_AQ_PKG.CREATE_QUEUE.](https://github.com/paulissoft/oracle-tools/issues/174)
- [Enhance start/stop MSG scheduler in case of PATO installations.](https://github.com/paulissoft/oracle-tools/issues/new)
- [Use a default processing method when the job scheduler can not be used for the MSG subsystem.](https://github.com/paulissoft/oracle-tools/issues/176)
- [Add pipelined function show_queues to MSG_AQ_PKG.](https://github.com/paulissoft/oracle-tools/issues/178)
- [Add view msg_queue_info_v.](https://github.com/paulissoft/oracle-tools/issues/179)

### Fixed

- [Constant MSG_CONSTANTS_PKG. c_prefer_to_use_utl_http must be moved to WEB_SERVICE_PKG.](https://github.com/paulissoft/oracle-tools/issues/177)

## [3.3.2] - 2024-07-04

### Fixed

- [The smart pool data source statistics class raises a null pointer exception due to not checking the SQL state of an exception.](https://github.com/paulissoft/oracle-tools/issues/168)

## [3.3.1] - 2024-07-02

### Fixed

- [The JDBC class PoolDataSourceStatistics must be made more error proof.](https://github.com/paulissoft/oracle-tools/issues/167)

## [3.3.0] - 2024-07-01

### Added

- [It should be possible to replicate a table between schemas, local or remote.](https://github.com/paulissoft/oracle-tools/issues/164)

### Changed

- [Stability enhancements for database components ADMIN and MSG.](https://github.com/paulissoft/oracle-tools/issues/166)

### Fixed

- [The smart pool data source may use two pool data sources, one fixed and one dynamic.](https://github.com/paulissoft/oracle-tools/issues/165)

## [3.2.0] - 2024-06-03

### Added

- [Provide SQL Developer Code Style Profile.](https://github.com/paulissoft/oracle-tools/issues/163)

### Changed

- [The database UI component should be skipped when there is no APEX needed.](https://github.com/paulissoft/oracle-tools/issues/161)
- [Modifying the MSG_CONSTANTS_PKG blocks due to processes using its constants.](https://github.com/paulissoft/oracle-tools/issues/160)

### Fixed

- [DDL generation on 23c gives this error: ORA-31600: invalid input value OID for parameter NAME in function SET_TRANSFORM_PARAM](https://github.com/paulissoft/oracle-tools/issues/162)

## [3.1.1] - 2024-05-23

### Fixed

- [Wrong JDBC setup for Flyway in release 3.1.0.](https://github.com/paulissoft/oracle-tools/issues/159)

## [3.1.0] - 2024-05-14

### Added

- [Upgrade Maven dependencies.](https://github.com/paulissoft/oracle-tools/issues/158)

## [3.0.0] - 2024-05-13

### Changed

- [Maven coordinates should no longer use oracle-tools but pato instead.](https://github.com/paulissoft/oracle-tools/issues/157)
- [It must be possible to install PATO in a database without APEX installed.](https://github.com/paulissoft/oracle-tools/issues/156)
- [The database directory may also contain a file env.properties to read environment properties from.](https://github.com/paulissoft/oracle-tools/issues/155)
- [The EXT_LOAD_FILE_PKG should not contain references to APEX.](https://github.com/paulissoft/oracle-tools/issues/1)

## [2.8.0] - 2024-04-17

### Added

- [The Java Smart Pool Data Source must be ready for Spring.](https://github.com/paulissoft/oracle-tools/issues/152)

### Fixed

- [The DDL ref constraint object did not exclude materialized views in its lookup.](https://github.com/paulissoft/oracle-tools/issues/153)

## [2.6.1] - 2024-02-14

### Fixed

- [The common pool data source is updated when a second pool with the same properties joins.](https://github.com/paulissoft/oracle-tools/issues/151)

## [2.6.0] - 2024-02-14

### Added

- [Combine multiple Java pool data sources into one in order to reduce resources needed.](https://github.com/paulissoft/oracle-tools/issues/150)

## [2.5.0] - 2024-01-25

### Added

- [Enhance test connection Java program.](https://github.com/paulissoft/oracle-tools/issues/149)

### Fixed

- [Generation of BC_PORTAL scripts does no longer work.](https://github.com/paulissoft/oracle-tools/issues/146)

## [2.4.0] - 2023-11-20

### Fixed

- [Installation of PATO in empty database fails.](https://github.com/paulissoft/oracle-tools/issues/148)

### Added

- [It must be possible to enable Flyway flag outOfOrder when the order of incremental migrations is incorrect.](https://github.com/paulissoft/oracle-tools/issues/147)

## [2.3.1] - 2023-10-25

### Fixed

- [The SQL client does not accept an empty last parameter when a script is invoked.](https://github.com/paulissoft/oracle-tools/issues/145)
- [The ADMIN user needs to grant execute privileges on its packages to public.](https://github.com/paulissoft/oracle-tools/issues/144)
- [The ADMIN user needs SYS privileges for the package ADMIN_SYSTEM_PKG.](https://github.com/paulissoft/oracle-tools/issues/143)

## [2.3.0] - 2023-09-06

### Changed

- [Bump up plugin versions.](https://github.com/paulissoft/oracle-tools/issues/141)

## [2.2.1] - 2023-08-28

### Fixed

- [The DDL generator reserves files for instead of triggers but they are not created.](https://github.com/paulissoft/oracle-tools/issues/139)
- [Oracle Datamodeler custom library fails when the number of foreign key columns is 0.](https://github.com/paulissoft/oracle-tools/issues/138)

## [2.2.0] - 2023-05-31

### Changed

- [Improve robustness of installing and code checking.](https://github.com/paulissoft/oracle-tools/issues/136)

## [2.1.1] - 2023-05-09

### Changed

- Updated PL/SQL documentation.
- No logging by default for package DATA_SQL_PKG.

## [2.1.0] - 2023-05-03

### Added

- [Functionality to use dynamic SQL for queries and DML.](https://github.com/paulissoft/oracle-tools/issues/128)

### Fixed

- [Instead of trigger DDL is not correctly placed in the view DDL file.](https://github.com/paulissoft/oracle-tools/issues/127)

## [2.0.0] - 2023-04-01

This is the first release of Paulissoft Application Tools for Oracle (PATO) after publishing my e-book ["How to build an Oracle database application", Leanpub](https://leanpub.com/build-oracle-apex-application).

### Added

- [Add heartbeat mechanism in order to keep jobs alive.](https://github.com/paulissoft/oracle-tools/pull/120)

## [1.11.0] - 2023-03-06

### Added

- [It should be possible to exchange partitions to a table instead of just dropping them.](https://github.com/paulissoft/oracle-tools/issues/117)
- [Create an asynchronous message subsystem as a replacement for Oracle Query Notification.](https://github.com/paulissoft/oracle-tools/issues/118)

### Fixed

- [The Jenkins pipeline does not merge correctly development into the next branch.](https://github.com/paulissoft/oracle-tools/issues/111)

## [1.10.0] - 2023-01-14

### Added

- [It must be possible to use the Maven daemon in Jenkins.](https://github.com/paulissoft/oracle-tools/issues/82)
- [It must be possible to run actions for different application environments or actions in parallel on Jenkins.](https://github.com/paulissoft/oracle-tools/issues/83)
- [It must be possible to have a dry run for Jenkins.](https://github.com/paulissoft/oracle-tools/issues/84)
- [It must be possible to use a schema object id for specifying the object to (NOT) generate DDL for.](https://github.com/paulissoft/oracle-tools/issues/89)
- [Error logging must include object concerned for DDL generation.](https://github.com/paulissoft/oracle-tools/issues/97)
- [Online interval partitioning support needed.](https://github.com/paulissoft/oracle-tools/issues/105)
- [APEX seed and publish.](https://github.com/paulissoft/oracle-tools/issues/107)

### Deprecated

- [Remove Maven dependency mechanism for use in other projects from the documentation.](https://github.com/paulissoft/oracle-tools/issues/41)

### Fixed

- [It should be possible to exclude (temporary) database jobs while generating DDL.](https://github.com/paulissoft/oracle-tools/issues/22)
- [The strip source schema for generating DDL scripts does not work well.](https://github.com/paulissoft/oracle-tools/issues/91)
- [The DDL generator does not create a correct constraint script.](https://github.com/paulissoft/oracle-tools/issues/92)
- [The excel upload utility does not work with column names with spaces.](https://github.com/paulissoft/oracle-tools/issues/93)
- [The DDL generator can not parse a specific ALTER TABLE MODIFY CHECK constraint.](https://github.com/paulissoft/oracle-tools/issues/95)
- [DBMS_METADATA DDL generation with SCHEMA_EXPORT export does not provide CONSTRAINTS AS ALTER.](https://github.com/paulissoft/oracle-tools/issues/98)
- [When a wrong APEX export file is imported, the import fails but that error is displayed as a warning by Maven.](https://github.com/paulissoft/oracle-tools/issues/101)
- [Can not create DDL for synonym.](https://github.com/paulissoft/oracle-tools/issues/103)

## [1.9.0] - 2022-10-05

### Added

- [It must be possible to test the connection with a timeout.](https://github.com/paulissoft/oracle-tools/issues/77)
- [It must be possible to specify stages in the Jenkins pipeline.](https://github.com/paulissoft/oracle-tools/issues/78)

## [1.8.1] - 2022-10-04

### Fixed

- [The default value for Jenkins environment variables should be an empty string.](https://github.com/paulissoft/oracle-tools/issues/75)

## [1.8.0] - 2022-10-04

### Added

- [The Jenkins job should be able to run without GitHub SSH credentials.](https://github.com/paulissoft/oracle-tools/issues/73)

## [1.7.0] - 2022-09-29

### Added

- [The Docker volume for the Maven local repository must mount to directory owned by jenkins agent group.](https://github.com/paulissoft/oracle-tools/issues/69)
- [It must be possible to specify the SCM username and email as environment variables in Jenkins configuration.](https://github.com/paulissoft/oracle-tools/issues/70)

## [1.6.1] - 2022-09-29

### Fixed

- [The Docker volume for the Maven local repository must mount to directory owned by jenkins agent user.](https://github.com/paulissoft/oracle-tools/issues/66)

## [1.6.0] - 2022-09-28

### Added

- [Add SQL Datamodeler custom library and transformations scripts.](https://github.com/paulissoft/oracle-tools/issues/46)
- [SQL injection must be impossible.](https://github.com/paulissoft/oracle-tools/issues/57)
- [It should be possible to group together (constraints) per base object and install them correctly.](https://github.com/paulissoft/oracle-tools/issues/62)

### Changed

- [DDL generation changes due to sequence start with should be ignored.](https://github.com/paulissoft/oracle-tools/issues/58)
- [DDL generation changes due to timestamp format for dbms_scheduler jobs should be ignored.](https://github.com/paulissoft/oracle-tools/issues/59)

### Fixed

- [Something goes in Jenkins wrong when an APEX export has only changes in the create_application.sql scripts.](https://github.com/paulissoft/oracle-tools/issues/49)
- [The Jenkins handling of (proxy) username should be more user friendly.](https://github.com/paulissoft/oracle-tools/issues/50)
- [When a synonym points to an object that is not accessible, an error (no data found) is returned.](https://github.com/paulissoft/oracle-tools/issues/51)
- [The error translation procedure api_pkg.translate_error does not handle empty parameters well.](https://github.com/paulissoft/oracle-tools/issues/60)
- [The ddl unit test fails when the ORACLE_TOOLS schema has a synonym for a non-existing object.](https://github.com/paulissoft/oracle-tools/issues/61)

## [1.5.0] - 2022-08-22

### Added

- [Set up Continuous Integration / Delivery / Deployment.](https://github.com/paulissoft/oracle-tools/issues/27)

### Changed

- [Upgrade Flyway version.](https://github.com/paulissoft/oracle-tools/issues/45)

### Fixed

- [When DDL is generated with the 'sort objects by dependencies' flag, an error is raised for unknown dependencies.](https://github.com/paulissoft/oracle-tools/issues/47)

## [1.4.0] - 2022-07-17

### Added

- [The generated DDL install.sql should use show errors after every stored procedure.](https://github.com/paulissoft/oracle-tools/issues/37)

### Changed

- [When generating DDL the temporary file should be kept.](https://github.com/paulissoft/oracle-tools/issues/36)

### Fixed

- [The referential constraints are not created in the correct order in the install.sql file.](https://github.com/paulissoft/oracle-tools/issues/35)

## [1.3.2] - 2022-02-23

### Changed

- [Generating DDL for the V5 interface should use the actual output files for the determination of a sequence number](https://github.com/paulissoft/oracle-tools/issues/25)

## [1.3.1] - 2022-01-25

### Fixed

- [Import of APEX application (with translated app) is successful, but returns with error](https://github.com/paulissoft/oracle-tools/issues/24)

## [1.3.0] - 2021-12-28

### Fixed

- [PKG_DDL_UTIL can not find object "BC_PORTAL:INDEX:bcp_addresses_l1:::::::"](https://github.com/paulissoft/oracle-tools/issues/19)
- [Generating DDL fails when a constraint depends on an index and that index has the same name as its table](https://github.com/paulissoft/oracle-tools/issues/20)
- [PKG_DDL_UTIL: ORA-20113: Object BC_PORTAL:INDEX:bcp_addresses_l1:BC_PORTAL::BCP_ADDRESSES:::: is not correct.](https://github.com/paulissoft/oracle-tools/issues/21)

## [1.2.1] - 2021-09-13

### Fixed

- [Can not run unit test](https://github.com/paulissoft/oracle-tools/issues/9)

## [1.2.0] - 2021-09-10

### Added

- [Add for the LOAD FILE utility the ability to determine datatype with a maximum length of 4000 characters for strings.](https://github.com/paulissoft/oracle-tools/issues/3)
- [The DDL subsystem should be able to suppress physical properties for tables, indexes and so on](https://github.com/paulissoft/oracle-tools/issues/5)
- [A new version of pkg_ddl_util is needed.](https://github.com/paulissoft/oracle-tools/issues/7)
- [Add task to recompile PL/SQL code and show PL/SQL warnings.](https://github.com/paulissoft/oracle-tools/issues/11)

### Changed

- [The PKG_DDL_UTIL unit test should use utPLSQL v3](https://github.com/paulissoft/oracle-tools/issues/2)
- [The DDL scripts generated must be compatible with Oracle 12.](https://github.com/paulissoft/oracle-tools/issues/4)
- [Grant objects to public.](https://github.com/paulissoft/oracle-tools/issues/8)

### Fixed

- [The DDL subsystem generates a wrong install.sql for EPC](https://github.com/paulissoft/oracle-tools/issues/6)
- [When DDL is generated the script modification date should remain unchanged if its contents do not change](https://github.com/paulissoft/oracle-tools/issues/12)

