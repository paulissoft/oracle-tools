CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_MEMBER_OBJECT" IS

member function member#
return integer
deterministic
is
begin
  return member#$;
end member#;

member function member_name
return varchar2
deterministic
is
begin
  return member_name$;
end member_name;

overriding member function id
return varchar2
deterministic
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('oracle_tools.t_member_object.ID');
  dbug.print(dbug."output", 'return: %s', member_name());
  dbug.leave;
$end  
  return member_name();
end id;

overriding member function is_a_repeatable
return integer
deterministic
is
begin
  return 0;
end is_a_repeatable;

end;
/

