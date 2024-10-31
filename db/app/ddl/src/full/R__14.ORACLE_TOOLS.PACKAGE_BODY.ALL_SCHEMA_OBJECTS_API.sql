CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."ALL_SCHEMA_OBJECTS_API" IS /* -*-coding: utf-8-*- */

g_session_id all_schema_objects.session_id%type := to_number(sys_context('USERENV', 'SESSIONID'));

procedure set_session_id
( p_session_id in all_schema_objects.session_id%type
)
is
begin
  if p_session_id is null
  then
    raise value_error;
  end if;
  g_session_id := p_session_id;
end set_session_id;

function get_session_id
return all_schema_objects.session_id%type
is
begin
  return g_session_id;
end get_session_id;

procedure add
( p_schema_object in t_schema_object
, p_must_exist in boolean
, p_session_id in all_schema_objects.session_id%type
, p_generate_ddl in all_schema_objects.generate_ddl%type
)
is
  -- index 1: update; 2: insert
  l_lwb constant simple_integer := case p_must_exist when true then 1 when false then 2 else 1 end;
  l_upb constant simple_integer := case p_must_exist when true then 1 when false then 2 else 2 end; -- try both when p_must_exist is null
begin
  <<dml_loop>>
  for i_idx in l_lwb .. l_upb
  loop
    case i_idx
      when 1
      then
        update  all_schema_objects t
        set     t.obj = p_schema_object
        ,       t.generate_ddl = nvl(p_generate_ddl, t.generate_ddl)
        where   t.obj.id() = p_schema_object.id();
        
      when 2
      then
        insert into all_schema_objects
        ( session_id
        , seq
        , obj
        , generate_ddl
        )
        values
        ( p_session_id
          -- Since objects are inserted per Oracle session
          -- there is never a problem with another session inserting at the same time for the same session.
        , (select nvl(max(t.seq), 0) + 1 from all_schema_objects t where t.session_id = p_session_id)
        , p_schema_object
        , nvl(p_generate_ddl, 0)
        );
    end case;
      
    case sql%rowcount
      when 0
      then
        if i_idx = 1 and l_upb = 2
        then
          null; -- will still have an insert to come
        else
          raise no_data_found;
        end if;
        
      when 1
      then
        exit dml_loop; -- ok
        
      else
        raise too_many_rows; -- strange
    end case;
  end loop dml_loop;
end add;

procedure add
( p_schema_object_cursor in t_schema_object_cursor
, p_must_exist in boolean
, p_session_id in all_schema_objects.session_id%type
, p_generate_ddl in all_schema_objects.generate_ddl%type
)
is
  l_schema_object_tab t_schema_object_tab;
  l_limit constant simple_integer := 100;
begin
  <<fetch_loop>>
  loop
    fetch p_schema_object_cursor bulk collect into l_schema_object_tab limit l_limit;
    if l_schema_object_tab.count > 0
    then
      for i_idx in l_schema_object_tab.first .. l_schema_object_tab.last
      loop
        -- simple: bulk dml may improve speed but helas
        add
        ( p_schema_object => l_schema_object_tab(i_idx)
        , p_must_exist => p_must_exist
        , p_session_id => p_session_id
        , p_generate_ddl => p_generate_ddl
        );
      end loop;
    end if;
    exit fetch_loop when l_schema_object_tab.count < l_limit; -- netx fetch will return 0 rows
  end loop;
end add;

function find_by_seq
( p_seq in all_schema_objects.seq%type
, p_session_id in all_schema_objects.session_id%type
)
return all_schema_objects%rowtype
is
  l_rec all_schema_objects%rowtype;
begin
  select  t.*
  into    l_rec
  from    all_schema_objects t
  where   t.session_id = p_session_id
  and     t.seq = p_seq;

  return l_rec;
end find_by_seq;

function find_by_object_id
( p_id in varchar2
, p_session_id in all_schema_objects.session_id%type
)
return all_schema_objects%rowtype
is
  l_rec all_schema_objects%rowtype;
begin
  select  t.*
  into    l_rec
  from    all_schema_objects t
  where   t.session_id = p_session_id -- there is a unique index on (session_id, obj.id())
  and     t.obj.id() = p_id;

  return l_rec;
end find_by_object_id;

function ignore_object(p_obj in oracle_tools.t_schema_object)
return integer
is
  pragma udf;
  
  function ignore_object(p_object_type in varchar2, p_object_name in varchar2)
  return integer
  is
  begin
    return
      case
        when p_object_type is null
        then 0        
        when p_object_name is null
        then 0
        -- no dropped tables
        when p_object_type in ('TABLE', 'INDEX', 'TRIGGER', 'OBJECT_GRANT') and p_object_name like 'BIN$%' escape '\'
        then 1
        -- no AQ indexes/views
        when p_object_type in ('INDEX', 'VIEW', 'OBJECT_GRANT') and p_object_name like 'AQ$%' escape '\'
        then 1
        -- no Flashback archive tables/indexes
        when p_object_type in ('TABLE', 'INDEX') and p_object_name like 'SYS\_FBA\_%' escape '\'
        then 1
        -- no system generated indexes
        when p_object_type in ('INDEX') and p_object_name like 'SYS\_C%' escape '\'
        then 1
        -- no generated types by declaring pl/sql table types in package specifications
        when p_object_type in ('SYNONYM', 'TYPE_SPEC', 'TYPE_BODY', 'OBJECT_GRANT') and p_object_name like 'SYS\_PLSQL\_%' escape '\'
        then 1
        -- see http://orasql.org/2012/04/28/a-funny-fact-about-collect/
        when p_object_type in ('SYNONYM', 'TYPE_SPEC', 'TYPE_BODY', 'OBJECT_GRANT') and p_object_name like 'SYSTP%' escape '\'
        then 1
        -- no datapump tables
        when p_object_type in ('TABLE', 'OBJECT_GRANT') and p_object_name like 'SYS\_SQL\_FILE\_SCHEMA%' escape '\'
        then 1
        -- no datapump tables
        when p_object_type in ('TABLE', 'OBJECT_GRANT') and p_object_name like user || '\_DDL' escape '\'
        then 1
        -- no datapump tables
        when p_object_type in ('TABLE', 'OBJECT_GRANT') and p_object_name like user || '\_DML' escape '\'
        then 1
        -- no Oracle generated datapump tables
        when p_object_type in ('TABLE', 'OBJECT_GRANT') and p_object_name like 'SYS\_EXPORT\_FULL\_%' escape '\'
        then 1
        -- no Flyway stuff and other Oracle things
        when p_object_type in ('TABLE', 'OBJECT_GRANT', 'INDEX', 'CONSTRAINT', 'REF_CONSTRAINT') and
             ( p_object_name like 'schema_version%' or
               p_object_name like 'flyway_schema_history%' or
               p_object_name like 'CREATE$JAVA$LOB$TABLE%' )
        then 1
        -- no identity column sequences
        when p_object_type in ('SEQUENCE', 'OBJECT_GRANT') and p_object_name like 'ISEQ$$%' escape '\'
        then 1
        else 0
      end;
  end ignore_object;
begin
  return
    case
      when ignore_object(p_obj.object_type(), p_obj.object_name()) = 1 or
           ignore_object(p_obj.base_object_type(), p_obj.base_object_name()) = 1
      then 1
      else 0
    end;
end ignore_object;

function get_schema_objects
return varchar2 sql_macro
is
begin
  return replace
         ( q'[
select  t.*
,       all_schema_objects_api.ignore_object(t.obj) as ignore_object
from    all_schema_objects t
where   t.session_id = {session_id}
]'       , '{session_id}'
         , g_session_id
         );
end get_schema_objects;

END ALL_SCHEMA_OBJECTS_API;
/

