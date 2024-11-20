CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_SEQUENCE_DDL" AS

overriding member procedure add_ddl
( self in out nocopy oracle_tools.t_sequence_ddl
, p_verb in varchar2
, p_text_tab in oracle_tools.t_text_tab
)
is
$if oracle_tools.pkg_ddl_util.c_set_start_with_to_minvalue $then
  l_ddl_text varchar2(32767);
$end  
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'ADD_DDL (1)');
$end

  self.ddl_tab.extend(1);

$if oracle_tools.pkg_ddl_util.c_set_start_with_to_minvalue $then

  l_ddl_text := p_text_tab(1);

  -- CREATE SEQUENCE "BC_PORTAL"."BCP_APPLICATION_LOG_SEQ" MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 254432 CACHE 20 NOORDER NOCYCLE NOKEEP NOSCALE GLOBAL

  -- use MINVALUE for START WITH
  l_ddl_text :=
    regexp_replace
    ( l_ddl_text
    , '^(\s*CREATE\s+SEQUENCE.+)(MINVALUE\s+)(\d+)(.+START\s+WITH\s+)(\d+)(.*)$'
    , '\1\2\3\4\3\6'
    );
      
  self.ddl_tab(self.ddl_tab.last) :=
    oracle_tools.t_ddl -- no need to use oracle_tools.t_ddl_sequence since the START WITH is changed
    ( p_ddl# => self.ddl_tab.last
    , p_verb => p_verb
    , p_text_tab => oracle_tools.t_text_tab(l_ddl_text)
    );

$else

  self.ddl_tab(self.ddl_tab.last) :=
    oracle_tools.t_ddl_sequence
    ( /*p_ddl# => */self.ddl_tab.last
    , /*p_verb => */p_verb
    , /*p_text => */p_text
    );

$end

  self.chk(null);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end add_ddl;

end;
/

