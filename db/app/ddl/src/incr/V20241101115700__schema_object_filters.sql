create sequence schema_object_filters$seq start with 1;

create table schema_object_filters
( id number default schema_object_filters$seq.nextval
, session_id number default to_number(sys_context('USERENV', 'SESSIONID')) constraint schema_object_filters$ck$session_id check (session_id is not null) -- The session id (v$session.audsid)
, created timestamp(6) default sys_extract_utc(systimestamp) constraint schema_object_filters$ck$created check (created is not null)
, obj oracle_tools.t_schema_object_filter constraint schema_object_filters$ck$obj check (obj is not null)
, constraint schema_object_filters$pk primary key (id)
)
organization index
tablespace data
including created
overflow tablespace data
;

