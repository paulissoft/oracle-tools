CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_COMMENT_DDL" AS

overriding member procedure uninstall
( self in out nocopy t_comment_ddl
, p_target in t_schema_ddl
)
is
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
  -- replace by an empty comment

  -- GPA 2017-06-28 To avoid COMMENT ON . IS '' 
  if delete_comment
     ( p_column_name => p_target.obj.column_name()
     , p_dict_object_type => p_target.obj.dict_object_type()
     , p_fq_object_name => p_target.obj.fq_object_name()
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

  -- COMMENT ON TABLE "schema"."object" IS ''
  -- COMMENT ON VIEW "schema"."object" IS ''
  -- COMMENT ON MATERIALIZED VIEW "<owner>"."MV_TTSUBSCRIPTION" IS ''
  -- COMMENT ON COLUMN "schema"."object"."column" IS ''
  self.add_ddl
  ( p_verb => 'COMMENT'
  , p_text => delete_comment
              ( p_column_name => p_target.obj.column_name()
              , p_dict_object_type => p_target.obj.dict_object_type()
              , p_fq_object_name => p_target.obj.fq_object_name()
              )
  , p_add_sqlterminator => 0 -- the target text should already contain a sqlterminator (or not)
  );
end uninstall;

end;
/

