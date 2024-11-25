create table generated_ddl_statements
( session_id number not null -- Primary key #1
, schema_object_id varchar2(500 byte) not null -- Primary key #2
, ddl# integer -- Primary key #3 (sequence within parent)
  not null
  constraint generated_ddl_statements$ck$ddl# check (ddl# >= 1) 
, verb varchar2(128 byte)
  not null
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  not null  
, constraint generated_ddl_statements$pk
  primary key (session_id, schema_object_id, ddl#)
, constraint generated_ddl_statements$fk$1
  foreign key (session_id, schema_object_id)
  references generate_ddl_session_schema_objects(session_id, schema_object_id) on delete cascade
)
organization index
tablespace users
including created
overflow tablespace users
;

alter table generated_ddl_statements nologging;

-- no need to create foreign key index generated_ddl_statements$fk$1 since the primary key starts with those columns
