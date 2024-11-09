CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_COMMENT_OBJECT" AS

constructor function t_comment_object
( self in out nocopy oracle_tools.t_comment_object
, p_base_object in oracle_tools.t_named_object
, p_object_schema in varchar2
, p_column_name in varchar2
)
return self as result
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCTOR');
  dbug.print
  ( dbug."input"
  , 'p_base_object.id(): %s; p_object_schema: %s; p_column_name: %s'
  , p_base_object.id()
  , p_object_schema
  , p_column_name
  );
$end

  if p_base_object is null
  then
    self.base_object_id$ := null;
  else
    self.base_object_id$ := p_base_object.id;
  end if;
  self.network_link$ := null;
  self.object_schema$ := p_object_schema;
  self.column_name$ := p_column_name;

  oracle_tools.t_schema_object.set_id(self);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end

  return;
end;

-- begin of getter(s)

overriding member function object_type
return varchar2
deterministic
is
begin
  return 'COMMENT';
end object_type;

overriding member function column_name
return varchar2
deterministic
is
begin
  return self.column_name$;
end column_name;

-- end of getter(s)

overriding member procedure chk
( self in oracle_tools.t_comment_object
, p_schema in varchar2
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CHK');
$end

  oracle_tools.pkg_ddl_util.chk_schema_object(p_dependent_or_granted_object => self, p_schema => p_schema);

  if self.object_schema() is not null
  then
    oracle_tools.pkg_ddl_error.raise_error
    ( oracle_tools.pkg_ddl_error.c_invalid_parameters
    , 'Object schema should be empty.'
    , self.schema_object_info()
    );
  end if;
  if self.object_name() is not null
  then
    oracle_tools.pkg_ddl_error.raise_error
    ( oracle_tools.pkg_ddl_error.c_invalid_parameters
    , 'Object name should be empty.'
    , self.schema_object_info()
    );
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end
end chk;

overriding member function dict_object_exists
return integer -- 0/1
is
  l_count pls_integer;
  l_owner constant all_objects.object_type%type := self.object_schema();
  l_object_type constant all_objects.object_type%type := self.dict_object_type();
  l_object_name constant all_objects.object_type%type := self.object_name();
begin
  select  sign(count(*))
  into    l_count
  from    ( select  1
            from    all_tab_comments t
            where   l_object_type in ('TABLE', 'VIEW')
            and     t.comments is not null
            and     t.owner = l_owner
            and     t.table_type = l_object_type
            and     t.table_name = l_object_name
            union all
            -- materialized view comments
            select  1
            from    all_mview_comments m
            where   l_object_type = 'MATERIALIZED VIEW'
            and     m.comments is not null
            and     m.owner = l_owner
            and     m.mview_name = l_object_name
            union all
            -- column comments
            select  1
            from    all_col_comments c                    
            where   l_object_type in ('TABLE', 'VIEW', 'MATERIALIZED VIEW')
            and     c.comments is not null
            and     c.owner = l_owner
            and     c.table_name = l_object_name
          );
  return l_count;
end;

end;
/

