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

[Unreleased]

- [It should be possible to exclude (temporary) database jobs while generating DDL.](https://github.com/paulissoft/oracle-tools/issues/22)
- [Remove Maven dependency mechanism for use in other projects from the documentation.](https://github.com/paulissoft/oracle-tools/issues/41)
- [It must be possible to use the Maven daemon in Jenkins.](https://github.com/paulissoft/oracle-tools/issues/82)
- [It must be possible to run actions for different application environments or actions in parallel on Jenkins.](https://github.com/paulissoft/oracle-tools/issues/83)
- [It must be possible to have a dry run for Jenkins.](https://github.com/paulissoft/oracle-tools/issues/84)
- [In Jenkins it must be possible to use NFS for the Maven local repository and the controller/agent workspace.](https://github.com/paulissoft/oracle-tools/issues/85)
- [The strip source schema for generating DDL scripts does not work well.](https://github.com/paulissoft/oracle-tools/issues/91)
- [The DDL generator does not create a correct constraint script.](https://github.com/paulissoft/oracle-tools/issues/92)
- [The excel upload utility does not work with column names with spaces.](https://github.com/paulissoft/oracle-tools/issues/93)
- [The DDL generator can not parse a specific ALTER TABLE MODIFY CHECK constraint.](https://github.com/paulissoft/oracle-tools/issues/95)
- [Error logging must include object concerned for DDL generation.](https://github.com/paulissoft/oracle-tools/issues/97)
- [DBMS_METADATA DDL generation with SCHEMA_EXPORT export does not provide CONSTRAINTS AS ALTER.](https://github.com/paulissoft/oracle-tools/issues/98)
- [When a wrong APEX export file is imported, the import fails but that error is displayed as a warning by Maven.](https://github.com/paulissoft/oracle-tools/issues/101)
- [Online interval partitioning support needed.](https://github.com/paulissoft/oracle-tools/issues/105)

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

