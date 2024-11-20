-- We must specify an OID to be able to use it remotely.
begin
  -- Use VARCHAR2(1000 CHAR) instead of VARCHAR2(4000 CHAR) to circumvent this:
  --   ORA-00910: specified length too long for its datatype
  execute immediate q'[CREATE TYPE "ORACLE_TOOLS"."T_TEXT_TAB" AS TABLE OF VARCHAR2(1000 CHAR)]';
end;
/

