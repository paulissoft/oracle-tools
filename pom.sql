begin
  admin_install_pkg.process_root_project
  ( p_github_access_handle => 'paulissoft/oracle-tools'
  , p_modules => sys.odcivarchar2list('db/app', 'apex/app')
  );
end;
/
