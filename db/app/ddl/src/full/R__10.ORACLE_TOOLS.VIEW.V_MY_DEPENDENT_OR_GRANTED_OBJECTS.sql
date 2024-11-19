CREATE OR REPLACE FORCE VIEW "ORACLE_TOOLS"."V_MY_DEPENDENT_OR_GRANTED_OBJECTS" OF "ORACLE_TOOLS"."T_DEPENDENT_OR_GRANTED_OBJECT"
  WITH OBJECT IDENTIFIER ("ID") BEQUEATH CURRENT_USER AS 
  select  oracle_tools.t_object_grant_object
        ( p_base_object => value(mnso)
        , p_object_schema => null
        , p_grantee => p.grantee
        , p_privilege => p.privilege
        , p_grantable => p.grantable
        )
from    oracle_tools.v_my_named_schema_objects mnso
        inner join oracle_tools.v_my_object_grants_dict p
        on p.table_schema = mnso.object_schema() and p.table_name = mnso.object_name()
where   mnso.object_type() not in ( 'PACKAGE_BODY'
                                  , 'TYPE_BODY'
                                  , 'MATERIALIZED_VIEW' -- grants are on underlying tables
                                  ); 

