create or replace package ui_session_pkg
as
-- See https://jeffkemponoracle.com/tag/best-practice/

c_date_fmt constant varchar2(100) := 'dd/mm/yyyy';
c_number_fmt constant varchar2(100) := '999G999G999G999G990D00';
c_nls_numeric_characters constant varchar2(2) := '.,';

/*
 * Get the date format.
 *
 * @return c_date_fmt
 */
function get_date_format
return varchar2
deterministic;

/*
 * Get nls_numeric_characters.
 *
 * @param p_language  The language
 *
 * @return  ', ' if p_language equals 'fr', c_nls_numeric_characters else
 */
function get_nls_numeric_characters
( p_language in varchar2 default apex_application.g_browser_language
)
return varchar2;

/*
 * Get a date from a session variable.
 *
 * @param p_name             The variable name
 * @param p_add_page_prefix  Add a page prefix (e.g. P || v('APP_PAGE_ID') || '_') to the variable?
 *
 * @return The value of the (page) variable converted to a date using c_date_fmt
 */
function get_date
( p_name in varchar2
, p_add_page_prefix in integer default 0
)
return date;
 
/*
 * Get a number from a session variable (nv(p_name)).
 *
 * @param p_name  The variable name
 * @param p_add_page_prefix  Add a page prefix (e.g. P || v('APP_PAGE_ID') || '_') to the variable?
 *
 * @return The value of the (page) variable
 */
function get_number
( p_name in varchar2
, p_add_page_prefix in integer default 0
)
return number;
 
/*
 * Get a string from a session variable (v(p_name)).
 *
 * @param p_name  The variable name
 * @param p_add_page_prefix  Add a page prefix (e.g. P || v('APP_PAGE_ID') || '_') to the variable?
 *
 * @return The value of the (page) variable
 */
function get_string
( p_name in varchar2
, p_add_page_prefix in integer default 0
)
return varchar2;
 
/*
 * Assign a date to a session variable.
 *
 * @param p_name   The variable name
 * @param p_value  The value
 */
procedure set_date
( p_name in varchar2
, p_value in date := null
);
  
/*
 * Assign a number to a session variable.
 *
 * @param p_name   The variable name
 * @param p_value  The value
 */
procedure set_number
( p_name in varchar2
, p_value in number := null
);
 
/*
 * Assign a string to a session variable.
 *
 * @param p_name   The variable name
 * @param p_value  The value
 */
procedure set_string
( p_name in varchar2
, p_value in varchar2 := null
);

/*
 * Convert to number.
 *
 * @param p_value     The value
 * @param p_language  The language
 */
function cast_to_number
( p_value in varchar2
, p_language in varchar2 default apex_application.g_browser_language
)
return number
deterministic;

/*
 * Convert to date.
 *
 * @param p_value  The value
 */
function cast_to_date
( p_value in varchar2
)
return date
deterministic;

/*
 * Convert a number to a string.
 *
 * @param p_value     The value
 * @param p_language  The language
 */
function cast_to_varchar2
( p_value in number
, p_language in varchar2 default apex_application.g_browser_language
)
return varchar2
deterministic;

/*
 * Convert a date to a string.
 *
 * @param p_value     The value
 */
function cast_to_varchar2
( p_value in date
)
return varchar2
deterministic;

/*
 * Convert a date to a string.
 *
 * @param p_value     The value
 * @param p_date_fmt  The date format
 * @param p_language  The language (en, fr, ...) to be converted to a nls_date_language 
 */
function cast_to_varchar2
( p_value in date
, p_date_fmt in varchar2 
, p_language in varchar2 default apex_application.g_browser_language
)
return varchar2
deterministic;

/*
 * Simulate an Apex session for tools like SQL*Plus or SQL Developer.
 *
 * @param p_app_id       The application id
 * @param p_app_user     The application user
 * @param p_app_page_id  The application page id
 */
procedure create_apex_session
( p_app_id in apex_applications.application_id%type
, p_app_user in apex_workspace_activity_log.apex_user%type
, p_app_page_id in apex_application_pages.page_id%type default 1
);

/*
 * Copy page items to another page.
 * 
 * The page item names should be prefixed as usual:
 *
 *   'P_' || p_app_page_id_from || '_'
 *
 * @param p_app_page_id_from  The application page id to copy from
 * @param p_app_page_id_to    The application page id to copy to
 * @param p_page_item_names   A list of page item names
 * @param p_sep               The list separator
 */
procedure copy_page_items
( p_page_item_names in varchar2
, p_app_page_id_from in naturaln
, p_app_page_id_to in naturaln default 0
, p_sep in varchar2 default ','
);

/**
 * Prepares a diloag url where the variables are taken from the user input and not session state.
 *
 * See https://hardlikesoftware.com/weblog/2017/01/05/passing-data-in-and-out-of-apex-dialogs/
 *
 * @param p_url  The url to prepare (use <p1>, <p2> ... for client side value substitutions)
 *
 * @return The prepared URL
 */
function prepare_dialog_url
( p_url in varchar2
)
return varchar2
deterministic;

end ui_session_pkg;
/
