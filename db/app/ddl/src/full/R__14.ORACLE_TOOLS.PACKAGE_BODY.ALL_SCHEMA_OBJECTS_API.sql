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
        where   t.obj.id() = p_schema_object.id();
        
      when 2
      then
        insert into all_schema_objects
        ( session_id
        , seq
        , obj
        )
        values
        ( p_session_id
          -- Since objects are inserted per Oracle session
          -- there is never a problem with another session inserting at the same time for the same session.
        , (select nvl(max(t.seq), 0) + 1 from all_schema_objects t where t.session_id = p_session_id)
        , p_schema_object
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
        , p_session_id=> p_session_id
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
return t_schema_object
is
  l_schema_object t_schema_object;
begin
  select  t.obj
  into    l_schema_object
  from    all_schema_objects t
  where   t.session_id = p_session_id
  and     t.seq = p_seq;

  return l_schema_object;
end find_by_seq;

function find_by_object_id
( p_id in varchar2
, p_session_id in all_schema_objects.session_id%type
)
return t_schema_object
is
  l_schema_object t_schema_object;
begin
  select  t.obj
  into    l_schema_object
  from    all_schema_objects t
  where   t.session_id = p_session_id -- there is a unique index on (session_id, obj.id())
  and     t.obj.id() = p_id;

  return l_schema_object;
end find_by_object_id;

function get_schema_objects
return varchar2 sql_macro
is
begin
  return replace
         ( q'[
select  t.seq
,       t.created
,       t.generate_ddl
,       t.obj
from    all_schema_objects t
where   t.session_id = {session_id}
]'       , '{session_id}'
         , g_session_id
         );
end get_schema_objects;

END ALL_SCHEMA_OBJECTS_API;
/

