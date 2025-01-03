CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_DDL" AS

constructor function t_ddl
( self in out nocopy oracle_tools.t_ddl
, p_ddl# in integer
, p_verb in varchar2
, p_text_tab in oracle_tools.t_text_tab
)
return self as result
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCTOR');
$end

  self.ddl#$ := p_ddl#;
  self.verb$ := p_verb;
  set_text_tab(p_text_tab);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;

member function verb
return varchar2
deterministic
is
begin
  return self.verb$;
end verb;

member function ddl#
return integer
deterministic
is
begin
  return self.ddl#$;
end ddl#;

member procedure print
( self in oracle_tools.t_ddl
)
is
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 1 $then
  l_clob clob := null;
  l_lines_tab dbms_sql.varchar2a;
$end
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 1 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'PRINT');
  dbug.print
  ( dbug."info"
  , 'ddl#: %s; verb: %s; cardinality: %s'
  , self.ddl#()
  , self.verb()
  , case when self.text_tab is not null then self.text_tab.count end
  );
--$if oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  if self.text_tab is not null and self.text_tab.count > 0
  then
    oracle_tools.pkg_str_util.text2clob
    ( pi_text_tab => self.text_tab
    , pio_clob => l_clob
    , pi_append => false
    );
    oracle_tools.pkg_str_util.split
    ( p_str => l_clob
    , p_delimiter => chr(10)
    , p_str_tab => l_lines_tab
    );
    for i_idx in l_lines_tab.first .. l_lines_tab.last
    loop
      dbug.print(dbug."info", l_lines_tab(i_idx));
    end loop;
    dbms_lob.freetemporary(l_clob);
  end if;
--$end
  dbug.leave;
$else
  null;
$end
end print;

order member function match( p_ddl in oracle_tools.t_ddl )
return integer
deterministic
is
begin
  return compare(p_ddl);
end match;

member function compare( p_ddl in oracle_tools.t_ddl )
return integer
deterministic
is
  l_result binary_integer := 0;
  l_idx binary_integer;
  l_text1_tab oracle_tools.t_text_tab := null;
  l_text2_tab oracle_tools.t_text_tab := null;

  function cmp(p_val1 in varchar2, p_val2 in varchar2)
  return binary_integer
  is
  begin
    return
      case
        when p_val1 is null and p_val2 is null then 0
        when p_val1 is null then -1 -- cmp(null, X) = -1
        when p_val2 is null then +1 -- cmp(X, null) = +1
        when p_val1 < p_val1 then -1 -- cmp(X, Y) = -1 when X < Y
        when p_val1 > p_val1 then +1 -- cmp(X, Y) = +1 when X > Y
        else 0
      end;
  end cmp;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  function pos_not_equal(p_text1 in varchar2, p_text2 in varchar2)
  return pls_integer
  is
  begin
    if p_text1 is null and p_text2 is null
    then
      return 0;
    elsif p_text1 is null or p_text2 is null
    then
      dbug.print(dbug.warning, 'equal: "%s"; p_text1 remainder: "%s"; p_text2 remainder: "%s"', null, substr(p_text1, 1, 20), substr(p_text2, 1, 20));
      return 1;
    else
      for i_idx in 1 .. greatest(length(p_text1), length(p_text2))
      loop
        if substr(p_text1, i_idx, 1) = substr(p_text2, i_idx, 1)
        then
          null;
        else
          dbug.print(dbug.warning, 'equal: "%s"; p_text1 remainder: "%s"; p_text2 remainder: "%s"', substr(p_text1, 1, i_idx - 1), substr(p_text1, i_idx, 20), substr(p_text2, i_idx, 20));
          return i_idx;
        end if;
      end loop;
      return 0;
    end if;
  end pos_not_equal;
$end
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'COMPARE');
  dbug.print(dbug."input", 'self:');
  self.print();
  dbug.print(dbug."input", 'p_ddl:');
  p_ddl.print();
$end

  if p_ddl is null
  then
    l_result := null;
  else
    l_result := cmp(self.verb(), p_ddl.verb());

    if l_result = 0
    then
      l_result := cmp(to_char(self.ddl#()), to_char(p_ddl.ddl#()));
    end if;

    if l_result = 0
    then
      self.text_to_compare(l_text1_tab);
      p_ddl.text_to_compare(l_text2_tab);

      l_idx := l_text1_tab.first;

      loop
        exit when l_idx is null or l_result != 0;

        if l_idx <= l_text2_tab.last
        then
          l_result :=
            case
              when l_text1_tab(l_idx) is null and l_text2_tab(l_idx) is null
              then 0
              -- not both null
              when l_text1_tab(l_idx) is null
              then -1
              when l_text2_tab(l_idx) is null
              then +1
              -- both not null
              when l_text1_tab(l_idx) < l_text2_tab(l_idx)
              then -1
              when l_text1_tab(l_idx) > l_text2_tab(l_idx)
              then +1
              else 0
            end;
        else
          l_result := +1;
        end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
        if l_result != 0
        then
          dbug.print
          ( dbug."warning"
          , 'idx: %s; result: %s; index not equal: %s'
          , l_idx
          , l_result
          , pos_not_equal(l_text1_tab(l_idx), case when l_idx <= l_text2_tab.last then l_text2_tab(l_idx) end)
          );
        end if;
$end

        l_idx := l_text1_tab.next(l_idx);
      end loop;
    end if;
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.print(dbug."output", 'result: %s', l_result);
  dbug.leave;
$end

  return l_result;
end compare;

member procedure text_to_compare( self in oracle_tools.t_ddl, p_text_tab out nocopy oracle_tools.t_text_tab )
is
begin
  p_text_tab := self.text_tab;
end text_to_compare;

member procedure set_text_tab
( self in out nocopy oracle_tools.t_ddl
, p_text_tab in oracle_tools.t_text_tab
)
is
begin
  case
    when p_text_tab is null
    then self.text_tab := null;
    when p_text_tab.count = 0
    then self.text_tab := oracle_tools.t_text_tab();
    else
      self.text_tab := oracle_tools.t_text_tab();
      for i_idx in p_text_tab.first .. p_text_tab.last
      loop
        self.text_tab.extend(1);
        self.text_tab(self.text_tab.last) := p_text_tab(i_idx);
      end loop;
  end case;
  chk();
end set_text_tab;

member procedure chk
( self in oracle_tools.t_ddl
)
is
begin
  if self is null or
     self.text_tab is null or
     self.text_tab.count = 0 or
     ( self.verb$ is null and self.text_tab(1) like 'BEGIN%' ) or -- PROCOBJ
     ( self.verb$ not in ('ALTER', 'AUDIT', 'COMMENT', 'CREATE', 'DROP', 'GRANT', 'REVOKE', '--') )
  then
    null; -- OK
  elsif not( self.text_tab(1) like self.verb$ || ' %' )
  then
    oracle_tools.pkg_ddl_error.raise_error
    ( oracle_tools.pkg_ddl_error.c_ddl_not_correct
    , 'First line should start with ALTER, AUDIT, COMMENT, CREATE, DROP, GRANT, REVOKE or --.'
    , utl_lms.format_message
      ('verb="%s"; line[1:100]="%s"'
      , self.verb$
      , case when cardinality(self.text_tab) > 0 then substr(self.text_tab(1), 1, 100) end
      )
    );
  end if;
end chk;

static function ddl_info
( p_schema_object in oracle_tools.t_schema_object
, p_verb in varchar2
, p_ddl# in integer
)
return varchar2
deterministic
is
begin
  return '-- ddl info: ' ||
         p_verb || ';' ||
         replace(p_schema_object.schema_object_info(), ':', ';') || ';' ||
         p_ddl# || chr(10);
end ddl_info;

final member function ddl_info
( p_schema_object in oracle_tools.t_schema_object
)
return varchar2
deterministic
is
begin
  return oracle_tools.t_ddl.ddl_info(p_schema_object => p_schema_object, p_verb => self.verb(), p_ddl# => self.ddl#);
end ddl_info;

end;
/

