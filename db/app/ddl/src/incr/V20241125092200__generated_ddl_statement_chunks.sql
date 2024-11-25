create table generated_ddl_statement_chunks
( session_id number not null -- Primary key #1
, schema_object_id varchar2(500 byte) not null -- Primary key #2
, ddl# integer -- Primary key #3
  not null
, chunk# integer -- Primary key #4
  not null
  constraint generated_ddl_statement_chunks$ck$chunk# check (chunk# >= 1)
, chunk varchar2(4000 byte) -- see t_text_tab
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  not null  
, constraint generated_ddl_statement_chunks$pk
  primary key (session_id, schema_object_id, ddl#, chunk#)
, constraint generated_ddl_statement_chunks$fk$1
  foreign key (session_id, schema_object_id, ddl#)
  references generated_ddl_statements(session_id, schema_object_id, ddl#) on delete cascade
)
;

alter table generated_ddl_statement_chunks nologging;

-- no need to create foreign key index generated_ddl_statement_chunks$fk$1 since the primary key starts with those columns
