begin
  admin_install_pkg.define_project_db
  ( p_github_access_handle => 'paulissoft/oracle-tools'
  , p_path => 'db'
  , p_schema => null
  );
  admin_install_pkg.define_project_apex
  ( p_github_access_handle => 'paulissoft/oracle-tools'
  , p_path => 'apex'
  , p_schema => null
  );
end;
/
