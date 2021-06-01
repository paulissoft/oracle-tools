prompt --application/shared_components/logic/application_computations/fsp_language_preference
begin
wwv_flow_api.create_flow_computation(
 p_id=>wwv_flow_api.id(35446407322593076)
,p_computation_sequence=>10
,p_computation_item=>'FSP_LANGUAGE_PREFERENCE'
,p_computation_point=>'AFTER_SUBMIT'
,p_computation_type=>'ITEM_VALUE'
,p_computation_processed=>'REPLACE_EXISTING'
,p_computation=>'REQUEST'
,p_compute_when=>'en,fr'
,p_compute_when_type=>'REQUEST_IN_CONDITION'
);
end;
/
