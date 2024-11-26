create table generated_ddl_statements
( generated_ddl_id integer not null -- Primary key #1
, ddl# integer -- Primary key #2 (sequence within parent)
  not null
  constraint generated_ddl_statements$ck$ddl# check (ddl# >= 1) 
, verb varchar2(128 byte)
  not null
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  not null  
, constraint generated_ddl_statements$pk
  primary key (generated_ddl_id, ddl#)
, constraint generated_ddl_statements$fk$1
  foreign key (generated_ddl_id)
  references generated_ddls(id) on delete cascade
)
organization index
tablespace users
including created
overflow tablespace users
;

alter table generated_ddl_statements nologging;

-- no need to create foreign key index generated_ddl_statements$fk$1 since the primary key starts with that column
