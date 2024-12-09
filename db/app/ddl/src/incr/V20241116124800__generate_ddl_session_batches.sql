create table generate_ddl_session_batches
( session_id number
  constraint generate_ddl_session_batches$nnc$session_id not null -- Primary key #1
, seq integer
  constraint generate_ddl_session_batches$nnc$seq not null -- Primary key #2 (sequence within parent)
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  constraint generate_ddl_session_batches$nnc$created not null
, object_type varchar2(30 byte)
  constraint generate_ddl_session_batches$nnc$object_type not null
, schema varchar2(128 byte)
, transform_param_list varchar2(4000 byte) -- parameter from pkg_ddl_util.get_schema_ddl
-- select list from cursor c_params in body pkg_ddl_util
, params clob
  constraint generate_ddl_session_batches$ck$params check (params is json strict)
-- some administration
, start_time timestamp(6)
, end_time timestamp(6)
, error_message varchar2(4000 byte)
, constraint generate_ddl_session_batches$pk
  primary key (session_id, seq)
, constraint generate_ddl_session_batches$fk$1
  foreign key (session_id)
  references generate_ddl_sessions(session_id) on delete cascade
)
;

alter table generate_ddl_session_batches nologging;

-- foreign key index generate_ddl_session_batches$fk$2 not necessary

comment on table generate_ddl_session_batches is
    'DDL is generated in batches.';
