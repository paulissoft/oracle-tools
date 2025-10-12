CREATE OR REPLACE FUNCTION "DATA_CALL_INFO" 
return varchar2
is
begin
  return oracle_tools.data_auditing_pkg.get_call_info;
end;
/

