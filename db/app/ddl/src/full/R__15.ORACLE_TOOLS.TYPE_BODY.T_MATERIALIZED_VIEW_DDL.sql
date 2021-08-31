CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_MATERIALIZED_VIEW_DDL" IS

overriding member procedure migrate
( self in out nocopy t_materialized_view_ddl
, p_source in t_schema_ddl
, p_target in t_schema_ddl
)
is
  l_tgt_materialized_view_object t_materialized_view_object := treat(p_target.obj as t_materialized_view_object);
  l_schema_ddl_tab t_schema_ddl_tab;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_MATERIALIZED_VIEW_DDL.MIGRATE');
  dbug.print(dbug."input", 'p_source.obj.id(): %s; p_target.obj.id(): %s', p_source.obj.id(), p_target.obj.id());
$end

  -- first the standard things
  t_schema_ddl.migrate
  ( p_source => p_source
  , p_target => p_target
  , p_schema_ddl => self
  );

  -- next: preserve the grants
  select  value(t)
  bulk collect
  into    l_schema_ddl_tab
  from    table
          ( oracle_tools.pkg_ddl_util.display_ddl_schema
            ( l_tgt_materialized_view_object.object_schema() -- p_schema
            , null                                           -- p_new_schema
            , 0                                              -- p_sort_objects_by_deps
            , 'OBJECT_GRANT'                                 -- p_object_type
            , null                                           -- p_object_names
            , null                                           -- p_object_names_include
            , l_tgt_materialized_view_object.network_link()  -- p_network_link
            , 0                                              -- p_grantor_is_schema
            )
          ) t
  ;

  -- drop the target materialized view
  self.uninstall(p_target);
  -- create the source materialized view
  self.install(p_source);
  -- recreate the grants
  if l_schema_ddl_tab is not empty
  then
    for i_idx in l_schema_ddl_tab.first .. l_schema_ddl_tab.last
    loop
      if cardinality(l_schema_ddl_tab(i_idx).ddl_tab) > 0
      then
        for i_ddl_idx in l_schema_ddl_tab(i_idx).ddl_tab.first .. l_schema_ddl_tab(i_idx).ddl_tab.last
        loop
          self.add_ddl
          ( p_verb => l_schema_ddl_tab(i_idx).ddl_tab(i_ddl_idx).verb()
          , p_text => l_schema_ddl_tab(i_idx).ddl_tab(i_ddl_idx).text
          );
        end loop;
      end if;
    end loop;
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end migrate;

end;
/

