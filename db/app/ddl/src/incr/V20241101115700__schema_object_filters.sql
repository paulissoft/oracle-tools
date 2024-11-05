create sequence schema_object_filters$seq minvalue 1 maxvalue 9999999999999999999999999999 start with 1 increment by 1 cycle;

create table schema_object_filters
( session_id number default to_number(sys_context('USERENV', 'SESSIONID')) constraint schema_object_filters$ck$session_id check (session_id is not null) -- The session id (v$session.audsid)
, created timestamp(6) default sys_extract_utc(systimestamp) constraint schema_object_filters$ck$created check (created is not null)
, id number default schema_object_filters$seq.nextval constraint schema_object_filters$ck$id check (id is not null)
, obj oracle_tools.t_schema_object_filter constraint schema_object_filters$ck$obj check (obj is not null)
, constraint schema_object_filters$pk primary key (session_id, created)
, constraint schema_object_filters$uk$1 unique (id)
)
organization index
tablespace data
including id
overflow tablespace data
nested table obj.object_tab$ store as obj_object_tab$ 
nested table obj.object_cmp_tab$ store as obj_object_cmp_tab$ 
;
