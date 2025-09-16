create or replace type body property_typ
is

order member function match(p_other in property_typ)
return integer
is
begin
  return
    case
      when -- name equal?
           ( self.name is null and p_other.name is null ) or
           ( self.name = p_other.name )
      then
        case
          when -- value equal?
               ( self.value is null and p_other.value is null ) or
               ( self.value = p_other.value )
          then 0            
          when self.value is null
          then -2
          when p_other.value is null
          then +2
          when self.value < p_other.value
          then -2
          when self.value > p_other.value
          then +2
          else 1/0 -- should not happen
        end
      when self.name is null
      then -1
      when p_other.name is null
      then +1
      when self.name < p_other.name
      then -1
      when self.name > p_other.name
      then +1
      else 1/0 -- should not happen
    end;
end match;

end;
/
