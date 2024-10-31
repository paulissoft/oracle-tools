CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."ALL_SCHEMA_OBJECTS_API" AUTHID DEFINER IS /* -*-coding: utf-8-*- */

type t_schema_object_cursor is ref cursor;
   
procedure set_session_id
( p_session_id in all_schema_objects.session_id%type default to_number(sys_context('USERENV', 'SESSIONID')) -- The session id
);
/** Set the session id as a package global variable. **/

function get_session_id
return all_schema_objects.session_id%type;
/** Get the session id (the package global variable). **/

procedure add
( p_schema_object in t_schema_object -- The schema object to add to ALL_SCHEMA_OBJECTS (session id equals p_session_id)
, p_must_exist in boolean default null -- p_must_exist: TRUE - must exist (UPDATE); FALSE - must NOT exist (INSERT); NULL - don't care (UPSERT)
, p_session_id in all_schema_objects.session_id%type default get_session_id -- The session id
, p_generate_ddl in all_schema_objects.generate_ddl%type default null -- The generate DDL flag
);
/** Add a schema object to ALL_SCHEMA_OBJECTS, meaning INSERT, UPDATE OR UPSERT. */

procedure add
( p_schema_object_cursor in t_schema_object_cursor -- The schema objects to add to ALL_SCHEMA_OBJECTS (session id equals p_session_id)
, p_must_exist in boolean default null -- p_must_exist: TRUE - must exist (UPDATE); FALSE - must NOT exist (INSERT); NULL - don't care (UPSERT)
, p_session_id in all_schema_objects.session_id%type default get_session_id -- The session id
, p_generate_ddl in all_schema_objects.generate_ddl%type default null -- The generate DDL flag
);
/** Add schema objects to ALL_SCHEMA_OBJECTS, meaning INSERT, UPDATE OR UPSERT. */

function find_by_seq
( p_seq in all_schema_objects.seq%type default 1 -- Find schema object in ALL_SCHEMA_OBJECTS by (p_session_id, seq)
, p_session_id in all_schema_objects.session_id%type default get_session_id -- The session id
)
return all_schema_objects%rowtype;
/** Find the schema object in ALL_SCHEMA_OBJECTS by seq. **/

function find_by_object_id
( p_id in varchar2 -- Find schema object in ALL_SCHEMA_OBJECTS by (p_session_id, obj.id())
, p_session_id in all_schema_objects.session_id%type default get_session_id -- The session id
)
return all_schema_objects%rowtype;
/** Find the schema object in ALL_SCHEMA_OBJECTS by obj.id(). **/

function ignore_object(p_obj in oracle_tools.t_schema_object)
return integer;

function get_schema_objects
return varchar2 sql_macro;
/**

Get all rows from ALL_SCHEMA_OBJECTS with session_id equal to get_session_id() and ordered by SEQ.

Usage: select * from all_schema_objects_api.get_schema_objects()

**/

END ALL_SCHEMA_OBJECTS_API;
/

