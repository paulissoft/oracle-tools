prompt --application/shared_components/logic/application_computations
begin
wwv_flow_api.create_flow_computation(
 p_id=>wwv_flow_api.id(57262039569176820)
,p_computation_sequence=>10
,p_computation_item=>'APPLICATION_OWNER'
,p_computation_point=>'AFTER_LOGIN'
,p_computation_type=>'QUERY'
,p_computation_processed=>'REPLACE_EXISTING'
,p_computation=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select  a.owner',
'from    apex_applications a',
'where   a.application_id = to_number(:APP_ID)'))
);
wwv_flow_api.create_flow_computation(
 p_id=>wwv_flow_api.id(5744521498799724)
,p_computation_sequence=>10
,p_computation_item=>'FSP_LANGUAGE_PREFERENCE'
,p_computation_point=>'AFTER_SUBMIT'
,p_computation_type=>'ITEM_VALUE'
,p_computation_processed=>'REPLACE_EXISTING'
,p_computation=>'REQUEST'
,p_compute_when=>'en,fr'
,p_compute_when_type=>'REQUEST_IN_CONDITION'
);
wwv_flow_api.create_flow_computation(
 p_id=>wwv_flow_api.id(5930608721930836)
,p_computation_sequence=>10
,p_computation_item=>'FSP_LANGUAGE_PREFERENCE'
,p_computation_point=>'ON_NEW_INSTANCE'
,p_computation_type=>'FUNCTION_BODY'
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
wwv_flow_api.create_flow_computation(
 p_id=>wwv_flow_api.id(53204375573328365)
,p_computation_sequence=>10
,p_computation_item=>'SHOW_HELP'
,p_computation_point=>'ON_NEW_INSTANCE'
,p_computation_type=>'STATIC_ASSIGNMENT'
,p_computation_processed=>'REPLACE_EXISTING'
,p_computation=>'1'
,p_computation_comment=>'Show help region by default but use the collapsible template.'
);
end;
/
