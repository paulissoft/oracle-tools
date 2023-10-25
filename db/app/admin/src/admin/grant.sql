-- privileges granted to ADMIN user (or SYSTEM) by sys
-- not necessary on an autonomous database since the ADMIN user has them

grant select on sys.v_$session to &&admin;
grant select on sys.v_$db_object_cache to &&admin;
