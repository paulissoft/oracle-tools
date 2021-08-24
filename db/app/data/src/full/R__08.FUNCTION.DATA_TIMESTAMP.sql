CREATE OR REPLACE FUNCTION "DATA_TIMESTAMP" 
return timestamp with time zone as
begin
  return current_timestamp;
end;
/

