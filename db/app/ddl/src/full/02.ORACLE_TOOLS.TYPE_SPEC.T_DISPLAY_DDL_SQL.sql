CREATE TYPE "ORACLE_TOOLS"."T_DISPLAY_DDL_SQL" authid current_user as object
( schema_object_id varchar2(500 byte)
, ddl# integer
, verb varchar2(128 byte)
, ddl_info varchar2(1000 byte)
, chunk# integer
, chunk varchar2(4000 byte)
  -- attributes below are only set for the last chunk
, last_chunk number(1, 0) -- 1 or null
, schema_object oracle_tools.t_schema_object -- not null if and only if last_chunk = 1
)
instantiable
final;
/

