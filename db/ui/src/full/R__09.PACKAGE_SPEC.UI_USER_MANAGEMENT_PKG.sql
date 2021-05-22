create or replace package ui_user_management_pkg
is

"USE_APEX_GROUPS" constant varchar2(100) := 'USE_APEX_GROUPS'; -- an Apex BUILD OPTION

type t_users_rec is record
( user_name apex_workspace_apex_users.user_name%type
, last_name apex_workspace_apex_users.last_name%type
, first_name apex_workspace_apex_users.first_name%type
, email apex_workspace_apex_users.email%type
, date_created apex_workspace_apex_users.date_created%type
, account_expiry apex_workspace_apex_users.account_expiry%type
, account_locked varchar2(1 char)
, is_admin varchar2(1 char)
, is_application_developer varchar2(1 char)
, group_name varchar2(4000 char)
, first_schema_provisioned apex_workspace_apex_users.first_schema_provisioned%type
);

type t_users_tab is table of t_users_rec;

function show_users
( p_user_name in apex_workspace_apex_users.user_name%type default null
)
return t_users_tab
pipelined;

/*
 * Has the user a role?
 * 
 * Depending on the build option USE_APEX_GROUPS (Include or Exclude) this will:
 * 1) for Include use apex_util.get_groups_user_belongs_to() to get the group the user belongs to
 * 2) for Exclude use users_tbl get its profile 
 * 
 * Now the group/profile should match (wildcard like) any of the p_role_tab items.
 *
 * @param p_role_tab  The roles (wildcards allowed with \ as escape) to check for
 * @param p_app_user  The application user
 * @param p_app_id    The application id
 *
 * @return 1 (true) or 0 (false)
 */
function has_role
( p_role_tab in sys.odcivarchar2list
, p_app_user in varchar2 default apex_application.g_user
, p_app_id in number default apex_application.g_flow_id
)
return integer;

/*
 * Has the user an ACL role?
 * 
 * This uses the Application Access Control to check the roles.
 *
 * @param p_role_tab  The roles (wildcards allowed with \ as escape) to check for
 * @param p_app_user  The application user
 * @param p_app_id    The application id
 *
 * @return If any of the p_role_tab items returns a positive result for APEX_ACL.HAS_USER_ROLE() it will return true (1) else false (0).
 */
function has_acl_role
( p_role_tab in sys.odcivarchar2list
, p_app_user in varchar2 default apex_application.g_user
, p_app_id in number default apex_application.g_flow_id
)
return integer;

/*
 * Get the user role?
 *
 * Depending on the build option USE_APEX_GROUPS (Include or Exclude) this will:
 * 1) for Include use apex_util.get_groups_user_belongs_to() to get the group the user belongs to
 * 2) for Exclude use users_tbl get its profile 
 * 
 * @param p_app_user  The application user
 * @param p_app_id    The application id
 *
 * @return the group or profile the user belongs to
 */
function get_role
( p_app_user in varchar2 default apex_application.g_user
, p_app_id in number default apex_application.g_flow_id
)
return varchar2;

/**
 * Reset the passwords for a list of users.
 *
 * Uses the reset_password() routine to reset the passwords for the users in the list.
 *
 * @param p_user_tab  A list of users
 */
procedure reset_passwords
( p_user_tab in apex_application_global.vc_arr2 default apex_application.g_f01
);

/*
 * Reset the password from inside a job.
 *
 * See also https://support.oracle.com/, Doc ID 2210311.1
 *
 * @param p_username             The username
 * @param p_message              The message to display
 * @param p_workspace_id         The workspace to set the security context for
 * @param p_use_current_session  Use the current session (value not 0) or 
 *                               let the job UI_RESET_PWD_JOB do it (value 0).
 */
procedure reset_password
( p_username in varchar2
, p_message in varchar2 default 'Here are your credentials:'
, p_workspace_id in number default sys_context('APEX$SESSION', 'WORKSPACE_ID')
, p_use_current_session in integer default 0 -- 0: false; 1: true
);

/**
 * Issue dml on APEX_WORKSPACE_APEX_USERS.
 *
 * @param p_action                    (I)nsert, (U)pdate or (D)elete
 * @param p_user_name                 The Apex login
 * @param p_last_name                 The last name
 * @param p_first_name                The first name
 * @param p_email                     The email address
 * @param p_account_expiry            The date the account expires
 * @param p_account_locked            Is the account locked (Y/N)?
 * @param p_is_admin                  Is the user an Apex Administrator (Y/N)?
 * @param p_is_application_developer  Is the user an Apex Application Developer (Y/N)?
 * @param p_group_name                The group name the user belongs to
 * @param p_first_schema_provisioned  The default schema
 */
procedure dml_apex_user
( p_action in varchar2
, p_user_name in apex_workspace_apex_users.user_name%type
, p_last_name in apex_workspace_apex_users.last_name%type
, p_first_name in apex_workspace_apex_users.first_name%type
, p_email in apex_workspace_apex_users.email%type
, p_account_expiry in apex_workspace_apex_users.account_expiry%type
, p_account_locked in apex_workspace_apex_users.account_locked%type
, p_is_admin in apex_workspace_apex_users.is_admin%type
, p_is_application_developer in apex_workspace_apex_users.is_application_developer%type
, p_group_name in apex_workspace_group_users.group_name%type
, p_first_schema_provisioned in apex_workspace_apex_users.first_schema_provisioned%type
);

end ui_user_management_pkg;
/
