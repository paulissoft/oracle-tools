CREATE OR REPLACE PACKAGE "CFG_INSTALL_PKG" authid current_user
is 

procedure setup_session
( p_plsql_warnings in varchar2 default 'DISABLE:ALL'
);

procedure compile_objects
( p_compile_all in boolean
, p_reuse_settings in boolean
);

end cfg_install_pkg;
/

