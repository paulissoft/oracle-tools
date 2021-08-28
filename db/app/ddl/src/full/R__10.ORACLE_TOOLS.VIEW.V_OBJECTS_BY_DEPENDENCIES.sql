CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_OBJECTS_BY_DEPENDENCIES" AS 
select  t.object_type
,       t.object_name
,       t.dependency_list
,       t.nr
from    table
        ( oracle_tools.pkg_ddl_util.sort_objects_by_deps
          ( cursor
            ( select  o.owner
              ,       o.type
              ,       o.name
              from    table(oracle_tools.pkg_ddl_util.get_schema_object_info(user)) o
            )
          , user
          )
        ) t;
