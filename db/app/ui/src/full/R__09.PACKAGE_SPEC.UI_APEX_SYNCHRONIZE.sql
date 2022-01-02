create or replace package ui_apex_synchronize authid current_user is

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
, p_user in varchar2 default user
);

procedure publish_application;

procedure post_import
( p_application_id in apex_application_trans_map.primary_application_id%type
);

end ui_apex_synchronize;
/
