create table generate_ddl_session_schema_objects
( session_id number not null -- Primary key #1
, seq integer not null -- Primary key #2: Sequence within (session_id)
  constraint generate_ddl_session_schema_objects$ck$seq check (seq >= 1) 
, schema_object_filter_id integer not null
, schema_object_id varchar2(500 byte) not null
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  not null  
, constraint generate_ddl_session_schema_objects$pk
  primary key (session_id, seq)
, constraint generate_ddl_session_schema_objects$uk$1
  unique (session_id, schema_object_id)
, constraint generate_ddl_session_schema_objects$fk$1
  foreign key (schema_object_filter_id, schema_object_id)
  references schema_object_filter_results(schema_object_filter_id, schema_object_id) on delete cascade
, -- The lookup value GENERATE_DDL_SESSIONS.SCHEMA_OBJECT_FILTER_ID must be equal to GENERATE_DDL_SESSION_SCEHMA_OBJECTS.SCHEMA_OBJECT_FILTER_ID.
  -- There is no simple way of doing this o SCHEMA_OBJECTS_API will take care of that.
  constraint generate_ddl_session_schema_objects$fk$2
  foreign key (session_id)
  references generate_ddl_sessions(session_id) on delete cascade
)
;

alter table generate_ddl_session_schema_objects nologging;

-- foreign key index generate_ddl_session_schema_objects$fk$1
create index generate_ddl_session_schema_objects$fk$1
on generate_ddl_session_schema_objects(schema_object_filter_id, schema_object_id);

-- foreign key index generate_ddl_session_schema_objects$fk$2
create index generate_ddl_session_schema_objects$fk$2
on generate_ddl_session_schema_objects(session_id);
