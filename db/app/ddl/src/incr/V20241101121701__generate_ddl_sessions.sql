declare
  l_tablespace_name user_tablespaces.tablespace_name%type;
begin
  select  max(ts.tablespace_name)
  into    l_tablespace_name
  from    user_tablespaces ts
  where   ts.tablespace_name in ('USERS', 'DATA');

  execute immediate utl_lms.format_message(q'<
create table generate_ddl_sessions
( session_id number
  default to_number(sys_context('USERENV', 'SESSIONID'))
  constraint generate_ddl_sessions$nnc$session_id not null
, generate_ddl_configuration_id integer
  constraint generate_ddl_sessions$nnc$generate_ddl_configuration_id not null
, schema_object_filter_id integer
  constraint generate_ddl_sessions$nnc$schema_object_filter_id not null
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  constraint generate_ddl_sessions$nnc$created not null
, username varchar2(128 byte)
  constraint generate_ddl_sessions$nnc$username not null
, updated timestamp(6) -- only set during update
, -- Per session just one active schema object filter:
  -- when you update schema_object_filter_id remove all its related GENERATE_DDL_SESSION_SCHEMA_OBJECTS.
  constraint generate_ddl_sessions$pk
  primary key (session_id) 
, constraint generate_ddl_sessions$fk$1
  foreign key (schema_object_filter_id)
  references oracle_tools.schema_object_filters(id) on delete cascade
, constraint generate_ddl_sessions$fk$2
  foreign key (generate_ddl_configuration_id)
  references oracle_tools.generate_ddl_configurations(id) on delete cascade
)
organization index
tablespace %s
>', l_tablespace_name);
;

  execute immediate q'<
alter table generate_ddl_sessions nologging
>';

-- foreign key index generate_ddl_sessions$fk$1
  execute immediate q'<
create index generate_ddl_sessions$idx$1
on generate_ddl_sessions(schema_object_filter_id)
>';

-- foreign key index generate_ddl_sessions$fk$2
  execute immediate q'<
create index generate_ddl_sessions$idx$2
on generate_ddl_sessions(generate_ddl_configuration_id)
>';

  execute immediate q'<
comment on table generate_ddl_sessions is
    'Information about DDL generation per session id (sys_context(''USERENV'', ''SESSIONID'')). '
>';
end;
/

