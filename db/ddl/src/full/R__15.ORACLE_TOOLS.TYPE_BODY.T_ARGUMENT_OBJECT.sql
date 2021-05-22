CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_ARGUMENT_OBJECT" AS

constructor function t_argument_object
( self in out nocopy t_argument_object
, p_argument# in integer
, p_argument_name in varchar2
, p_data_type_name in varchar2
, p_in_out in varchar2
, p_type_owner in varchar2
, p_type_name in varchar2
)
return self as result
is
begin
  self.argument#$ := p_argument#;
  self.argument_name$ := p_argument_name;
  self.data_type_name$ := p_data_type_name;
  self.in_out$ := p_in_out;
  self.type_owner$ := p_type_owner;
  self.type_name$ := p_type_name;
  return;
end;  

-- begin of getter(s)/setter(s)

member function argument#
return integer
deterministic
is
begin
  return self.argument#$;
end argument#;

member function argument_name
return varchar2
deterministic
is
begin
  return self.argument_name$;
end argument_name;

member function data_type_name
return varchar2
deterministic
is
begin
  return self.data_type_name$;
end data_type_name;

member function in_out
return varchar2
deterministic
is
begin
  return self.in_out$;
end in_out;

member function type_owner
return varchar2
deterministic
is
begin
  return self.type_owner$;
end type_owner;

member function type_name
return varchar2
deterministic
is
begin
  return self.type_name$;
end type_name;

-- end of getter(s)/setter(s)

member function data_type
return varchar2
deterministic
is
begin
  return
    case data_type_name()
      when 'REF'
      then 'REF "' || type_owner() || '"."' || type_name() || '"'
      when 'OBJECT'
      then '"' || type_owner() || '"."' || type_name() || '"'
      else data_type_name()
    end;
end;    

end;
/

