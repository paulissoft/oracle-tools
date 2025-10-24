CREATE OR REPLACE PACKAGE "UI_APEX_SYNCHRONIZE" AUTHID CURRENT_USER IS

procedure pre_export
( p_workspace_name in apex_workspaces.workspace%type
, p_application_id in apex_application_trans_map.primary_application_id%type
, p_update_language_mapping in boolean
, p_seed_and_publish in boolean
);

procedure pre_import
( p_application_id in apex_application_trans_map.primary_application_id%type
);

procedure prepare_import
( p_workspace_name in apex_workspaces.workspace%type
, p_application_id in apex_application_trans_map.primary_application_id%type
, p_user in varchar2 default sys_context('USERENV', 'CURRENT_SCHEMA')
);

/**
 * Published the application and normalises the translated application id.
 *
 * When the primary application id is 116, the translated application id numbers will become a number at least p_application_id * 1000 + 1.
 *
 * @param p_application_id  The primary application id
 * @param p_workspace_id    The workspace id (if not null the security group wil be set)
 * @param p_workspace_name  The workspace name (if not null the security group wil be set to the workspace id of upper(p_workspace_name))
 */

procedure publish_application
( p_application_id in apex_application_trans_map.primary_application_id%type default wwv_flow_application_install.get_application_id
, p_workspace_id in apex_workspaces.workspace_id%type default wwv_flow_application_install.get_workspace_id
, p_workspace_name in apex_workspaces.workspace%type default null
);

procedure post_import
( p_application_id in apex_application_trans_map.primary_application_id%type
);

end ui_apex_synchronize;
/

