CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_SEQUENCE_DDL" AS

overriding member procedure add_ddl
( self in out nocopy t_sequence_ddl
, p_verb in varchar2
, p_text in t_text_tab
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_SEQUENCE_DDL.ADD_DDL (1)');
$end

  self.ddl_tab.extend(1);
  self.ddl_tab(self.ddl_tab.last) :=
    t_ddl_sequence
    ( /*p_ddl# => */self.ddl_tab.last
    , /*p_verb => */p_verb
    , /*p_text => */p_text
    );

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end add_ddl;

end;
/

