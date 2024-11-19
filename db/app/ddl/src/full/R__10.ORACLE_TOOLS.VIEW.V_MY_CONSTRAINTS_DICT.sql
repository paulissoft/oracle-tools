CREATE OR REPLACE FORCE VIEW "ORACLE_TOOLS"."V_MY_CONSTRAINTS_DICT" BEQUEATH CURRENT_USER AS
  select t.*
from    ( select  c.owner as object_schema
          ,       case when c.constraint_type = 'R' then 'REF_CONSTRAINT' else 'CONSTRAINT' end as object_type
          ,       c.constraint_name as object_name
          ,       c.owner as base_object_schema
          ,       c.table_name as base_object_name
          ,       c.constraint_type
          ,       c.search_condition
          from    all_constraints c
          where   /* Type of constraint definition:
                     C (check constraint on a table)
                     P (primary key)
                     U (unique key)
                     R (referential integrity)
                     V (with check option, on a view)
                     O (with read only, on a view)
                  */
                  c.constraint_type in ('C', 'P', 'U', 'R')
        ) t;
