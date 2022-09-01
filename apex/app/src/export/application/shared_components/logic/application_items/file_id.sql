prompt --application/shared_components/logic/application_items/file_id
begin
--   Manifest
--     APPLICATION ITEM: FILE_ID
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>127029477646494312
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_flow_item(
 p_id=>wwv_flow_api.id(45037795716225604)
,p_name=>'FILE_ID'
,p_protection_level=>'N'
,p_item_comment=>'The temporary file id (APEX_APPLICATION_TEMP_FILES).'
);
wwv_flow_api.component_end;
end;
/
