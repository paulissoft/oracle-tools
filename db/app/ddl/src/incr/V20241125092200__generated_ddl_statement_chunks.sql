create table generated_ddl_statement_chunks
( generated_ddl_id integer -- Primary key #1
  constraint generated_ddl_statement_chunks$nnc$generated_ddl_id not null
, ddl# integer -- Primary key #2
  constraint generated_ddl_statement_chunks$nnc$ddl# not null
, chunk# integer -- Primary key #3
  constraint generated_ddl_statement_chunks$nnc$chunk# not null
  constraint generated_ddl_statement_chunks$ck$chunk# check (chunk# >= 1)
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  constraint generated_ddl_statement_chunks$nnc$created not null
, chunk varchar2(4000 byte) -- see t_text_tab
, constraint generated_ddl_statement_chunks$pk
  primary key (generated_ddl_id, ddl#, chunk#)
, constraint generated_ddl_statement_chunks$fk$1
  foreign key (generated_ddl_id, ddl#)
  references generated_ddl_statements(generated_ddl_id, ddl#) on delete cascade
)
;

alter table generated_ddl_statement_chunks nologging;

-- no need to create foreign key index generated_ddl_statement_chunks$fk$1 since the primary key starts with those columns

comment on table generated_ddl_statement_chunks is
    'The generated DDL statement chunks.';
