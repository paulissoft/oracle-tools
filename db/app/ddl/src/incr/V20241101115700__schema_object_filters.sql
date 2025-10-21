declare
  l_tablespace_name user_tablespaces.tablespace_name%type;
begin
  -- 2147483647 is power(2, 31) - 1, the maximum for positiven
  execute immediate q'<
create sequence schema_object_filters$seq minvalue 1 maxvalue 2147483647 start with 1 increment by 1 cycle
>';

  select  max(ts.tablespace_name)
  into    l_tablespace_name
  from    user_tablespaces ts
  where   ts.tablespace_name in ('USERS', 'DATA');

  execute immediate utl_lms.format_message(q'<
create table schema_object_filters
( id integer 
  default oracle_tools.schema_object_filters$seq.nextval
  constraint schema_object_filters$nnc$id not null
  constraint schema_object_filters$ck$id check (id between 1 and 2147483647)
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  constraint schema_object_filters$nnc$created not null
, updated timestamp(6)
-- in overflow
, obj_json clob -- representation of t_schema_object_filter
  constraint schema_object_filters$nnc$obj_json not null
  constraint schema_object_filters$ck$obj_json check (obj_json is json strict)
, hash_bucket raw(2000) -- sys.dbms_crypto.hash(obj.serialize(), 3 /* HASH_SH1 */)
  constraint schema_object_filters$nnc$hash_bucket not null
, hash_bucket_nr integer
  default 1
  constraint schema_object_filters$nnc$hash_bucket_nr not null
  constraint schema_object_filters$ck$hash_bucket_nr check (hash_bucket_nr >= 1)
, constraint schema_object_filters$pk
  primary key (id)
-- store unique obj instances only (but add hash_bucket_nr since theoretically two objects may have the same hash)
, constraint schema_object_filters$uk$1
  unique (hash_bucket, hash_bucket_nr)
)
organization index
tablespace %s
including updated
overflow tablespace %s
>', l_tablespace_name, l_tablespace_name);

  execute immediate q'<
alter table schema_object_filters nologging
>';

  execute immediate q'<
comment on table schema_object_filters is
    'The filter for schema objects.'
>';
end;
/
