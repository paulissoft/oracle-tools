CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_TRIGGER_DDL" IS

overriding member procedure add_ddl
( self in out nocopy t_trigger_ddl
, p_verb in varchar2
, p_text in clob
, p_add_sqlterminator in integer
)
is
  -- GPA 2017-03-27 #142494703 The DDL generator should remove leading whitespace before WHEN clauses in triggers because that generates differences.
  -- A trigger WHEN clause should have at least keyword old or new followed by a dot
  l_find_expr constant varchar2(100) := '^(\s+)(when\s(|.*[^:a-zA-Z0-9$#_])(old|new)\..*)$'; -- :old or :new is used in trigger body, not the triggering event
  l_repl_expr constant varchar2(100) := '\2';
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'ADD_DDL');
  dbug.print(dbug."input", 'self:');
  self.print();
  dbug.print(dbug."input", 'p_verb: %s; p_add_sqlterminator: %s', p_verb, p_add_sqlterminator);
$end

  (self as t_schema_ddl).add_ddl
  ( p_verb => p_verb 
  , p_text => regexp_replace(p_text, l_find_expr, l_repl_expr, 1, 1, 'im') -- case insensitive multi-line search/replace
  , p_add_sqlterminator => p_add_sqlterminator
  );

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end add_ddl;

end;
/

