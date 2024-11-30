create table generate_ddl_configurations
( id integer generated always as identity
  constraint generate_ddl_configurations$nnc$id not null
, transform_param_list varchar2(4000 byte) -- dbms_metadata transform parameters
  constraint generate_ddl_configurations$nnc$transform_param_list not null
, db_version number -- dbms_db_version.version + dbms_db_version.release / 10, e.g. 12.2: meaning DDL generation may change
  constraint generate_ddl_configurations$nnc$db_version not null
, last_ddl_time_schema date -- last_ddl_time of any object in this schema: meaning DDL generation may change
  constraint generate_ddl_configurations$nnc$last_ddl_time_schema not null
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  constraint generate_ddl_configurations$nnc$created not null
, constraint generate_ddl_configurations$pk
  primary key (id) 
, constraint generate_ddl_configurations$uk$1
  unique (transform_param_list, db_version, last_ddl_time_schema) 
, constraint generate_ddl_configurations$ck$1
  check (substr(transform_param_list, 1, 1) = ',')
)
;

alter table generate_ddl_configurations nologging;

comment on table generate_ddl_configurations is
    'A DDL generate configuration including DBMS_METADATA tansformation parameters, database and schema version. ';
