prompt --application/shared_components/logic/application_items/application_context
begin
wwv_flow_api.create_flow_item(
 p_id=>wwv_flow_api.id(35839151115949559)
,p_name=>'APPLICATION_CONTEXT'
,p_protection_level=>'S'
,p_item_comment=>'Context that can be used by another application. For instance, when the Upload File page is invoked from another application, that calling application may set this context so it can be used during the DML of the Upload File process.'
);
end;
/
