CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_GENERATE_DDL_SESSION_BATCH_PARAMETERS" ("OBJECT_SCHEMA", "OBJECT_TYPE", "BASE_OBJECT_SCHEMA", "BASE_OBJECT_TYPE", "NR_OBJECTS", "OBJECT_NAME_TAB", "BASE_OBJECT_NAME_TAB") BEQUEATH CURRENT_USER AS 
  select  object_schema
,       object_type
,       base_object_schema
,       base_object_type
,       nr_objects
,       object_name_tab
,       base_object_name_tab
from    ( with vmsondy as
          ( select  /*+ MATERIALIZE */
                    vmsondy.id
            ,       vmsondy.object_schema() as object_schema
            ,       vmsondy.object_type() as object_type
            ,       vmsondy.object_name() as object_name
            ,       vmsondy.base_object_schema() as base_object_schema
            ,       vmsondy.base_object_type() as base_object_type
            ,       vmsondy.base_object_name() as base_object_name
            ,       vmsondy.column_name() as column_name
            ,       vmsondy.grantee() as grantee
            ,       vmsondy.privilege() as privilege
            ,       vmsondy.grantable() as grantable
            from    oracle_tools.v_my_schema_objects_no_ddl_yet  vmsondy
          ), src as
          ( select  vmsondy.object_type as object_type
            ,       case
                      when vmsondy.object_type in ('CONSTRAINT', 'REF_CONSTRAINT')
                      then null
                      else vmsondy.object_schema
                    end as object_schema
            ,       case
                      when vmsondy.object_type in ('CONSTRAINT', 'REF_CONSTRAINT')
                      then null
                      else vmsondy.object_name
                    end as object_name
            ,       vmsondy.base_object_type as base_object_type
            ,       case
                      when vmsondy.object_type in ('INDEX', 'TRIGGER')
                      then null
                      when vmsondy.object_type = 'SYNONYM' and vmsondy.object_schema = vmsofr.schema_object_filter.schema$
                      then null
                      else vmsondy.base_object_schema
                    end as base_object_schema
            ,       case
                      when vmsondy.object_type in ('INDEX', 'TRIGGER') and vmsondy.object_schema = vmsofr.schema_object_filter.schema$
                      then null
                      when vmsondy.object_type = 'SYNONYM' and vmsondy.object_schema = vmsofr.schema_object_filter.schema$
                      then null
                      else vmsondy.base_object_name
                    end as base_object_name
            ,       vmsondy.column_name
            ,       vmsondy.grantee
            ,       vmsondy.privilege
            ,       vmsondy.grantable
            from    -- here we are only interested in schema objects without DDL
                    vmsondy
                    inner join oracle_tools.v_my_schema_object_filter_results vmsofr
                    on vmsofr.schema_object_id = vmsondy.id
          )
          select  t.object_schema
          ,       t.object_type
          ,       t.base_object_schema
          ,       t.base_object_type
          ,       cast
                  ( multiset
                    ( select  l.object_name
                      from    src l
                      where   l.object_type || 'X' = t.object_type || 'X' -- null == null
                      and     l.object_schema || 'X' = t.object_schema || 'X'
                      and     l.base_object_schema || 'X' = t.base_object_schema || 'X'
                      and     l.object_name is not null
                    ) as oracle_tools.t_text_tab
                  ) as object_name_tab
          ,       cast
                  ( multiset
                    ( select  l.base_object_name
                      from    src l
                      where   l.object_type || 'X' = t.object_type || 'X' -- null == null
                      and     l.object_schema || 'X' = t.object_schema || 'X'
                      and     l.base_object_schema || 'X' = t.base_object_schema || 'X'
                      and     l.base_object_name is not null
                    ) as oracle_tools.t_text_tab
                  ) as base_object_name_tab
          ,       count(*) as nr_objects
          ,       -- This function uses all the group by columns
                  -- hence no special attention needed for just invoking once (I hope)
                  oracle_tools.t_schema_object.ddl_batch_order
                  ( p_object_schema => t.object_schema
                  , p_object_type => t.object_type 
                  , p_base_object_schema => t.base_object_schema 
                  , p_base_object_type => t.base_object_type 
                  ) as ddl_batch_order
          from    src t
          group by
                  t.object_schema
          ,       t.object_type
          ,       t.base_object_schema
          ,       t.base_object_type
        )
order by
        ddl_batch_order;

