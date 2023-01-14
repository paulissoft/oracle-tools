prompt --application/shared_components/logic/application_items/application_context
begin
--   Manifest
--     APPLICATION ITEM: APPLICATION_CONTEXT
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>84978882401008962
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_flow_item(
 p_id=>wwv_flow_api.id(32139319229017000)
,p_name=>'APPLICATION_CONTEXT'
,p_protection_level=>'S'
,p_item_comment=>'Context that can be used by another application. For instance, when the Upload File page is invoked from another application, that calling application may set this context so it can be used during the DML of the Upload File process.'
);
wwv_flow_api.component_end;
end;
/
