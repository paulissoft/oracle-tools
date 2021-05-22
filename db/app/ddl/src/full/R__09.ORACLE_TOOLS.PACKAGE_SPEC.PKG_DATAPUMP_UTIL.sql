CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_DATAPUMP_UTIL" authid current_user is

function get_schema_export_directory
return all_directories.directory_name%type deterministic;

function get_schema_export_file
( p_schema in varchar2 default user
, p_content in varchar2 default 'METADATA_ONLY' -- CONTENT={ALL | DATA_ONLY | METADATA_ONLY}
, p_remote_link in varchar2 default null
)
return varchar2 deterministic;

function get_schema_sql_file
( p_schema in varchar2 default user
, p_content in varchar2 default 'METADATA_ONLY' -- CONTENT={ALL | DATA_ONLY | METADATA_ONLY}
, p_remote_link in varchar2 default null
)
return varchar2 deterministic;

-- create a datapump export file on the server
procedure create_schema_export_file
( p_schema in varchar2 default user
, p_content in varchar2 default 'METADATA_ONLY' -- CONTENT={ALL | DATA_ONLY | METADATA_ONLY}
, p_remote_link in varchar2 default null
);

procedure get_schema_export_file_info
( p_schema_export_file in varchar2
, p_creation_date out nocopy varchar2
, p_job_name out nocopy varchar2
);

-- sql file with maybe some filtering / transforming
-- create_schema_export_file() will be called if necessary
procedure create_schema_sql_file
( p_schema in varchar2 default user
, p_content in varchar2 default 'METADATA_ONLY' -- CONTENT={ALL | DATA_ONLY | METADATA_ONLY}
, p_new_schema in varchar2 default null
, p_object_type in varchar2 default null
, p_object_name_expr in varchar2 default null
, p_remote_link in varchar2 default null
, p_sql_file out nocopy bfile
);

function bfile2clob
( p_bfile in out nocopy bfile
)
return clob;

end pkg_datapump_util;
/

