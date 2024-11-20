create table generate_ddl_session_schema_ddl_chunks
( session_id number not null -- Primary key #1
, schema_object_id varchar2(500 byte) not null -- Primary key #2
, ddl# integer -- Primary key #3
  not null
, line# integer -- Primary key #4
  not null
  constraint generate_ddl_session_schema_ddl_chunks$ck$line# check (line# >= 1)
, text varchar2(4000 char)
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  not null  
, constraint generate_ddl_session_schema_ddl_chunks$pk
  primary key (session_id, schema_object_id, ddl#, line#)
, constraint generate_ddl_session_schema_ddl_chunks$fk$1
  foreign key (session_id, schema_object_id, ddl#)
  references generate_ddl_session_schema_ddls(session_id, schema_object_id, ddl#) on delete cascade
)
organization index
tablespace users
;

alter table generate_ddl_session_schema_ddl_chunks nologging;

-- no need to create foreign key index generate_ddl_session_schema_ddl_chunks$fk$1 since the primary key starts with those columns
