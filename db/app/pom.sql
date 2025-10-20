declare
  l_modules constant sys.odcivarchar2list :=
    sys.odcivarchar2list('cfg', 'data', 'api', 'ddl', 'ext', 'ui', 'util');
begin
  admin_install_pkg.define_project_db
  ( p_github_access_handle => 'paulissoft/oracle-tools'
  , p_path => 'db/app/admin'
  , p_schema => 'ADMIN'
  );
  for i_idx in l_modules.first .. l_modules.last
  loop
    admin_install_pkg.define_project_db
    ( p_github_access_handle => 'paulissoft/oracle-tools'
    , p_path => 'db/app/' || l_modules(i_idx)
    , p_schema => 'ORACLE_TOOLS'
    );
  end loop;
end;
/
