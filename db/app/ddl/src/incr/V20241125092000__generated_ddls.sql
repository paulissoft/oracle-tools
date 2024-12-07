create table generated_ddls
( id integer generated always as identity
  constraint generated_ddls$nnc$id not null
, schema_object_id varchar2(500 byte)   -- Unique key #1
  constraint generated_ddls$nnc$schema_object_id not null
, last_ddl_time date                    -- Unique key #2
  constraint generated_ddls$nnc$last_ddl_time not null
, generate_ddl_configuration_id integer -- Unique key #3
  constraint generated_ddls$nnc$generate_ddl_configuration_id not null
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  constraint generated_ddls$nnc$created not null
, constraint generated_ddls$pk
  primary key (id)
, constraint generated_ddls$uk$1
  unique (schema_object_id, last_ddl_time, generate_ddl_configuration_id)
, constraint generate_ddls$fk$1
  foreign key (generate_ddl_configuration_id)
  references oracle_tools.generate_ddl_configurations(id) on delete cascade
, constraint generated_ddls$fk$2
  foreign key (schema_object_id)
  references schema_objects(id) on delete cascade
)
organization index
tablespace users
including created
overflow tablespace users
;

alter table generated_ddls nologging;

create index generated_ddls$idx$1
on generated_ddls(generate_ddl_configuration_id);

-- no need to create foreign key index generated_ddls$fk$2 since the unique key starts with that column

comment on table generated_ddls is
    'The generated DDL info for a specific schema object id, last DDL time and configuration.';
