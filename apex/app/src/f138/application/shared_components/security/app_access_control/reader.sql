prompt --application/shared_components/security/app_access_control/reader
begin
wwv_flow_api.create_acl_role(
 p_id=>wwv_flow_api.id(290724376784474)
,p_static_id=>'READER'
,p_name=>'Reader'
,p_description=>'Role assigned to application readers.'
);
end;
/
