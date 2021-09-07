create or replace package ut_code_check_pkg is

"abcd" constant varchar2(4 char) := 'abcd';

-- Do not defined global public variables but use setters and getters
l_var varchar2(4 char);

end ut_code_check_pkg;
/
