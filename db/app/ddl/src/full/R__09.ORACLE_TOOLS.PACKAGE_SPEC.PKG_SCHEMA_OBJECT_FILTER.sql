CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_SCHEMA_OBJECT_FILTER" AUTHID DEFINER IS

c_debugging constant boolean := oracle_tools.pkg_ddl_util.c_debugging >= 1;

procedure construct
( p_schema in varchar2 default user
, p_object_type in varchar2 default null
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_grantor_is_schema in integer default 0
, p_objects in clob default null
, p_objects_include in integer default null
, p_schema_object_filter in out nocopy oracle_tools.t_schema_object_filter
);

procedure print
( p_schema_object_filter in oracle_tools.t_schema_object_filter
);

function matches_schema_object
( p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_metadata_object_type in varchar2
, p_object_name in varchar2
, p_metadata_base_object_type in varchar2 default null
, p_base_object_name in varchar2 default null
)
return integer
deterministic;

function matches_schema_object
( p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_schema_object_id in varchar2
)
return integer
deterministic;

function matches_schema_object
( p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_schema_object in oracle_tools.t_schema_object
)
return integer
deterministic;

$if oracle_tools.cfg_pkg.c_testing $then

-- test functions

--%suitepath(DDL)
--%suite

--%test
procedure ut_construct;

--%test
procedure ut_matches_schema_object;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

end pkg_schema_object_filter;
/

