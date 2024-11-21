ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_SCHEMA_DDL_CHUNKS" ADD CONSTRAINT "GENERATE_DDL_SESSION_SCHEMA_DDL_CHUNKS$CK$CHUNK#" CHECK (chunk# >= 1) ENABLE;

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_SCHEMA_DDL_CHUNKS" ADD CONSTRAINT "GENERATE_DDL_SESSION_SCHEMA_DDL_CHUNKS$PK" PRIMARY KEY ("SESSION_ID", "SCHEMA_OBJECT_ID", "DDL#", "CHUNK#") ENABLE;

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_SCHEMA_DDL_CHUNKS" MODIFY ("CHUNK#" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_SCHEMA_DDL_CHUNKS" MODIFY ("CREATED" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_SCHEMA_DDL_CHUNKS" MODIFY ("DDL#" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_SCHEMA_DDL_CHUNKS" MODIFY ("SCHEMA_OBJECT_ID" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_SCHEMA_DDL_CHUNKS" MODIFY ("SESSION_ID" NOT NULL ENABLE);

