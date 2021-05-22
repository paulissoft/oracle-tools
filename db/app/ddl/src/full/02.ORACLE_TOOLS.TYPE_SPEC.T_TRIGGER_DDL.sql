CREATE TYPE "ORACLE_TOOLS"."T_TRIGGER_DDL" authid current_user under t_schema_ddl
( -- GPA 2017-03-27 #142494703 The DDL generator should remove leading whitespace before WHEN clauses in triggers because that generates differences.
  overriding member procedure add_ddl
  ( self in out nocopy t_trigger_ddl
  , p_verb in varchar2
  , p_text in clob
  , p_add_sqlterminator in integer
  )
)
final;
/

