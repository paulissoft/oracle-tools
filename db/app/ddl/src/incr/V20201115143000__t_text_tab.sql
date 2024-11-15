-- We must specify an OID to be able to use it remotely.
begin
  execute immediate q'[CREATE TYPE "ORACLE_TOOLS"."T_TEXT_TAB" AS TABLE OF VARCHAR2(4000 BYTE)]';
end;
/

