begin
  admin_install_pkg.define_project_apex
  ( p_github_access_handle => 'paulissoft/oracle-tools'
  , p_path => 'apex/app'
  , p_schema => 'ORACLE_TOOLS'
  , p_application_id => 138
  );
end;
/
