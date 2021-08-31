CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_SCHEMA_OBJECT" AUTHID CURRENT_USER IS

procedure create_schema_object
( p_owner in varchar2 -- GJP 2021-08-31 Necessary in case of a remap
, p_object_schema in varchar2
, p_object_type in varchar2
, p_object_name in varchar2 default null
, p_base_object_schema in varchar2 default null
, p_base_object_type in varchar2 default null
, p_base_object_name in varchar2 default null
, p_column_name in varchar2 default null
, p_grantee in varchar2 default null
, p_privilege in varchar2 default null
, p_grantable in varchar2 default null
, p_schema_object out nocopy t_schema_object
);

function create_schema_object
( p_owner in varchar2
, p_object_schema in varchar2
, p_object_type in varchar2
, p_object_name in varchar2 default null
, p_base_object_schema in varchar2 default null
, p_base_object_type in varchar2 default null
, p_base_object_name in varchar2 default null
, p_column_name in varchar2 default null
, p_grantee in varchar2 default null
, p_privilege in varchar2 default null
, p_grantable in varchar2 default null
)
return t_schema_object;

procedure create_named_object
( p_owner in varchar2 -- GJP 2021-08-31 Necessary in case of a remap
, p_object_type in varchar2
, p_object_schema in varchar2
, p_object_name in varchar2
, p_named_object out nocopy t_schema_object
);

function create_named_object
( p_owner in varchar2
, p_object_type in varchar2
, p_object_schema in varchar2
, p_object_name in varchar2
)
return t_named_object;

procedure create_constraint_object
( p_owner in varchar2
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_constraint_type in varchar2 default null
, p_column_names in varchar2 default null
, p_search_condition in varchar2 default null
, p_obj out nocopy t_constraint_object
);

function create_constraint_object
( p_owner in varchar2
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_constraint_type in varchar2 default null
, p_column_names in varchar2 default null
, p_search_condition in varchar2 default null
)
return t_constraint_object;

function create_index_object
( p_owner in varchar2
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_tablespace_name in varchar2 default null
)
return t_index_object;

function create_procobj_object
( p_owner in varchar2
, p_object_schema in varchar2
, p_object_name in varchar2
)
return t_procobj_object;

procedure create_ref_constraint_object
( p_owner in varchar2
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_constraint_type in varchar2 default null
, p_column_names in varchar2 default null
, p_ref_object in t_named_object default null
, p_obj out nocopy t_ref_constraint_object
);

function create_ref_constraint_object
( p_owner in varchar2
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_constraint_type in varchar2 default null
, p_column_names in varchar2 default null
, p_ref_object in t_named_object default null
)
return t_ref_constraint_object;

function create_table_object
( p_owner in varchar2
, p_object_schema in varchar2
, p_object_name in varchar2
, p_tablespace_name in varchar2 default null
)
return t_table_object;

function get_column_names
( p_owner in varchar2
, p_constraint_name in varchar2
, p_table_name in varchar2
)
return varchar2;

function get_column_names
( p_owner in varchar2
, p_index_name in varchar2
)
return varchar2;

end pkg_schema_object;
/

