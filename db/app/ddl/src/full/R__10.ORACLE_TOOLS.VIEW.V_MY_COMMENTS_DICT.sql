CREATE OR REPLACE FORCE VIEW "ORACLE_TOOLS"."V_MY_COMMENTS_DICT" ("BASE_OBJECT_SCHEMA", "BASE_OBJECT_TYPE", "BASE_OBJECT_NAME", "COLUMN_NAME") BEQUEATH CURRENT_USER AS 
  select  c."BASE_OBJECT_SCHEMA",c."BASE_OBJECT_TYPE",c."BASE_OBJECT_NAME",c."COLUMN_NAME"
from    ( -- table/view comments
          select  t.owner             as base_object_schema
          ,       t.table_type        as base_object_type
          ,       t.table_name        as base_object_name
          ,       null                as column_name
          from    all_tab_comments t
          where   t.table_type in ('TABLE', 'VIEW')
          and     t.comments is not null
          union all
          -- materialized view comments
          select  m.owner             
          ,       'MATERIALIZED_VIEW'
          ,       m.mview_name        
          ,       null                
          from    all_mview_comments m
          where   m.comments is not null
          union all
          -- column comments
          select  c.owner             
          ,       ( select  o.object_type
                    from    all_objects o
                    where   o.owner = c.owner
                    and     o.object_name = c.table_name
                  )                   
          ,       c.table_name        
          ,       c.column_name       
          from    all_col_comments c
          where   c.comments is not null
        ) c;

