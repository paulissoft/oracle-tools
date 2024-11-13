-- 2147483647 is power(2, 31) - 1, the maximum for positiven
create sequence schema_object_filters$seq minvalue 1 maxvalue 2147483647 start with 1 increment by 1 cycle;

create table schema_object_filters
( id integer 
  default oracle_tools.schema_object_filters$seq.nextval
  not null
  constraint schema_object_filters$ck$id check (id between 1 and 2147483647)
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  not null
, last_modification_time_schema date -- last modification time of any object in this schema (obj.schema)
  not null
, updated timestamp(6)
-- in overflow
, obj oracle_tools.t_schema_object_filter
, hash_bucket raw(2000) not null -- sys.dbms_crypto.hash(obj.serialize(), 3 /* HASH_SH1 */)
, hash_bucket_nr integer
  default 1
  not null
  constraint schema_object_filters$ck$hash_bucket_nr check (hash_bucket_nr >= 1)
, constraint schema_object_filters$pk
  primary key (id)
-- store unique obj instances only (but add hash_bucket_nr since theoretically two objects may have the same hash)
, constraint schema_object_filters$uk$1
  unique (hash_bucket, hash_bucket_nr)
)
organization index
tablespace users
including updated
overflow tablespace users
nested table obj.object_tab$ store as schema_object_filters$obj$object_tab$
nested table obj.object_cmp_tab$ store as schema_object_filters$obj$object_cmp_tab$
;

alter table schema_object_filters nologging;
