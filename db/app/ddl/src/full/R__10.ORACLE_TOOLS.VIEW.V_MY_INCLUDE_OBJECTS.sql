CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_INCLUDE_OBJECTS" ("INCLUDE_OBJECT")  BEQUEATH CURRENT_USER AS 
  select  unique
        oracle_tools.t_schema_object.id
        ( p_object_schema => t.object_schema()
        , p_object_type => t.object_type()
        , p_object_name => case when t.object_type() in ('CONSTRAINT', 'INDEX', 'REF_CONSTRAINT') then '*' else t.object_name() end
        , p_base_object_schema => t.base_object_schema()
        , p_base_object_type => t.base_object_type()
        , p_base_object_name => t.base_object_name()
        , p_column_name => case t.object_type() when 'COMMENT' then '*' end
        , p_grantee => case t.object_type() when 'OBJECT_GRANT' then '*' end
        , p_privilege => case t.object_type() when 'OBJECT_GRANT' then '*' end
        , p_grantable => case t.object_type() when 'OBJECT_GRANT' then '*' end
        ) as include_object
from    table
        ( oracle_tools.schema_objects_api.get_schema_objects
          ( p_schema => user
          , p_object_type => null
          , p_object_names => null
          , p_object_names_include => null
          , p_grantor_is_schema => 0
          , p_exclude_objects => null
          , p_include_objects => null
          )
        ) t;

