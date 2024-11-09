create table generate_ddl_sessions
( session_id number
  default to_number(sys_context('USERENV', 'SESSIONID'))
  not null
, schema_object_filter_id integer not null
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  not null
, -- per session you can use a schema object filter just once: purge if necessary
  constraint generate_ddl_sessions$pk
  primary key (session_id, schema_object_filter_id) 
, constraint generate_ddl_sessions$fk$1
  foreign key (schema_object_filter_id)
  references schema_object_filters(id) on delete cascade
)
;

-- Create a descending index to speed up searching for (last) schema_object_filter_id per session
create index generate_ddl_sessions$idx$1
on generate_ddl_sessions(session_id, created desc);
