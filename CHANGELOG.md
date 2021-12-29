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

## [1.3.0] - 2021-12-28

### Added

- [It should be possible to exclude (temporary) database jobs while generating DDL.](https://github.com/paulissoft/oracle-tools/issues/22)

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

