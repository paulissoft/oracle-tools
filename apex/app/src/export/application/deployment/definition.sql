prompt --application/deployment/definition
begin
--   Manifest
--     INSTALL: 138
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>100828379776356525
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_install(
 p_id=>wwv_flow_api.id(60962104706791595)
,p_welcome_message=>'This application installer will guide you through the process of creating your database objects and seed data.'
,p_configuration_message=>'You can configure the following attributes of your application.'
,p_build_options_message=>'You can choose to include the following build options.'
,p_validation_message=>'The following validations will be performed to ensure your system is compatible with this application.'
,p_install_message=>'Please confirm that you would like to install this application''s supporting objects.'
,p_upgrade_message=>'The application installer has detected that this application''s supporting objects were previously installed.  This wizard will guide you through the process of upgrading these supporting objects.'
,p_upgrade_confirm_message=>'Please confirm that you would like to install this application''s supporting objects.'
,p_upgrade_success_message=>'Your application''s supporting objects have been installed.'
,p_upgrade_failure_message=>'Installation of database objects and seed data has failed.'
,p_get_version_sql_query=>'SELECT OBJECT_NAME FROM USER_OBJECTS WHERE OBJECT_NAME = ''EXT_LOAD_FILE_PKG'''
,p_deinstall_success_message=>'Deinstallation complete.'
,p_required_free_kb=>100
,p_required_sys_privs=>'CREATE PROCEDURE'
,p_required_names_available=>'EXT_LOAD_FILE_PKG'
);
wwv_flow_api.component_end;
end;
/
