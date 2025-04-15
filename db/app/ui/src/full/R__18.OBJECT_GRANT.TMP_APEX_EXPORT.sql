call dbms_application_info.set_module('R__18.OBJECT_GRANT.TMP_EXPORT_APEX.sql', null);
call dbms_application_info.set_action('SQL statement 1');
grant select, insert, delete on oracle_tools.tmp_export_apex to public;

