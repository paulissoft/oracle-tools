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

This package will **NOT** read dictionary objects hence **AUTHID DEFINER** is sufficient.

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

subtype t_session_id is integer;  

procedure set_session_id
( p_session_id in t_session_id
);
/**

Set the session id that will be used for the CRUD operations.

The p_session_id parameter must be:
a. on of the SESSION_ID values from GENERATE_DDL_SESSIONS (same USER) **OR**
b. the current session id (to_number(sys_context('USERENV', 'SESSIONID')))

**/

function get_session_id
return t_session_id;
/** Get the session id that will be used for the CRUD operations. **/

function find_schema_object
( p_schema_object_id in varchar2 -- Find schema object in GENERATE_DDL_SESSION_SCHEMA_OBJECTS by (schema_object_filter_id, obj.id)
)
return oracle_tools.t_schema_object;
/** Find the schema object in GENERATE_DDL_SESSION_SCHEMA_OBJECTS by obj.id. **/

procedure default_match_perc_threshold
( p_match_perc_threshold in integer -- The new match percentage threshold.
);
/** Set the new default match percentage threshold. The original default is 50 percent. **/

function match_perc
return integer
deterministic;
/**
Return the match percentage for the current session id: the percentage of objects to generate DDL for.

Calculated as the sum of V_ALL_SCHEMA_OBJECTS.GENERATE_DDL (0 or 1) for the current session id divided by the total count of objects.
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
, p_schema_object_filter out nocopy oracle_tools.t_schema_object_filter -- the schema object filter
, p_generate_ddl_configuration_id out nocopy integer -- the GENERATE_DDL_CONFIGURATIONS.ID
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

**/

procedure add
( p_schema_object_filter in oracle_tools.t_schema_object_filter -- the schema object filter
, p_generate_ddl_configuration_id in integer -- the GENERATE_DDL_CONFIGURATIONS.ID
, p_schema_object_filter_id out nocopy integer
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
**/

procedure add
( p_schema_object in oracle_tools.t_schema_object -- The schema object to add to GENERATE_DDL_SESSION_SCHEMA_OBJECTS
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
**/

procedure add
( p_schema_ddl in oracle_tools.t_schema_ddl
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
**/

procedure add
( p_schema_ddl_tab in oracle_tools.t_schema_ddl_tab
);
/** Invoke add(p_schema_ddl) for each entry. **/

procedure add
( p_schema in varchar2
, p_transform_param_list in varchar2
, p_object_schema in varchar2
, p_object_type in varchar2
, p_base_object_schema in varchar2
, p_base_object_type in varchar2
, p_object_name_tab in oracle_tools.t_text_tab
, p_base_object_name_tab in oracle_tools.t_text_tab
, p_nr_objects in integer
);
/** Update the record in table GENERATE_DDL_SESSION_BATCHES. **/

procedure add
( p_schema_object_tab in oracle_tools.t_schema_object_tab
, p_schema_object_filter_id in positiven
);
/**
Insert (if not already there) into:
1. SCHEMA_OBJECTS
2. SCHEMA_OBJECT_FILTER_RESULTS
3. GENERATE_DDL_SESSION_SCHEMA_OBJECTS
**/

procedure set_batch_start_time
( p_seq in integer
);
/** Set the GENERATE_DDL_SESSION_BATCHES.START_TIME for the current session id and seq. **/

procedure set_batch_end_time
( p_seq in integer
);
/** Set the GENERATE_DDL_SESSION_BATCHES.END_TIME for the current session id and seq. **/

END DDL_CRUD_API;
/
