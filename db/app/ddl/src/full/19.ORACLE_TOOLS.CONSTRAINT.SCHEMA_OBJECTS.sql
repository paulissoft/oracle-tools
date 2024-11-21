ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECTS" ADD CONSTRAINT "SCHEMA_OBJECTS$CK$OBJ" CHECK (obj is not null and obj.id = id) ENABLE;

ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECTS" ADD CONSTRAINT "SCHEMA_OBJECTS$PK" PRIMARY KEY ("ID") ENABLE;

ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECTS" ADD UNIQUE (TREAT("OBJ" AS "T_TABLE_COLUMN_OBJECT")."DATA_DEFAULT$") RELY ENABLE;

ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECTS" ADD UNIQUE (TREAT("OBJ" AS "T_TYPE_METHOD_OBJECT")."ARGUMENTS") RELY ENABLE;

ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECTS" MODIFY ("CREATED" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECTS" MODIFY ("ID" NOT NULL ENABLE);

