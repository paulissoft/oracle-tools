create table generate_ddl_session_schema_objects
( session_id number -- Primary key #1
  constraint generate_ddl_session_schema_objects$nnc$session_id not null
, schema_object_filter_id integer -- derivable from session_id, however needed for generate_ddl_session_schema_objects$fk$1
  constraint generate_ddl_session_schema_objects$nnc$schema_object_filter_id not null
, schema_object_id varchar2(500 byte)
  constraint generate_ddl_session_schema_objects$nnc$schema_object_id not null  
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  constraint generate_ddl_session_schema_objects$nnc$created not null
, last_ddl_time date -- all_objects.last_ddl_time
, generate_ddl_configuration_id integer
, ddl_output_written integer
  constraint generate_ddl_session_schema_objects$ck$ddl_output_written check (ddl_output_written = 1)
, constraint generate_ddl_session_schema_objects$pk
  primary key (session_id, schema_object_id)
, constraint generate_ddl_session_schema_objects$fk$1
  foreign key (schema_object_filter_id, schema_object_id)
  references schema_object_filter_results(schema_object_filter_id, schema_object_id) on delete cascade
, -- The lookup value GENERATE_DDL_SESSIONS.SCHEMA_OBJECT_FILTER_ID must be equal to GENERATE_DDL_SESSION_SCEHMA_OBJECTS.SCHEMA_OBJECT_FILTER_ID.
  -- There is no simple way of doing this so SCHEMA_OBJECTS_API will take care of that.
  constraint generate_ddl_session_schema_objects$fk$2
  foreign key (session_id)
  references generate_ddl_sessions(session_id) on delete cascade
, constraint generate_ddl_session_schema_objects$fk$3
  foreign key (schema_object_id, last_ddl_time, generate_ddl_configuration_id)
  references generated_ddls(schema_object_id, last_ddl_time, generate_ddl_configuration_id) on delete cascade
)
organization index
tablespace users
;

alter table generate_ddl_session_schema_objects nologging;

-- foreign key index generate_ddl_session_schema_objects$fk$1
create index generate_ddl_session_schema_objects$fk$1
on generate_ddl_session_schema_objects(schema_object_filter_id, schema_object_id);

-- foreign key index generate_ddl_session_schema_objects$fk$2
create index generate_ddl_session_schema_objects$fk$2
on generate_ddl_session_schema_objects(session_id);

-- foreign key index generate_ddl_session_schema_objects$fk$3
create index generate_ddl_session_schema_objects$fk$3
on generate_ddl_session_schema_objects(schema_object_id, last_ddl_time, generate_ddl_configuration_id);

comment on table generate_ddl_session_schema_objects is
    'Information about DDL to generate for schema objects for a specific session.';
