begin
  admin_install_pkg.define_project_db
  ( p_github_access_handle => 'paulissoft/oracle-tools'
  , p_path => null
  , p_schema => null
  , p_modules => sys.odcivarchar2list('db', 'apex')
  );
end;
/
