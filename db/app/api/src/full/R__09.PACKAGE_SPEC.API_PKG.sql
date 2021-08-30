CREATE OR REPLACE PACKAGE "API_PKG" authid current_user -- needed to invoke procedures from the calling schema without grants
is

-- GJP 2020-11-30  Use cfg_pkg.c_debugging instead
-- -- for conditional compiling
-- c_debugging constant pls_integer := data_api_pkg.c_debugging;

type t_rec is record
( id integer
);

type t_tab is table of t_rec;

type t_cur is ref cursor return t_rec;

type t_errors_tab is table of user_errors%rowtype;

/**
 * Return the owner of the package DATA_API_PKG.
 *
 * @return data_api_pkg.get_owner
 */
function get_data_owner
return all_objects.owner%type;

/**
 * Show IDs using a query.
 *
 * @param p_cursor  A query cursor
 */
function show_cursor
( p_cursor in t_cur
)
return t_tab
pipelined;

/**
 * Translate a generic application error, otherwise return the error.
 *
 * The default translation function (get_error_text) is a stand alone function that 
 * does not exist by default. This is on purpose since it is system specific.
 *
 * @param p_sqlerrm   May be something like 'ORA-20001: #<error code>#<p1>#<p2>#<p3>
 * @param p_function  The function that gets the text for error <error code>.
 * 
 * @return If p_sqlerrm starts with ORA-20001 translate it using p_function, otherwise return p_sqlerrm.
 */
function translate_error
( p_sqlerrm in varchar2
, p_function in varchar2 default 'get_error_text'
)
return varchar2;

/**
 * Convert a separated list into a collection.
 *
 * @param p_value_list   A separated list of values
 * @param p_sep          The list separator
 * @param p_ignore_null  Ignore null values (when set, value list "|" returns 0 elements instead of 2)
 * 
 * @return The collection of values
 */
function list2collection
( p_value_list in varchar2
, p_sep in varchar2 default ','
, p_ignore_null in naturaln default 1
)
return sys.odcivarchar2list
deterministic;

function excel_date_number2date
( p_date_number in integer
)
return date
deterministic;

procedure ut_expect_violation
( p_br_name in varchar2
, p_sqlcode in integer -- default sqlcode
, p_sqlerrm in varchar2 -- default sqlerrm
, p_data_owner in all_tables.owner%type -- default get_data_owner
);

/**
 * Compile objects in the current schema and show the errors associated with them.
 *
 * <p>
 * Both package/type specifications and bodies will be compiled.
 * </p>
 *
 * @param p_object_names          A comma separated list of object names.
 * @param p_object_names_include  How to treat the object name list: include (1), exclude (0) or don't care (null)?
 * @param p_plsql_warnings        For "alter session set PLSQL_WARNINGS = '<p_sql_warnings>'"
 *
 * @return A list of USER_ERRORS rows ordered by name, type, sequence.
 */
function show_compile_errors
( p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_plsql_warnings in varchar2 default 'ENABLE:ALL'
)
return t_errors_tab
pipelined;

$if cfg_pkg.c_testing $then

--%suitepath(API)
--%suite

-- for unit testing
procedure ut_setup
( p_autonomous_transaction in boolean
, p_br_package_tab in data_br_pkg.t_br_package_tab
, p_init_procedure in all_procedures.object_name%type default null
, p_insert_procedure in all_procedures.object_name%type default 'UT_INSERT'
);

procedure ut_teardown
( p_autonomous_transaction in boolean
, p_br_package_tab in data_br_pkg.t_br_package_tab
, p_init_procedure in all_procedures.object_name%type default null
, p_delete_procedure in all_procedures.object_name%type default 'UT_DELETE'
);

--%test
procedure ut_excel_date_number2date;

$end

end API_PKG;
/

