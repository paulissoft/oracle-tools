begin
  admin_install_pkg.process_project
  ( p_github_access_handle => 'paulissoft/oracle-tools'
  , p_path => 'db/app'
  );
  admin_install_pkg.process_project
  ( p_github_access_handle => 'paulissoft/oracle-tools'
  , p_path => 'apex/app'
  );
end;
/
