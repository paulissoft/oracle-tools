set define on termout on verify off feedback off

define flyway_table = "&1"
define nr_months_to_keep_flyway_table = "&2"

/*
Bootstrap problem: SQL Error: ORA-00904: "ORACLE_TOOLS"."CFG_INSTALL_PKG"."PURGE_FLYWAY_TABLE": invalid identifier
*/
whenever sqlerror exit success

select oracle_tools.cfg_install_pkg.purge_flyway_table('"&flyway_table"', &nr_months_to_keep_flyway_table) as "# rows purged from &_USER..&flyway_table" from dual;

exit sql.sqlcode
