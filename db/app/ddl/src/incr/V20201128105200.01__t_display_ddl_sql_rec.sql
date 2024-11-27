begin
  execute immediate q'[
create type t_display_ddl_sql_rec authid definer as object
( schema_object_id varchar2(500 byte)
, ddl# integer
, verb varchar2(128 byte)
, ddl_info varchar2(1000 byte)
, chunk# integer
, chunk varchar2(4000 byte)
)
instantiable
final]';
end;
/
