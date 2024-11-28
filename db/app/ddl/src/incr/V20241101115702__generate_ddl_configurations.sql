create table generate_ddl_configurations
( id integer generated always as identity
, transform_param_list varchar2(4000 byte)
  not null
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  not null
, constraint generate_ddl_configurations$pk
  primary key (id) 
, constraint generate_ddl_configurations$ck$1
  check (substr(transform_param_list, 1, 1) = ',')
)
;

alter table generate_ddl_configurations nologging;

