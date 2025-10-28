-- privileges granted to ADMIN user (or SYSTEM) by SYS
-- not necessary on an autonomous database since the ADMIN user has them

grant select on sys.v_$session to &&admin;
grant select on sys.v_$db_object_cache to &&admin;

-- running ORACLE_TOOLS.UI_APEX_SYNCHRONIZE inside ADMIN_INSTALL_PKG
grant inherit privileges on user admin to oracle_tools;
