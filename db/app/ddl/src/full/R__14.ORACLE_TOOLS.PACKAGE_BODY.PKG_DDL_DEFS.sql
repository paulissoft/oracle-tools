CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."PKG_DDL_DEFS" IS /* -*-coding: utf-8-*- */

  -- DBMS_METADATA object types voor DBA gerelateerde taken (DBA rol)
  g_dba_md_object_type_tab constant t_md_object_type_tab := oracle_tools.t_text_tab
                                                            ( 'CONTEXT'
                                                            /*, 'DEFAULT_ROLE'*/
                                                            , 'DIRECTORY'
                                                            /*, 'FGA_POLICY'*/
                                                            /*, 'ROLE'*/
                                                            /*, 'ROLE_GRANT'*/
                                                            /*, 'ROLLBACK_SEGMENT'*/
                                                            , 'SYSTEM_GRANT'
                                                            /*, 'TABLESPACE'*/
                                                            /*, 'TABLESPACE_QUOTA'*/
                                                            /*, 'TRUSTED_DB_LINK'*/
                                                            /*, 'USER'*/
                                                            );

  -- DBMS_METADATA object types voor de PUBLIC rol
  g_public_md_object_type_tab constant t_md_object_type_tab := oracle_tools.t_text_tab('DB_LINK');

  -- DBMS_METADATA object types ordered by least dependencies (see also sort_objects_by_deps)
  g_schema_md_object_type_tab constant t_md_object_type_tab :=
    oracle_tools.t_text_tab
    ( 'SEQUENCE'
    , 'TYPE_SPEC'
    , 'CLUSTER'
$if oracle_tools.pkg_ddl_defs.c_get_queue_ddl $then
    , 'AQ_QUEUE_TABLE'
    , 'AQ_QUEUE'
$else
    /* ORA-00904: "KU$"."SCHEMA_OBJ"."TYPE": invalid identifier */
    /* voorlopig nog geen queues i.v.m. voorgaand probleem */
$end
    , 'TABLE'
    , 'COMMENT'
    -- een (package) functie kan door een constraint, index of view worden gebruikt
    , 'FUNCTION'
    , 'PACKAGE_SPEC'
    , 'VIEW'
    , 'PROCEDURE'
    , 'MATERIALIZED_VIEW'
    , 'MATERIALIZED_VIEW_LOG'
    , 'PACKAGE_BODY'
    , 'TYPE_BODY'
    -- als de index is gebaseerd op een package functie dan moet ook de body al aangemaakt zijn tijdens aanmaken index
    , 'INDEX'
    , 'TRIGGER'
    , 'OBJECT_GRANT'
    /* zit al bij TABLE */ --,'CONSTRAINT'
    /* zit al bij TABLE */ --,'REF_CONSTRAINT'
    , 'SYNONYM' -- zo laat mogelijk i.v.m. verwijderen publieke synoniemen in synchronize()
    -- vanaf hier is beste volgorde niet bekend
$if oracle_tools.pkg_ddl_defs.c_get_db_link_ddl $then
    , 'DB_LINK'
$end                                                                                   
$if oracle_tools.pkg_ddl_defs.c_get_dimension_ddl $then
    , 'DIMENSION'
$end                                                                                   
$if oracle_tools.pkg_ddl_defs.c_get_indextype_ddl $then
    , 'INDEXTYPE'
$end                                                                                   
    , 'JAVA_SOURCE'
$if oracle_tools.pkg_ddl_defs.c_get_library_ddl $then
    , 'LIBRARY'
$end                                                                                   
$if oracle_tools.pkg_ddl_defs.c_get_operator_ddl $then
    , 'OPERATOR'
$end                                                                                   
    , 'REFRESH_GROUP'
$if oracle_tools.pkg_ddl_defs.c_get_xmlschema_ddl $then
    , 'XMLSCHEMA'
$end 
    , 'PROCOBJ'
    );

  g_dependent_md_object_type_tab constant t_md_object_type_tab :=
    oracle_tools.t_text_tab
    ( 'OBJECT_GRANT'   -- Part of g_schema_md_object_type_tab
    , 'SYNONYM'        -- Part of g_schema_md_object_type_tab
    , 'COMMENT'        -- Part of g_schema_md_object_type_tab
    , 'CONSTRAINT'     -- NOT part of g_schema_md_object_type_tab
    , 'REF_CONSTRAINT' -- NOT part of g_schema_md_object_type_tab
    , 'INDEX'          -- Part of g_schema_md_object_type_tab
    , 'TRIGGER'        -- Part of g_schema_md_object_type_tab
    );

  function get_md_object_type_tab
  ( p_what in varchar2
  )  
  return t_md_object_type_tab
  deterministic
  is
  begin
    return case upper(p_what)
             when 'DBA'
             then g_dba_md_object_type_tab
             when 'PUBLIC'
             then g_public_md_object_type_tab
             when 'SCHEMA'
             then g_schema_md_object_type_tab
             when 'DEPENDENT'
             then g_dependent_md_object_type_tab
           end;
  end get_md_object_type_tab;

end pkg_ddl_defs;
/

