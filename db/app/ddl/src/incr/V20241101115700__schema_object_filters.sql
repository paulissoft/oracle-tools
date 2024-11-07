-- 2147483647 is power(2, 31) - 1, the maximum for positiven
create sequence schema_object_filters$seq minvalue 1 maxvalue 2147483647 start with 1 increment by 1 cycle;

create table schema_object_filters
( session_id number default to_number(sys_context('USERENV', 'SESSIONID')) constraint schema_object_filters$ck$session_id check (session_id is not null) -- The session id (v$session.audsid)
, created timestamp(6) default sys_extract_utc(systimestamp) constraint schema_object_filters$ck$created check (created is not null)
, id number default oracle_tools.schema_object_filters$seq.nextval constraint schema_object_filters$ck$id check (id is not null and id between 1 and 2147483647)
, obj oracle_tools.t_schema_object_filter constraint schema_object_filters$ck$obj check (obj is not null)
, constraint schema_object_filters$pk primary key (session_id, created)
, constraint schema_object_filters$uk$1 unique (id)
)
organization index
tablespace users
including id
overflow tablespace users
nested table obj.object_tab$ store as obj_object_tab$ 
nested table obj.object_cmp_tab$ store as obj_object_cmp_tab$ 
;
