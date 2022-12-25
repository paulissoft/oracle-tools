begin
  for r in
  ( select  'drop type ' || object_name as cmd
    from    user_objects
    where   object_type = 'TYPE'
    and     object_name = 'T_SCHEMA_OBJECT_FILTER'
  )
  loop
    execute immediate r.cmd;
  end loop;

  execute immediate q'[
CREATE TYPE "ORACLE_TOOLS"."T_SCHEMA_OBJECT_FILTER" authid current_user as object
( schema$ varchar2(30 char)
, grantor_is_schema$ integer
, objects_tab$ oracle_tools.t_text_tab
, objects_cmp_tab$ oracle_tools.t_text_tab
, nr_excluded_objects$ integer
, match_count$ integer
, match_count_ok$ integer
, match_perc_threshold$ integer
, constructor function t_schema_object_filter
  ( self in out nocopy oracle_tools.t_schema_object_filter
  , p_schema in varchar2 default user
  , p_object_type in varchar2 default null
  , p_object_names in varchar2 default null
  , p_object_names_include in integer default null
  , p_grantor_is_schema in integer default 0
  , p_exclude_objects in clob default null
  , p_include_objects in clob default null
  )
  return self as result
, member function schema return varchar2 deterministic
, member function grantor_is_schema return integer deterministic
, member function match_perc return integer deterministic
, member function match_perc_threshold return integer deterministic
, member procedure print
  ( self in oracle_tools.t_schema_object_filter
  )
, member function matches_schema_object
  ( self in oracle_tools.t_schema_object_filter
  , p_schema_object_id in varchar2
  )
  return integer
  deterministic
, member procedure get_schema_objects
  ( self in out nocopy oracle_tools.t_schema_object_filter 
  , p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
  )
)
instantiable
final]';

  execute immediate 'GRANT EXECUTE ON T_SCHEMA_OBJECT_FILTER TO PUBLIC';
end;
/
