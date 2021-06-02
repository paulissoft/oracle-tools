prompt --application/shared_components/logic/application_items/application_owner
begin
wwv_flow_api.create_flow_item(
 p_id=>wwv_flow_api.id(24577268012285621)
,p_name=>'APPLICATION_OWNER'
,p_protection_level=>'I'
,p_item_comment=>'The application owner at login.'
);
end;
/
