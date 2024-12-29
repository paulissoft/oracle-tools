CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_DDL_DEFS" AUTHID DEFINER IS

/**

This package contains DDL definitions (constants/types) based on `DBMS_METADATA` and `DBMS_METADATA_DIFF`.

**/

/**/

/* CONSTANTS */
-- see 11g / 12c licensing
c_use_sqlterminator constant boolean := false; -- pkg_ddl_util v4/v5

-- 0: none, 1: standard, 2: verbose, 3: even more verbose
c_debugging constant naturaln := $if oracle_tools.cfg_pkg.c_debugging $then 1 $else 0 $end; -- never change the last value
c_debugging_parse_ddl constant boolean := $if oracle_tools.cfg_pkg.c_debugging $then c_debugging >= 2 $else false $end; -- idem
c_debugging_dbms_metadata constant boolean := $if oracle_tools.cfg_pkg.c_debugging $then c_debugging >= 2 $else false $end; -- idem

c_default_parallel_level constant natural := null; -- Number of parallel jobs; zero if run in serial; NULL uses the default parallelism.

-- Duplicate code see DDL_CRUD_API but we do notwant package spec A to invoke package spec B and vice versa.
subtype t_session_id is integer;
subtype t_session_id_nn is t_session_id not null;  

/*
-- Start of bugs/features (oldest first)
*/

-- GPA 2016-12-19 #136334705 Only user created items from ALL_OBJECTS
c_#136334705 constant boolean := true;

-- GPA 2017-02-01 #138707615 named not null constraints are recreated
c_#138707615_1 constant boolean := true;

-- GPA 2017-01-31 #138707615 The diff DDL for XBIKE contained errors.
--
-- Constraints with different indexes fail because the index is already there:
--
-- ALTER TABLE "<owner>"."WORKORDERTYPE" ADD CONSTRAINT "WORKORDERTYPE_PK" PRIMARY KEY ("SEQ")
-- USING INDEX (CREATE UNIQUE INDEX "<owner>"."WORKORDERTYPE1_PK" ON "<owner>"."WORKORDERTYPE" ("SEQ")
-- PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS
-- TABLESPACE "YSSINDEX" )  ENABLE;
--
c_#138707615_2 constant boolean := true;

-- GPA 2017-02-01 #138550763 As a developer I want to migrate types correctly.
c_#138550763 constant boolean := true;

-- GPA 2017-02-01 As a developer I want to migrate function based indexes correctly.
c_#138550749 constant boolean := true;

-- GPA 2017-03-06 Capture invalid objects before releasing to next enviroment.
c_#140920801 constant boolean := true; -- values: false - check nothing, true - allow checks

-- GJP 2022-09-25
-- DDL generation changes due to sequence start with should be ignored.
-- https://github.com/paulissoft/oracle-tools/issues/58
c_set_start_with_to_minvalue constant boolean := true;

-- GJP 2022-12-14 The DDL generator does not create a correct constraint script.
--
-- ALL_OBJECTS, ALL_INDEXES and ALL_CONSTRAINTS have a GENERATED column to separate system generated and user generated items.
-- The distinct values for the first two are 'N' and 'Y', for the latter these are 'GENERATED NAME' and 'USER NAME'.
-- This filtering must be applied to all usages.
--
-- This supersedes bug #136334705 (see above) since that is only for ALL_OBJECTS.
--
-- See also https://github.com/paulissoft/oracle-tools/issues/92.
c_exclude_system_objects constant boolean := true;
c_exclude_system_indexes constant boolean := true;
c_exclude_system_constraints constant boolean := false; -- true: only 'USER NAME'

-- If exclude not null constraints is false code with c_#138707615_1 (true/false irrelevant) will be inactive.
c_exclude_not_null_constraints constant boolean := false;

c_err_pipelined_no_data_found constant boolean := true; -- false: no exception for no_data_found in  pipelined functions

/*
-- End of bugs/features
*/

-- see also generate_ddl.pl
c_get_queue_ddl constant boolean := false;
c_get_db_link_ddl constant boolean := false;
c_get_dimension_ddl constant boolean := false;
c_get_indextype_ddl constant boolean := false;
c_get_library_ddl constant boolean := false;
c_get_operator_ddl constant boolean := false;
c_get_xmlschema_ddl constant boolean := false;

c_transform_param_list constant varchar2(4000 byte) :=
  'CONSTRAINTS,CONSTRAINTS_AS_ALTER,FORCE,PRETTY,REF_CONSTRAINTS,SEGMENT_ATTRIBUTES,TABLESPACE';

/* A list of dbms_metadata transformation parameters that will be set to TRUE. */

/* TYPES */
subtype t_dict_object_type is all_objects.object_type%type;
subtype t_dict_object_type_nn is t_dict_object_type not null;

subtype t_metadata_object_type is varchar2(30 byte);
subtype t_metadata_object_type_nn is t_metadata_object_type not null;

subtype t_object_name is varchar2(128 byte);
subtype t_object_name_nn is t_object_name not null;

-- key: owner.object_type.object_name[.grantee]
subtype t_object is varchar2(500 byte);
subtype t_object_nn is t_object not null;

subtype t_numeric_boolean is natural; -- must be null, 0 or 1
subtype t_numeric_boolean_nn is naturaln; -- must be 0 or 1

subtype t_schema is varchar2(30 byte);
subtype t_schema_nn is t_schema not null;

subtype t_object_names is varchar2(4000 byte);
subtype t_object_names_nn is t_object_names not null;

subtype t_objects is clob;

subtype t_network_link is all_db_links.db_link%type;
subtype t_network_link_nn is t_network_link not null;

type t_transform_param_tab is table of boolean index by varchar2(4000 char);

subtype t_md_object_type_tab is oracle_tools.t_text_tab;

function get_md_object_type_tab
( p_what in varchar2 -- Either DBA, PUBLIC, SCHEMA or DEPENDENT
)
return t_md_object_type_tab
deterministic;

/**

Return a list of DBMS_METADATA object types.

**/

function is_dependent_object_type
( p_object_type in t_metadata_object_type
)
return t_numeric_boolean
deterministic;

end pkg_ddl_defs;
/

