create or replace function data_timestamp
return timestamp with time zone as
begin
  return current_timestamp;
end;
/
