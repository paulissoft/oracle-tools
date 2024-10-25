create table all_schema_objects
( audsid number default sys_context('USERENV', 'SESSIONID')
, seq integer constraint ck_my_schema_objects_seq check (seq is not null and seq >= 1)
, obj oracle_tools.t_schema_object constraint ck_my_schema_objects_obj check (obj is not null)
, constraint pk_my_schema_objects primary key (audsid, seq)
);
