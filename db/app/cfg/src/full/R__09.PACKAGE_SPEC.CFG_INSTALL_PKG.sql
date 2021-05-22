create or replace package cfg_install_pkg authid current_user
is 

procedure setup_session;

procedure compile_objects(p_compile_all in boolean, p_reuse_settings in boolean);

end cfg_install_pkg;
/
