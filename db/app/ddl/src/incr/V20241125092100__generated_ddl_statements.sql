declare
  l_tablespace_name user_tablespaces.tablespace_name%type;
begin
  select  max(ts.tablespace_name)
  into    l_tablespace_name
  from    user_tablespaces ts
  where   ts.tablespace_name in ('USERS', 'DATA');

  execute immediate utl_lms.format_message(q'<
create table generated_ddl_statements
( generated_ddl_id integer -- Primary key #1
  constraint generated_ddl_statements$nnc$generated_ddl_id not null
, ddl# integer -- Primary key #2 (sequence within parent)
  constraint generated_ddl_statements$nnc$ddl# not null
  constraint generated_ddl_statements$ck$ddl# check ( ddl# >= 1 )
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  constraint generated_ddl_statements$nnc$created not null
, verb varchar2(128 byte)
, constraint generated_ddl_statements$pk
  primary key (generated_ddl_id, ddl#)
, constraint generated_ddl_statements$fk$1
  foreign key (generated_ddl_id)
  references generated_ddls(id) on delete cascade
)
organization index
tablespace %s
including verb
overflow tablespace %s
>', l_tablespace_name, l_tablespace_name);

  execute immediate q'<
alter table generated_ddl_statements nologging
>';

-- no need to create foreign key index generated_ddl_statements$fk$1 since the primary key starts with that column
  execute immediate q'<
comment on table generated_ddl_statements is
    'The generated DDL statements.'
>';
end;
/
