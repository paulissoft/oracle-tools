-- 2147483647 is power(2, 31) - 1, the maximum for positiven
create sequence schema_object_filters$seq minvalue 1 maxvalue 2147483647 start with 1 increment by 1 cycle;

create table schema_object_filters
( id number default oracle_tools.schema_object_filters$seq.nextval constraint schema_object_filters$ck$id check (id is not null and id between 1 and 2147483647)
, created timestamp(6) default sys_extract_utc(systimestamp) constraint schema_object_filters$ck$created check (created is not null)
, obj oracle_tools.t_schema_object_filter constraint schema_object_filters$ck$obj check (obj is not null)
, constraint schema_object_filters$pk primary key (id)
)
organization index
tablespace users
including created
overflow tablespace users
nested table obj.object_tab$ store as schema_object_filters$obj$object_tab$
nested table obj.object_cmp_tab$ store as schema_object_filters$obj$object_cmp_tab$
;

-- store unique obj instances only
create unique index schema_object_filters$uk$2 on schema_object_filters (sys.dbms_crypto.hash(obj.serialize(), 3 /* HASH_SH1 */));
