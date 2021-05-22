prompt --application/shared_components/security/app_access_control/contributor
begin
wwv_flow_api.create_acl_role(
 p_id=>wwv_flow_api.id(290671301784474)
,p_static_id=>'CONTRIBUTOR'
,p_name=>'Contributor'
,p_description=>'Role assigned to application contributors.'
);
end;
/
