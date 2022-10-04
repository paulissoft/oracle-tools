prompt --application/shared_components/logic/application_computations/fsp_language_preference_002
begin
--   Manifest
--     APPLICATION COMPUTATION: FSP_LANGUAGE_PREFERENCE
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>151930114232313867
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_flow_computation(
 p_id=>wwv_flow_api.id(68935852775358698)
,p_computation_sequence=>10
,p_computation_item=>'FSP_LANGUAGE_PREFERENCE'
,p_computation_point=>'ON_NEW_INSTANCE'
,p_computation_type=>'FUNCTION_BODY'
,p_computation_language=>'PLSQL'
,p_computation_processed=>'REPLACE_EXISTING'
,p_computation=>wwv_flow_string.join(wwv_flow_t_varchar2(
'begin',
'  if APEX_UTIL.GET_SESSION_LANG is null',
'  then',
'    APEX_UTIL.SET_SESSION_LANG(SUBSTR(OWA_UTIL.GET_CGI_ENV(''HTTP_ACCEPT_LANGUAGE''), 1, 2));',
'  end if;',
'  -- raise_application_error(-20000, ''browser language: "'' || APEX_UTIL.GET_SESSION_LANG || ''"'');',
'  return APEX_UTIL.GET_SESSION_LANG;',
'end;'))
);
wwv_flow_api.component_end;
end;
/
