declare
  l_modules constant sys.odcivarchar2list :=
    sys.odcivarchar2list('cfg', 'data', 'api', 'ddl', 'ext', 'ui', 'util');
begin
  admin_install_pkg.process_project_db
  ( p_github_access_handle => 'paulissoft/oracle-tools'
  , p_path => 'db/app/admin'
  , p_schema => 'ADMIN'
  , p_src_callbacks => '/src/callbacks/'
  );
  for i_idx in l_modules.first .. l_modules.last
  loop
    admin_install_pkg.process_project_db
    ( p_github_access_handle => 'paulissoft/oracle-tools'
    , p_path => 'db/app/' || l_modules(i_idx)
    , p_schema => 'ORACLE_TOOLS'
    , p_src_callbacks => case l_modules(i_idx) when 'cfg' then '/src/callbacks/' end
    );
  end loop;
end;
/
