create table generated_ddl_statement_chunks
( generated_ddl_id integer not null -- Primary key #1
, ddl# integer -- Primary key #2
  not null
, chunk# integer -- Primary key #3
  not null
  constraint generated_ddl_statement_chunks$ck$chunk# check (chunk# >= 1)
, chunk varchar2(4000 byte) -- see t_text_tab
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  not null  
, constraint generated_ddl_statement_chunks$pk
  primary key (generated_ddl_id, ddl#, chunk#)
, constraint generated_ddl_statement_chunks$fk$1
  foreign key (generated_ddl_id, ddl#)
  references generated_ddl_statements(generated_ddl_id, ddl#) on delete cascade
)
;

alter table generated_ddl_statement_chunks nologging;

-- no need to create foreign key index generated_ddl_statement_chunks$fk$1 since the primary key starts with those columns
