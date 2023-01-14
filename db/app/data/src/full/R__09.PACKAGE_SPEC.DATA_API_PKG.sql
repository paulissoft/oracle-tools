CREATE OR REPLACE PACKAGE "DATA_API_PKG" authid current_user is

/**
 * This package has AUTHID CURRENT_USER so that it can be used by 
 * the schemas <system>_DATA and <system>_API in their packages.
 */

-- GJP 2020-11-30  Use cfg_pkg.c_debugging instead
-- -- for conditional compiling
-- c_debugging constant pls_integer default 0;

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

/**
 * Get the owner of this package.
 *
 * @return  The package owner
 */
function get_owner
return all_objects.owner%type;

/**
 * Raise a generic application error.
 *
 * @param p_error_code  For instance a business rule
 * @param p_p1          Parameter 1
 * @param p_p2          Parameter 2
 * @param p_p3          Parameter 3
 * @param p_p4          Parameter 4
 * @param p_p5          Parameter 5
 * @param p_p6          Parameter 6
 * @param p_p7          Parameter 7
 * @param p_p8          Parameter 8
 * @param p_p9          Parameter 9
 */
procedure raise_error
( p_error_code in varchar2
, p_p1 in varchar2 default null
, p_p2 in varchar2 default null
, p_p3 in varchar2 default null
, p_p4 in varchar2 default null
, p_p5 in varchar2 default null
, p_p6 in varchar2 default null
, p_p7 in varchar2 default null
, p_p8 in varchar2 default null
, p_p9 in varchar2 default null
);

/**
 * Raise an application error concerning overlap.
 *
 * An exception with error message like #<p_error_code>#<interval of p_lwb1 and p_upb1>#<interval of p_lwb2 and p_upb2> will be raised.
 *
 * @param p_error_code  For instance a business rule
 * @param p_lwb1        Lower bound interval 1
 * @param p_upb1        Upper bound interval 1
 * @param p_lwb2        Lower bound interval 2
 * @param p_upb2        Upper bound interval 2
 * @param p_lwb_incl    Is the lower bound inclusive yes or no. Yes is shown as [ and no as (.
 * @param p_upb_incl    Is the upper bound inclusive yes or no. Yes is shown as ] and no as ).
 * @param p_key1        Part 1 of the key
 * @param p_key2        Part 2 of the key
 * @param p_key3        Part 3 of the key
 */
procedure raise_error_overlap
( p_error_code in varchar2
, p_lwb1 in varchar2
, p_upb1 in varchar2
, p_lwb2 in varchar2
, p_upb2 in varchar2
, p_lwb_incl boolean default true
, p_upb_incl boolean default true
, p_key1 in varchar2 default null
, p_key2 in varchar2 default null
, p_key3 in varchar2 default null
);

/**
 * Show the job status.
 *
 * @param p_job_name    The job name
 * @param p_start_date  The start date
 * 
 * @return A collection of ALL_SCHEDULER_JOB_RUN_DETAILS info for the job started at least the START DATE
 */
function show_job_status
( p_job_name in all_scheduler_job_run_details.job_name%type
, p_start_date_min in all_scheduler_job_run_details.actual_start_date%type default null
)
return t_job_status_tab
pipelined;

function dbms_assert$enquote_name
( p_str in varchar2
, p_what in varchar2
, p_capitalize in boolean default true
)
return varchar2;

function dbms_assert$qualified_sql_name
( p_str in varchar2
, p_what in varchar2
)
return varchar2;

function dbms_assert$schema_name
( p_str in varchar2
, p_what in varchar2
)
return varchar2;

function dbms_assert$simple_sql_name
( p_str in varchar2
, p_what in varchar2
)
return varchar2;

function dbms_assert$sql_object_name
( p_str in varchar2
, p_what in varchar2
)
return varchar2;
 
$if cfg_pkg.c_testing $then

--%suitepath(DATA)
--%suite

--%test
procedure ut_raise_error;

$end

end data_api_pkg;
/

