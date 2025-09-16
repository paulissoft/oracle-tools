create or replace type body property_typ
is

map member function to_string
return varchar2
is
begin
  return self.name || '=' || self.value;
end to_string;

end;
/
