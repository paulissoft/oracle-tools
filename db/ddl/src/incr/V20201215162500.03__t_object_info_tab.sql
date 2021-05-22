-- CREATE TYPE should not use CREATE TYPE .. AS TABLE OF "SCHEMA"."OBJECT"
-- otherwise the unit test for synchronize will fail
-- since schema EMPTY can not grant those table types when they are base on ORACLE_TOOLS objects.

/* To help Flyway */
BEGIN
  EXECUTE IMMEDIATE q'[
CREATE TYPE "ORACLE_TOOLS"."T_OBJECT_INFO_TAB" AS TABLE OF "T_OBJECT_INFO_REC"
]';
END;
/
