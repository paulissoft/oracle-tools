CREATE OR REPLACE PACKAGE "DATA_API_PKG" authid current_user is

/**
Definitions regarding data objects:
- exception handling
- job status
- dbms_assert assertions with context

This package has AUTHID CURRENT_USER so that it can be used by 
the schemas <system>_DATA and <system>_API in their packages.
**/

-- used as separator between error code and arguments
"#" constant varchar2(1) := '#';

c_exception constant pls_integer := -20001;
e_exception exception;

pragma exception_init(e_exception, -20001);

c_check_constraint constant pls_integer := -2290; -- check constraint violated
e_check_constraint exception;

pragma exception_init(e_check_constraint, -2290);

c_unique_constraint constant pls_integer := -1; -- unique constraint violated
e_unique_constraint exception;

pragma exception_init(e_unique_constraint, -1);

-- create or replace TRIGGER FKNTM_BNS_TPL_OBJECTIVE_PLAN_D BEFORE
--  UPDATE OF TON_ID, OJE_ID ON BNS_TPL_OBJECTIVE_PLAN_DETAILS
-- BEGIN
--   RAISE_APPLICATION_ERROR(-20225, 'Non Transferable FK constraint  on table BNS_TPL_OBJECTIVE_PLAN_DETAILS is violated');
-- END;
c_fk_non_transferable constant pls_integer := -20225;
e_fk_non_transferable exception;

pragma exception_init(e_fk_non_transferable, -20225);

c_cannot_update_to_null constant pls_integer := -1407;
e_cannot_update_to_null exception;

pragma exception_init(e_cannot_update_to_null, -1407);

type t_job_status_rec is record
( job_name all_scheduler_job_run_details.job_name%type
, status all_scheduler_job_run_details.status%type
, actual_start_date all_scheduler_job_run_details.actual_start_date%type
, errors all_scheduler_job_run_details.errors%type
);

type t_job_status_tab is table of t_job_status_rec;

function get_owner
return all_objects.owner%type; -- The package owner
/** Get the owner of this package. **/

procedure raise_error
( p_error_code in varchar2 -- For instance a business rule
, p_p1 in varchar2 default null -- Parameter 1
, p_p2 in varchar2 default null
, p_p3 in varchar2 default null
, p_p4 in varchar2 default null
, p_p5 in varchar2 default null
, p_p6 in varchar2 default null
, p_p7 in varchar2 default null
, p_p8 in varchar2 default null
, p_p9 in varchar2 default null
);
/** Raise a generic application error. **/

procedure raise_error_overlap
( p_error_code in varchar2 -- For instance a business rule
, p_lwb1 in varchar2 -- Lower bound interval 1
, p_upb1 in varchar2 -- Upper bound interval 1
, p_lwb2 in varchar2 -- Lower bound interval 2
, p_upb2 in varchar2 -- Upper bound interval 2
, p_lwb_incl boolean default true -- Is the lower bound inclusive yes or no. Yes is shown as [ and no as (.
, p_upb_incl boolean default true -- Is the upper bound inclusive yes or no. Yes is shown as ] and no as ).
, p_key1 in varchar2 default null -- Part 1 of the key
, p_key2 in varchar2 default null -- Part 2 of the key
, p_key3 in varchar2 default null -- Part 3 of the key
);
/**
Raise an application error concerning overlap.
An exception with error message like #<p_error_code>#<interval of p_lwb1 and p_upb1>#<interval of p_lwb2 and p_upb2> will be raised.
**/

function show_job_status
( p_job_name in all_scheduler_job_run_details.job_name%type -- The job name
, p_start_date_min in all_scheduler_job_run_details.actual_start_date%type default null -- The start date
)
return t_job_status_tab -- A collection of ALL_SCHEDULER_JOB_RUN_DETAILS info for the job started at least the START DATE
pipelined;
/** Show the job status. **/

function dbms_assert$enquote_name
( p_str in varchar2
, p_what in varchar2 -- the kind of object: used in error message
, p_capitalize in boolean default true
)
return varchar2;
/** Same as dbms_assert.enquote_name but with a more informational error message. **/

function dbms_assert$qualified_sql_name
( p_str in varchar2
, p_what in varchar2 -- the kind of object: used in error message
)
return varchar2;
/** Same as dbms_assert.qualified_sql_name but with a more informational error message. **/

function dbms_assert$schema_name
( p_str in varchar2
, p_what in varchar2 -- the kind of object: used in error message
)
return varchar2;
/** Same as dbms_assert.schema_name but with a more informational error message. **/

function dbms_assert$simple_sql_name
( p_str in varchar2
, p_what in varchar2 -- the kind of object: used in error message
)
return varchar2;
/** Same as dbms_assert.simple_sql_name but with a more informational error message. **/

function dbms_assert$sql_object_name
( p_str in varchar2
, p_what in varchar2 -- the kind of object: used in error message
)
return varchar2;
/** Same as dbms_assert.sql_object_name but with a more informational error message. **/

function get_object_name
( p_object_name in varchar2 -- the object name part
, p_what in varchar2 -- the kind of object: used in error message
, p_schema_name in varchar2 default null -- the schema part name
, p_fq in integer default 1 -- return fully qualified name, yes (1) or no (0)
, p_qq in integer default 1 -- return double quoted name, yes (1) or no (0)
, p_uc in integer default 1 -- return name in upper case, yes (1) or no (0)
)
return varchar2;
/**
A function to return the object name in some kind of format.
When p_what equals 'queue', 'subscriber' or 'agent', NO dbms_assert.sql_object_name() will be invoked for the resulting object name.
**/

$if cfg_pkg.c_testing $then

--%suitepath(DATA)
--%suite

--%test
procedure ut_raise_error;

$end

end data_api_pkg;
/

