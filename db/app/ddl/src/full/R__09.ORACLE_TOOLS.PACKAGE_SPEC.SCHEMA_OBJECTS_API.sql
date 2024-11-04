CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."SCHEMA_OBJECTS_API" AUTHID DEFINER IS /* -*-coding: utf-8-*- */

type t_schema_object_rec is record
( obj oracle_tools.t_schema_object
);

type t_schema_object_cursor is ref cursor return t_schema_object_rec;
   
procedure ins
( p_obj in oracle_tools.schema_object_filters.obj%type
, p_id out nocopy oracle_tools.schema_object_filters.id%type
);
/** Add a record to table schema_object_filters. **/

procedure add
( p_schema_object in oracle_tools.all_schema_objects.obj%type -- The schema object to add to ALL_SCHEMA_OBJECTS
, p_must_exist in boolean default null -- p_must_exist: TRUE - must exist (UPDATE); FALSE - must NOT exist (INSERT); NULL - don't care (UPSERT)
, p_schema_object_filter_id in oracle_tools.all_schema_objects.schema_object_filter_id%type default null -- If null, the last from schema_object_filters for this session is used
);
/** Add a schema object to ALL_SCHEMA_OBJECTS, meaning INSERT, UPDATE OR UPSERT. */

procedure add
( p_schema_object_cursor in t_schema_object_cursor -- The schema objects to add to ALL_SCHEMA_OBJECTS
, p_must_exist in boolean default null -- p_must_exist: TRUE - must exist (UPDATE); FALSE - must NOT exist (INSERT); NULL - don't care (UPSERT)
, p_schema_object_filter_id in oracle_tools.all_schema_objects.schema_object_filter_id%type default null -- If null, the last from schema_object_filters for this session is used
);
/** Add schema objects to ALL_SCHEMA_OBJECTS, meaning INSERT, UPDATE OR UPSERT. */

function find_by_seq
( p_seq in all_schema_objects.seq%type default 1 -- Find schema object in ALL_SCHEMA_OBJECTS by (schema_object_filter_id, seq)
, p_schema_object_filter_id in oracle_tools.all_schema_objects.schema_object_filter_id%type default null -- If null, the last from schema_object_filters for this session is used
)
return all_schema_objects%rowtype;
/** Find the schema object in ALL_SCHEMA_OBJECTS by seq. **/

function find_by_object_id
( p_id in varchar2 -- Find schema object in ALL_SCHEMA_OBJECTS by (schema_object_filter_id, obj.id())
, p_schema_object_filter_id in oracle_tools.all_schema_objects.schema_object_filter_id%type default null -- If null, the last from schema_object_filters for this session is used
)
return all_schema_objects%rowtype;
/** Find the schema object in ALL_SCHEMA_OBJECTS by obj.id(). **/

function get_schema_objects
( p_schema in varchar2 default user
, p_object_type in varchar2 default null
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_grantor_is_schema in integer default 0
, p_exclude_objects in clob default null
, p_include_objects in clob default null
)
return oracle_tools.t_schema_object_tab
pipelined;

function get_schema_objects
( p_schema_object_filter_id in number -- If null, the last from schema_object_filters for this session is used
)
return varchar2 sql_macro;
/**

Get all rows from ALL_SCHEMA_OBJECTS with schema_object_filter_id equal to p_schema_object_filter_id (if not null) or the last for this session (if null).

Usage: select * from schema_objects_api.get_schema_objects(null)

**/

function match_perc
return integer
deterministic;
/*
is
begin
  return
    case
      when match_count$ > 0
      then trunc((100 * match_count_ok$) / match_count$)
      else null
    end;
end;
*/

function match_perc_threshold
return integer
deterministic;
/*
is
begin
  return match_perc_threshold$;
end match_perc_threshold;
*/

procedure match_perc_threshold
( self in out nocopy oracle_tools.t_schema_object_filter 
, p_match_perc_threshold in integer
);
/*
is
begin
  self.match_perc_threshold$ := p_match_perc_threshold;
end match_perc_threshold;
*/

$if oracle_tools.cfg_pkg.c_testing $then

-- test functions

--%suitepath(DDL)
--%suite

--%test
procedure ut_get_schema_objects;

--%test
procedure ut_get_schema_object_filter;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

END SCHEMA_OBJECTS_API;
/

