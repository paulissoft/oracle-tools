CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_COMMENT_DDL" AS

overriding member procedure uninstall
( self in out nocopy oracle_tools.t_comment_ddl
, p_target in oracle_tools.t_schema_ddl
)
is
  l_base_object constant oracle_tools.t_schema_object :=
    oracle_tools.t_schema_object.create_schema_object
    ( p_object_schema => p_target.obj.base_object_schema
    , p_object_type => p_target.obj.base_object_type
    , p_object_name => p_target.obj.base_object_name
    );
  
  function delete_comment
  ( p_column_name in varchar2
  , p_dict_object_type in varchar2
  , p_fq_object_name in varchar2
  )
  return varchar2
  is
  begin
    return
      'COMMENT ON ' ||
      case
        when p_column_name is not null
        then 'COLUMN'
        -- Note: A VIEW comment is treated as a TABLE comment!
        when p_dict_object_type = 'VIEW'
        then 'TABLE'
        else p_dict_object_type
      end ||
      ' ' || 
      p_fq_object_name ||
      case
        when p_column_name is not null
        then '."' || p_column_name || '"'
      end ||
      q'[ IS '']';
  end;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('oracle_tools.t_comment_ddl.UNINSTALL');
  dbug.print
  ( dbug."input"
  , 'p_target.obj.object_schema: %s; p_target.obj.object_type: %s; p_target.obj.object_name: %s'
  , p_target.obj.object_schema
  , p_target.obj.object_type
  , p_target.obj.object_name
  );
  dbug.print
  ( dbug."input"
  , 'p_target.obj.base_object_schema: %s; p_target.obj.base_object_type: %s; p_target.obj.base_object_name: %s'
  , p_target.obj.base_object_schema
  , p_target.obj.base_object_type
  , p_target.obj.base_object_name
  );
  p_target.obj.print;
$end
  -- replace by an empty comment

  -- GPA 2017-06-28 To avoid COMMENT ON . IS '' 
  if delete_comment
     ( p_column_name => p_target.obj.column_name()
     , p_dict_object_type => l_base_object.dict_object_type()
     , p_fq_object_name => l_base_object.fq_object_name()
     ) = delete_comment
     ( p_column_name => null
     , p_dict_object_type => null
     , p_fq_object_name => null
     )
  then
    self.obj.chk(null);
    p_target.obj.chk(null);
    raise program_error;
  end if;

  -- Syntax:
  -- 1) COMMENT ON ( TABLE | MATERIALIZED VIEW ) [ <schema> '.' ] <object> IS ''
  -- 2) COMMENT ON COLUMN [ <schema> '.' ] <object> '.' <column> IS ''
  --
  -- Note: A VIEW comment is treated as a TABLE comment!
  self.add_ddl
  ( p_verb => 'COMMENT'
  , p_text => delete_comment
              ( p_column_name => p_target.obj.column_name()
              , p_dict_object_type => l_base_object.dict_object_type()
              , p_fq_object_name => l_base_object.fq_object_name()
              )
  , p_add_sqlterminator => 0 -- the target text should already contain a sqlterminator (or not)
  );

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end uninstall;

end;
/

