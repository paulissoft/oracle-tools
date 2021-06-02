prompt --application/shared_components/logic/application_computations/application_owner
begin
wwv_flow_api.create_flow_computation(
 p_id=>wwv_flow_api.id(41240748836920086)
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
end;
/
