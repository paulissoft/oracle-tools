create table generate_ddl_sessions
( session_id number
  default to_number(sys_context('USERENV', 'SESSIONID'))
  not null
, schema_object_filter_id integer not null
, generate_ddl_configuration_id integer not null
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  not null
, username varchar2(128 byte)
  not null
, updated timestamp(6) -- only set during update
, -- Per session just one active schema object filter:
  -- when you update schema_object_filter_id remove all its related GENERATE_DDL_SESSION_SCHEMA_OBJECTS.
  constraint generate_ddl_sessions$pk
  primary key (session_id) 
, constraint generate_ddl_sessions$fk$1
  foreign key (schema_object_filter_id)
  references oracle_tools.schema_object_filters(id) on delete cascade
, constraint generate_ddl_sessions$fk$2
  foreign key (generate_ddl_configuration_id)
  references oracle_tools.generate_ddl_configurations(id) on delete cascade
)
organization index
tablespace users
;

alter table generate_ddl_sessions nologging;

-- foreign key index generate_ddl_sessions$fk$1
create index generate_ddl_sessions$fk$1
on generate_ddl_sessions(schema_object_filter_id);

-- foreign key index generate_ddl_sessions$fk$2
create index generate_ddl_sessions$fk$2
on generate_ddl_sessions(generate_ddl_configuration_id);
