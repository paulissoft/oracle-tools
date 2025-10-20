begin
  admin_install_pkg.define_project_db
  ( p_github_access_handle => 'paulissoft/oracle-tools'
  , p_path => 'db/app'
  , p_schema => 'ORACLE_TOOLS'
  , p_modules => sys.odcivarchar2list('cfg', 'data', 'api', 'ddl', 'ext', 'ui', 'util')
  );
end;
/
