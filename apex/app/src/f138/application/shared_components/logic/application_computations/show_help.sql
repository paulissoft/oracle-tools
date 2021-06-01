prompt --application/shared_components/logic/application_computations/show_help
begin
wwv_flow_api.create_flow_computation(
 p_id=>wwv_flow_api.id(45298412832768541)
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
