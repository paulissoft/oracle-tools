CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."DDL_CRUD_API" AUTHID DEFINER IS /* -*-coding: utf-8-*- */

/**
Only this package is used to manage CRUD operations on:
- GENERATE_DDL_CONFIGURATIONS
- GENERATE_DDL_SESSION_BATCHES
- GENERATE_DDL_SESSION_SCHEMA_OBJECTS
- GENERATE_DDL_SESSIONS
- GENERATED_DDL_STATEMENT_CHUNKS
- GENERATED_DDL_STATEMENTS
- GENERATED_DDLS
- SCHEMA_OBJECT_FILTER_RESULTS
- SCHEMA_OBJECT_FILTERS
- SCHEMA_OBJECTS

The interface for these tables is via these views (grant select to public):
- V_DISPLAY_DDL_SQL
- V_MY_GENERATE_DDL_SESSION_BATCHES
- V_MY_INCLUDE_OBJECTS
- V_MY_NAMED_SCHEMA_OBJECTS
- V_MY_SCHEMA_DDLS
- V_MY_SCHEMA_OBJECTS
- V_MY_SCHEMA_OBJECTS_NO_DDL_YET
- V_MY_SCHEMA_OBJECT_FILTER
- V_MY_SCHEMA_OBJECT_INFO

These are helper views:
- V_SCHEMA_OBJECTS

This package will not read dictionary objects (in)directly hence **AUTHID DEFINER**.

These tables will not be granted to any other schema, so this package is the only interface: Virtual Private Database is thus not necessary.

There will be views that enable you to see the DDL data, but only for you and your sessions.

The data from the tables mentioned above will be filtered using the current session id set by set_session_id().

You can only see data:
a. from your sessions in GENERATE_DDL_SESSIONS (same USER) **OR**
b. for the current session id (to_number(sys_context('USERENV', 'SESSIONID')))

[This documentation is in PLOC format](https://github.com/ogobrecht/ploc)
**/

c_tracing constant boolean := oracle_tools.pkg_ddl_util.c_debugging >= 1;
c_debugging constant boolean := oracle_tools.pkg_ddl_util.c_debugging >= 3;

c_min_timestamp_to_keep constant timestamp(6) :=
  (sys_extract_utc(current_timestamp) - interval '2' day);

subtype t_session_id is integer;
subtype t_session_id_nn is t_session_id not null;  

subtype t_schema_object_filter_id is integer;
subtype t_schema_object_filter_id_nn is t_session_id not null;  

procedure set_session_id
( p_session_id in t_session_id_nn -- The session id.
);
/**

Set the session id that will be used for the CRUD operations.

The p_session_id parameter must be:
a. one of the SESSION_ID values from GENERATE_DDL_SESSIONS (same USER or USER is 'ORACLE_TOOLS') **OR**
b. the current session id (to_number(sys_context('USERENV', 'SESSIONID')))

**/

function get_session_id
return t_session_id_nn;
/** Get the session id that will be used for the CRUD operations. **/

function get_schema_object_filter_id
return t_schema_object_filter_id;
/**

Return the current schema object filter id.

| Table                               | CRUD |
|:------------------------------------|:-----|
| GENERATE_DDL_CONFIGURATIONS         |      |
| GENERATE_DDL_SESSION_BATCHES        |      |
| GENERATE_DDL_SESSION_SCHEMA_OBJECTS |      |
| GENERATE_DDL_SESSIONS               |      |
| GENERATED_DDL_STATEMENT_CHUNKS      |      |
| GENERATED_DDL_STATEMENTS            |      |
| GENERATED_DDLS                      |      |
| SCHEMA_OBJECT_FILTER_RESULTS        |      |
| SCHEMA_OBJECT_FILTERS               |      |
| SCHEMA_OBJECTS                      |      |

**/
function get_schema_object_filter
return oracle_tools.t_schema_object_filter;

function get_schema_object_filter
( p_schema_object_filter_id in t_schema_object_filter_id_nn
)
return oracle_tools.t_schema_object_filter;

function find_schema_object
( p_schema_object_id in varchar2 -- Find schema object in GENERATE_DDL_SESSION_SCHEMA_OBJECTS by (schema_object_filter_id, obj.id).
)
return oracle_tools.t_schema_object;
/**

Find the schema object in GENERATE_DDL_SESSION_SCHEMA_OBJECTS by obj.id.

| Table                               | CRUD |
|:------------------------------------|:-----|
| GENERATE_DDL_SESSION_SCHEMA_OBJECTS |  R   |
| SCHEMA_OBJECT_FILTER_RESULTS        |  R   |
| SCHEMA_OBJECTS                      |  R   |

**/

procedure default_match_perc_threshold
( p_match_perc_threshold in integer -- The new match percentage threshold.
);
/** Set the new default match percentage threshold. The original default is 50 percent. **/

function match_perc
return integer
deterministic;
/**
Return the match percentage for the current session id: the percentage of objects to generate DDL for.

Calculated as the sum of V_SCHEMA_OBJECTS.GENERATE_DDL (0 or 1) for the current session id divided by the total count of objects.
**/

function match_perc_threshold
return integer
deterministic;
/** Return the match percentage threshold as set by default_match_perc_threshold(). **/

procedure add
( p_schema in varchar2 -- The schema name.
, p_object_type in varchar2 -- Filter for object type.
, p_object_names in varchar2 -- A comma separated list of (base) object names.
, p_object_names_include in integer -- How to treat the object name list: include (1), exclude (0) or don't care (null)?
, p_grantor_is_schema in integer -- An extra filter for grants. If the value is 1, only grants with grantor equal to p_schema will be chosen.
, p_exclude_objects in clob -- A newline separated list of objects to exclude (their schema object id actually).
, p_include_objects in clob -- A newline separated list of objects to include (their schema object id actually).
, p_transform_param_list in varchar2 -- A comma separated list of transform parameters, see dbms_metadata.set_transform_param().
, p_schema_object_filter out nocopy oracle_tools.t_schema_object_filter -- The schema object filter.
, p_generate_ddl_configuration_id out nocopy integer -- The GENERATE_DDL_CONFIGURATIONS.ID.
);
/**
This procedure will:
1. create a schema object filter (type T_SCHEMA_OBJECT_FILTER)
2. normalize p_transform_param_list (uppercase, no duplicates, ordered and separated by commas) and
   add that normalized transform parameter list plus database version and last ddl time of DDL related objects of this schema (ORACLE_TOOLS)
   to GENERATE_DDL_CONFIGURATIONS

The idea for the last step is that DDL generation depends on:
a. the DBMS_METADATA transformation parameters
b. the database version
c. the version of the (most) important DDL related objects (now just package specifications and their bodies)

Each such combination is stored as a generate DDL configuration.

| Table                               | CRUD |
|:------------------------------------|:-----|
| GENERATE_DDL_CONFIGURATIONS         | CR D |

**/

procedure add
( p_schema_object_filter in oracle_tools.t_schema_object_filter -- The schema object filter.
, p_generate_ddl_configuration_id in integer -- The GENERATE_DDL_CONFIGURATIONS.ID.
, p_schema_object_filter_id out nocopy integer -- The schema object filter id. 
);
/**
This procedure will:
1. Determine the hash bucket based on the serialized schema object filter (sys.dbms_crypto.hash("serialized schema object filter", sys.dbms_crypto.hash_sh1))
2. Compare the serialized schema object filter against the schema object filters in SCHEMA_OBJECT_FILTERS having the same hash bucket 
3. Get the maximum hash bucket number plus 1 (the new number) for the same hash bucket
4. Get the last modification time of the schema (the maximum ALL_OBJECTS.LAST_DDL_TIME for the schema of the schema object filter)

Now when there was **no** record in SCHEMA_OBJECT_FILTERS with the
same hash bucket there will be an insert into
SCHEMA_OBJECT_FILTERS.

Otherwise (there is a record in SCHEMA_OBJECT_FILTERS) when the
previous last modification time is not the same as the value calculated in
step 4, all entries in SCHEMA_OBJECT_FILTER_RESULTS for this
schema object filter id will be removed. That is necessary since we must
recalculate p_schema_object_filter.matches_schema_object() for every object
since the schema is not the same anymore hence the results not reliable
anymore. The LAST_MODIFICATION_TIME_SCHEMA and UPDATED columns will be
updated in any case.

| Table                               | CRUD |
|:------------------------------------|:-----|
| GENERATE_DDL_SESSION_SCHEMA_OBJECTS |    D |
| GENERATE_DDL_SESSIONS               | CRUD |
| SCHEMA_OBJECT_FILTER_RESULTS        |    D |
| SCHEMA_OBJECT_FILTERS               | CRU  |

**/

procedure add
( p_schema_object in oracle_tools.t_schema_object -- The schema object to add to GENERATE_DDL_SESSION_SCHEMA_OBJECTS.
, p_schema_object_filter_id in t_schema_object_filter_id_nn
, p_schema_object_filter in oracle_tools.t_schema_object_filter
);
/**
Add a schema object to SCHEMA_OBJECTS for the current session id and update
GENERATE_DDL_SESSION_SCHEMA_OBJECTS when DDL must be generated.

Steps:
1. get the schema object filter id from GENERATE_DDL_SESSIONS for the current session id
2. raise PROGRAM_ERROR if not found
3. if not found: INSERT INTO SCHEMA_OBJECTS(ID, OBJ) VALUES (p_schema_object.id, p_schema_object)
4. if no schema object filter reuslt is found: insert into SCHEMA_OBJECT_FILTER_RESULTS
5. now when DDL must be generated (SCHEMA_OBJECT_FILTER_RESULTS.GENERATE_DDL = 1),
   update GENERATE_DDL_SESSION_SCHEMA_OBJECTS and set LAST_DDL_TIME and GENERATE_DDL_CONFIGURATION_ID
   from information from GENERATE_DDL_SESSIONS and GENERATED_DDLS
   (given the last ddl time from this schema object)

This last step is an efficiency step: when DDL has been generated before with the same
generate DDL configurayion, there is no need to do it again.

| Table                               | CRUD |
|:------------------------------------|:-----|
| GENERATE_DDL_SESSION_SCHEMA_OBJECTS |   U  |
| GENERATE_DDL_SESSIONS               |  R   |
| GENERATED_DDLS                      |  R   |
| SCHEMA_OBJECT_FILTER_RESULTS        | CR   |
| SCHEMA_OBJECT_FILTERS               |  R   |
| SCHEMA_OBJECTS                      | CR   |

**/

procedure add
( p_schema_ddl in oracle_tools.t_schema_ddl -- The schema DDL.
);
/**
Add schema DDL for the current session id.

Steps:
1. get the generate DDL configuration id from GENERATE_DDL_SESSIONS
2. determine whether there has already DDL generated for the combination of schema object id, schema object last ddl time and generate DDL configuration id
3. if not, add a record to GENERATED_DDLS with this info and save the generated DDL id
4. for each DDL statement (p_schema_ddl.ddl_tab)
   INSERT INTO GENERATED_DDL_STATEMENTS and
   for each chunk in the DDL statement
   INSERT INTO GENERATED_DDL_STATEMENT_CHUNKS
5. flag that DDL has been generated for this schema object:
   update GENERATE_DDL_SESSION_SCHEMA_OBJECTS and set LAST_DDL_TIME and GENERATE_DDL_CONFIGURATION_ID

| Table                               | CRUD |
|:------------------------------------|:-----|
| GENERATE_DDL_SESSION_SCHEMA_OBJECTS |   U  |
| GENERATE_DDL_SESSIONS               |  R   |
| GENERATED_DDL_STATEMENT_CHUNKS      | C    |
| GENERATED_DDL_STATEMENTS            | C    |
| GENERATED_DDLS                      | CR D |

**/

procedure add
( p_schema_ddl_tab in oracle_tools.t_schema_ddl_tab -- The schema DDL table.
);
/** Invoke ADD(p_schema_ddl) for each entry. **/

procedure add
( p_schema in varchar2 -- The schema.
, p_transform_param_list in varchar2 -- The DBMS_METADATA transformation parameter list separated by commas.
, p_object_schema in varchar2 -- The object schema.
, p_object_type in varchar2 -- The object type.
, p_base_object_schema in varchar2 -- The base object schema.
, p_base_object_type in varchar2 -- The base object type.
, p_object_name_tab in oracle_tools.t_text_tab -- The table of object names.
, p_base_object_name_tab in oracle_tools.t_text_tab -- The table of base object names.
, p_nr_objects in integer -- The number of objects.
);
/**

Add a record to table GENERATE_DDL_SESSION_BATCHES.

| Table                               | CRUD |
|:------------------------------------|:-----|
| GENERATE_DDL_SESSION_BATCHES        | C    |

**/

procedure add
( p_object_type in varchar2
);
/**

Add a record to table GENERATE_DDL_SESSION_BATCHES.

| Table                               | CRUD |
|:------------------------------------|:-----|
| GENERATE_DDL_SESSION_BATCHES        | C    |

**/

procedure add
( p_schema_object_tab in oracle_tools.t_schema_object_tab -- The schema object table.
, p_schema_object_filter_id in t_schema_object_filter_id_nn -- The schema object filter id.
, p_schema_object_filter in oracle_tools.t_schema_object_filter
);
/**

Insert (if not already there) into:
1. SCHEMA_OBJECTS
2. SCHEMA_OBJECT_FILTER_RESULTS
3. GENERATE_DDL_SESSION_SCHEMA_OBJECTS

| Table                               | CRUD |
|:------------------------------------|:-----|
| GENERATE_DDL_SESSION_SCHEMA_OBJECTS | CR   |
| GENERATE_DDL_SESSIONS               |  R   |
| GENERATED_DDLS                      |  R   |
| SCHEMA_OBJECT_FILTER_RESULTS        | CR   |
| SCHEMA_OBJECT_FILTERS               |  R   |
| SCHEMA_OBJECTS                      | CR   |

**/

procedure clear_batch;
/**

Remove all records from GENERATE_DDL_SESSION_BATCHES.START_TIME for the current session id.

| Table                               | CRUD |
|:------------------------------------|:-----|
| GENERATE_DDL_SESSION_BATCHES        |    D |

**/

procedure set_batch_start_time
( p_seq in integer -- The sequence within the current session batch.
);
/**

Set the GENERATE_DDL_SESSION_BATCHES.START_TIME for the current session id and seq.

| Table                               | CRUD |
|:------------------------------------|:-----|
| GENERATE_DDL_SESSION_BATCHES        |   U  |

**/

procedure set_batch_end_time
( p_seq in integer -- The sequence within the current session batch.
, p_error_message in varchar2 default null -- The error message (if any).
);
/**

Set the GENERATE_DDL_SESSION_BATCHES.END_TIME for the current session id and seq.

| Table                               | CRUD |
|:------------------------------------|:-----|
| GENERATE_DDL_SESSION_BATCHES        |   U  |

**/

procedure clear_all_ddl_tables;
/**
Clear all DDL tables.

Steps:
1. delete from generate_ddl_configurations
2. delete from schema_objects
3. delete from schema_object_filters

And thus all related tables thanks to the cascading foreign keys.

| Table                               | CRUD |
|:------------------------------------|:-----|
| GENERATE_DDL_CONFIGURATIONS         |    D |
| SCHEMA_OBJECT_FILTERS               |    D |
| SCHEMA_OBJECTS                      |    D |

**/

procedure fetch_schema_objects
( p_session_id in t_session_id_nn
, p_cursor in out nocopy sys_refcursor
, p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
);

type t_display_ddl_sql_rec is record
( schema_object_id oracle_tools.generated_ddls.schema_object_id%type
, ddl# oracle_tools.generated_ddl_statements.ddl#%type
, verb oracle_tools.generated_ddl_statements.verb%type
, ddl_info varchar2(1000 byte)
, chunk# oracle_tools.generated_ddl_statement_chunks.chunk#%type
, chunk oracle_tools.generated_ddl_statement_chunks.chunk%type
, last_chunk number(1, 0)
, schema_object oracle_tools.t_schema_object
);

type t_display_ddl_sql_tab is table of t_display_ddl_sql_rec;

type t_display_ddl_sql_cur is ref cursor return t_display_ddl_sql_rec;

procedure fetch_display_ddl_sql
( p_session_id in t_session_id_nn -- The session id from V_MY_GENERATE_DDL_SESSIONS, i.e. must belong to your USERNAME.
, p_cursor in out nocopy t_display_ddl_sql_cur
, p_display_ddl_sql_tab out nocopy t_display_ddl_sql_tab
);

procedure set_ddl_output_written
( p_schema_object_id in varchar2 -- may be null, meaning all in this session
, p_ddl_output_written in integer -- either null or 1
);
/** Set GENERATE_DDL_SESSION_SCHEMA_OBJECTS.DDL_OUTPUT_WRITTEN in the current session for every schema object matching the id. **/

type t_ddl_generate_report_rec is record
( -- from GENERATE_DDL_CONFIGURATIONS
  transform_param_list varchar2(4000 byte)
, db_version number
, last_ddl_time_schema date
  -- from SCHEMA_OBJECTS
, schema_object oracle_tools.t_schema_object
  -- from SCHEMA_OBJECT_FILTER_RESULTS
, generate_ddl number(1, 0) -- result of procedure PKG_SCHEMA_OBJECT_FILTER.MATCHES_SCHEMA_OBJECT()
  -- from GENERATE_DDL_SESSION_SCHEMA_OBJECTS
, ddl_generated number(1, 0) -- see v_schema_objects.ddl_generated
, ddl_output_written number(1, 0)
);

type t_ddl_generate_report_tab is table of t_ddl_generate_report_rec;

type t_ddl_generate_report_cur is ref cursor return t_ddl_generate_report_rec;

procedure fetch_ddl_generate_report
( p_session_id in t_session_id_nn -- The session id from V_MY_GENERATE_DDL_SESSIONS, i.e. must belong to your USERNAME.
, p_cursor in out nocopy t_ddl_generate_report_cur
, p_ddl_generate_report_tab out nocopy t_ddl_generate_report_tab
);

procedure delete_generate_ddl_sessions
( p_session_id in t_session_id default null -- The session id to delete (or sessions longer than 2 days ago).
);
/** Delete rows from GENERATE_DDL_SESSIONS. **/

END DDL_CRUD_API;
/

