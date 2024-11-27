create table generated_ddls
( id integer generated always as identity
, schema_object_id varchar2(500 byte) not null -- Unique key #1
, last_ddl_time date not null                  -- Unique key #2
, generate_ddl_parameter_id integer not null  -- Unique key #3
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  not null  
, constraint generated_ddls$pk
  primary key (id)
, constraint generated_ddls$uk$1
  unique (schema_object_id, last_ddl_time, generate_ddl_parameter_id)
, constraint generated_ddls$fk$1
  foreign key (schema_object_id)
  references schema_objects(id) on delete cascade
, constraint generate_ddls$fk$2
  foreign key (generate_ddl_parameter_id)
  references oracle_tools.generate_ddl_parameters(id) on delete cascade
)
organization index
tablespace users
including created
overflow tablespace users
;

alter table generated_ddls nologging;

-- no need to create foreign key index generated_ddls$fk$1 since the unique key starts with that column

create index generated_ddls$fk$2
on generated_ddls(generate_ddl_parameter_id);


