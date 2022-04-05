prompt --application/shared_components/logic/application_items/application_owner
begin
--   Manifest
--     APPLICATION ITEM: APPLICATION_OWNER
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>80521331112734834
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_flow_item(
 p_id=>wwv_flow_api.id(30519817178939303)
,p_name=>'APPLICATION_OWNER'
,p_protection_level=>'I'
,p_item_comment=>'The application owner at login.'
);
wwv_flow_api.component_end;
end;
/
