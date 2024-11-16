create table generate_ddl_session_schema_ddl_batches
( session_id number not null -- Primary key #1
, schema_object_id varchar2(500 byte) not null -- Primary key #2
, seq integer not null -- Primary key #3 (sequence within parent)
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  not null  
-- select list from cursor c_params in body pkg_ddl_util
, object_type varchar2(30 byte)
, object_schema varchar2(128 byte)
, base_object_schema varchar2(128 byte)
, object_name_tab oracle_tools.t_text_tab
, base_object_name_tab oracle_tools.t_text_tab
, nr_objects integer
, constraint generate_ddl_session_schema_ddl_batches$pk
  primary key (session_id, schema_object_id, seq)
, constraint generate_ddl_session_schema_ddl_batches$fk$1
  foreign key (session_id, schema_object_id)
  references generate_ddl_session_schema_objects(session_id, schema_object_id) on delete cascade
)
nested table object_name_tab store as generate_ddl_session_schema_ddl_batches$object_name_tab
nested table base_object_name_tab store as generate_ddl_session_schema_ddl_batches$base_object_name_tab
;

alter table generate_ddl_session_schema_ddl_batches nologging;

-- no need to create foreign key index generate_ddl_session_schema_ddl_batches$fk$1 since the primary key starts with those columns
