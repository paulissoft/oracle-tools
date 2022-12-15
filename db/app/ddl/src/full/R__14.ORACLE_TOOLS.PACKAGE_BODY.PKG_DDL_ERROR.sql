CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."PKG_DDL_ERROR" IS

procedure raise_error
( p_error_number in pls_integer
, p_error_message in varchar2
, p_context_info in varchar2
, p_context_label in varchar2 default 'object schema info'
)
is
begin
  raise_application_error(p_error_number, p_error_message);
exception
  when others
  then
    reraise_error('An error occurred for object with ' || p_context_label || ': ' || p_context_info);
    raise; -- to keep the compiler happy
end raise_error;

procedure reraise_error
( p_error_message in varchar2
)
is
begin
  raise_application_error(oracle_tools.pkg_ddl_error.c_reraise_with_backtrace, p_error_message, true);
end reraise_error;

end pkg_ddl_error;
/

