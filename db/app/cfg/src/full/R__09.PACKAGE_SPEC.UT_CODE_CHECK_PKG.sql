CREATE OR REPLACE PACKAGE "UT_CODE_CHECK_PKG" IS

"abcd" constant varchar2(4 char) := 'abcd';

-- Do not define global public variables but use setters and getters
l_var varchar2(4 char);

procedure ut_assign(p_str out nocopy varchar2);

procedure ut_reference(p_str in varchar2);

/**
Test package for checking code (unused variables and so on).
**/

end ut_code_check_pkg;
/

