create table generate_ddl_session_schema_ddls
( session_id number not null -- Primary key #1
, schema_object_id varchar2(500 byte) not null -- Primary key #2
, seq integer not null -- Primary key #3 (sequence within parent)
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  not null  
, ddl oracle_tools.t_ddl -- can not specify a not null constraint directly
, constraint generate_ddl_session_schema_ddls$pk
  primary key (session_id, schema_object_id, seq)
, constraint generate_ddl_session_schema_ddls$fk$1
  foreign key (session_id, schema_object_id)
  references generate_ddl_session_schema_objects(session_id, schema_object_id) on delete cascade
, constraint generate_ddl_session_schema_ddls$ck$1 check (ddl is not null)
)
organization index
tablespace users
including created
overflow tablespace users
nested table ddl.text_tab store as generate_ddl_session_schema_ddls$ddl$text_tab
;

alter table generate_ddl_session_schema_ddls nologging;

-- no need to create foreign key index generate_ddl_session_schema_ddls$fk$1 since the primary key starts with those columns
