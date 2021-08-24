CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_TYPE_METHOD_OBJECT" AS

constructor function t_type_method_object
( self in out nocopy t_type_method_object
, p_base_object in t_named_object -- the type specification
, p_member# in integer -- the METHOD_NO
, p_member_name in varchar2 -- the METHOD_NAME
, p_method_type in varchar2
, p_parameters in integer
, p_results in integer
, p_final in varchar2
, p_instantiable in varchar2
, p_overriding in varchar2
, p_arguments in t_argument_object_tab default null
)
return self as result
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter('T_TYPE_METHOD_OBJECT.T_TYPE_METHOD_OBJECT');
  dbug.print
  ( dbug."input"
  , 'p_base_object.id(): %s; p_member#: %s; p_member_name: %s'
  , p_base_object.id()
  , p_member#
  , p_member_name
  );
$end

  self.base_object$ := p_base_object;
  self.member#$ := p_member#;
  self.member_name$ := p_member_name;
  self.method_type$ := p_method_type;
  self.parameters$ := p_parameters;
  self.results$ := p_results;
  self.final$ := p_final;
  self.instantiable$ := p_instantiable;
  self.overriding$ := p_overriding;
  self.arguments := p_arguments;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;  

-- begin of getter(s)/setter(s)

overriding member function object_type
return varchar2
deterministic
is
begin
  return 'TYPE_METHOD';
end object_type;  

member function method_type
return varchar2
deterministic
is
begin
  return self.method_type$;
end method_type;

member function parameters
return integer
deterministic
is
begin
  return self.parameters$;
end parameters;

member function results
return integer
deterministic
is
begin
  return self.results$;
end results;

member function final
return varchar2
deterministic
is
begin
  return self.final$;
end final;

member function instantiable
return varchar2
deterministic
is
begin
  return self.instantiable$;
end instantiable;

member function overriding
return varchar2
deterministic
is
begin
  return self.overriding$;
end overriding;

member function static_or_member
return varchar2
deterministic
is
begin
  if method_type() in ('ORDER', 'MAP')
  then
    return 'MEMBER';
  else
    -- is there a SELF argument
    if cardinality(self.arguments) > 0
    then
      for i_idx in self.arguments.first .. self.arguments.last
      loop
        if self.arguments(i_idx).argument_name() = 'SELF'
        then
          return 'MEMBER';
        end if;
      end loop;
    end if;

    return 'STATIC';
  end if;
end static_or_member;

overriding final map member function signature
return varchar2
deterministic
is
  l_signature varchar2(4000 char) := null;

  -- method name equal to type name
  l_is_constructor constant boolean := (self.base_object_name() = self.object_name());

  -- any results?
  l_is_function constant boolean := (self.results() > 0);

  procedure add(p_text in varchar2)
  is
  begin
    l_signature := l_signature || p_text;
  end add;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter('T_TYPE_METHOD_OBJECT.SIGNATURE');
$end

  add(case when self.final() = 'NO' then 'NOT ' end || 'FINAL ');
  add(case when self.instantiable() = 'NO' then 'NOT ' end || 'INSTANTIABLE ');
  add(case when self.overriding() = 'NO' then 'NOT ' end || 'OVERRIDING ');
  add(chr(10));

  if l_is_constructor
  then
    add('CONSTRUCTOR');
  else
    -- [ ORDER | MAP ]
    if self.method_type() in ('ORDER', 'MAP')
    then
      add(self.method_type() || ' ');
    end if;

    -- [ MEMBER | STATIC ] [ FUNCTION | PROCEDURE ]
    add(self.static_or_member() || ' ' || case when l_is_function then 'FUNCTION' else 'PROCEDURE' end);
  end if;

  -- method name
  add(' ' || self.member_name());

  -- first the arguments and later the return value
  if cardinality(self.arguments) > self.results() 
  then
    add(chr(10) || '( ');

    for i_idx in self.arguments.first + self.results() .. self.arguments.last
    loop
      add
      ( self.arguments(i_idx).argument_name() ||
        ' ' ||
        replace(self.arguments(i_idx).in_out(), '/', ' ') ||
        ' ' ||
        self.arguments(i_idx).data_type() ||
        case when i_idx < self.arguments.last then chr(10) || ', ' end
      );
    end loop;

    add(chr(10) || ')');
  end if;

  -- return value?
  if l_is_function
  then
    add(chr(10) || 'RETURN ');
    add(case when l_is_constructor then 'SELF AS RESULT' else self.arguments(1).data_type() end);
  end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.print(dbug."output", 'return: %s', l_signature);
  dbug.leave;
$end

  return l_signature;
end signature;

overriding member procedure chk
( self in t_type_method_object
, p_schema in varchar2
)
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter('T_TYPE_METHOD_OBJECT.CHK');
  dbug.print(dbug."input", 'p_schema: %s', p_schema);
$end

  pkg_ddl_util.chk_schema_object(p_dependent_or_granted_object => self, p_schema => p_schema);

  if self.parameters() + self.results() = nvl(cardinality(self.arguments), 0)
  then
    null;
  else
    raise_application_error
    ( -20000
    , 'Method (' ||
      self.member_name() ||
      ') has "' ||
      self.parameters() ||
      '" parameters, "' ||
      self.results() ||
      '" results and "' ||
      cardinality(self.arguments) ||
      '" arguments.'
    );
  end if;

  if self.base_object_type() = 'TYPE_SPEC'
  then
    null;
  else
    raise_application_error
    ( -20000
    , 'Method (' ||
      self.member_name() ||
      ') must have a TYPE_SPEC as its base object: ' ||
      self.base_object$.id()
    );
  end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end
end chk;

end;
/

