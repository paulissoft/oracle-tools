create table all_schema_objects
( audsid number default sys_context('USERENV', 'SESSIONID') -- The session id
, seq integer constraint ck$all_schema_objects$seq check (seq is not null and seq >= 1) -- Sequence within parent
, generate_ddl number(1, 0) default 0 constraint ck$all_schema_objects$generate_ddl check (generate_ddl is not null and generate_ddl in (0, 1)) -- Will we generate DDL for this one?
, obj oracle_tools.t_schema_object constraint ck$all_schema_objects$obj check (obj is not null)
, constraint pk$all_schema_objects primary key (audsid, seq)
)
organization index
tablespace data
including generate_ddl
overflow tablespace data;

create unique index uk$all_schema_objects on all_schema_objects (audsid, obj.id());

