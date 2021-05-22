prompt --application/shared_components/user_interface/lovs/user_theme_preference
begin
wwv_flow_api.create_list_of_values(
 p_id=>wwv_flow_api.id(51120340387475371)
,p_lov_name=>'USER_THEME_PREFERENCE'
,p_lov_query=>'.'||wwv_flow_api.id(51120340387475371)||'.'
,p_location=>'STATIC'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(51120647045475371)
,p_lov_disp_sequence=>1
,p_lov_disp_value=>'Allow End Users to choose Theme Style'
,p_lov_return_value=>'Yes'
);
end;
/
