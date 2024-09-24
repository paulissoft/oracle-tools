CREATE OR REPLACE PACKAGE "ADMIN_RECOMPILE_PKG" AUTHID DEFINER AS 

/**
This package is a wrapper around SYS.UTL_RECOMP for recompiling invalid objects with the following added functionality:
- DBA users can use it like UTL_RECOMP (you are a DBA when sys_context('USERENV', 'ISDBA') equals 'TRUE' or sys_context('USERENV', 'SESSION_USER') equals $$PLSQL_UNIT_OWNER)
- normal users can only compile their own schema (the user name is sys_context('USERENV', 'SESSION_USER'))
**/

type invalid_object_rec_t is record
( owner all_objects.owner%type
, object_name all_objects.object_name%type
, object_type all_objects.object_type%type
, status all_objects.status%type
);

type invalid_object_tab_t is table of invalid_object_rec_t;

function show
( p_schema_tab in sys.odcivarchar2list default sys.odcivarchar2list(null) -- The schemas for which to show invalid objects. If NULL, all schemas with invalid objects will be shown when you are a DBA, otherwise just the invalid objects from your schema.
)
return invalid_object_tab_t
pipelined;
/**
Show invalid objects (status <> 'VALID') sorted by owner, object_name, object_type.
**/

procedure recomp_parallel
( p_threads in pls_integer default null -- The number of recompile threads to run in parallel. If NULL, use the value of 'job_queue_processes'.
, p_schema in varchar2 default null -- The schema in which to recompile invalid objects. If NULL, all invalid objects in the database are recompiled when you are a DBA, otherwise just your schema.
);

/**
A wrapper around UTL_RECOMP.RECOMP_PARALLEL.

Uses DBMS_OUTPUT to display the invocation and the invalid objects thereafter.
**/

procedure recomp_serial
( p_schema in varchar2 default null -- The schema in which to recompile invalid objects. If NULL, all invalid objects in the database are recompiled when you are a DBA, otherwise just your schema.
, p_exclude_oracle_maintained in boolean default true -- exclude all users whose ALL_USERS.ORACLE_MAINTAINED column equals Y
);

/**
A wrapper around UTL_RECOMP.RECOMP_SERIAL but may run that in a loop due to p_exclude_oracle_maintained.

Uses DBMS_OUTPUT to display the invocation(s) for all schemas matching the input parameters and the invalid objects thereafter.
**/

END ADMIN_RECOMPILE_PKG;
/
