ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_SCHEMA_OBJECTS" ADD CONSTRAINT "GENERATE_DDL_SESSION_SCHEMA_OBJECTS$PK" PRIMARY KEY ("SESSION_ID", "SCHEMA_OBJECT_ID") ENABLE;

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_SCHEMA_OBJECTS" MODIFY ("CREATED" CONSTRAINT "GENERATE_DDL_SESSION_SCHEMA_OBJECTS$NNC$CREATED" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_SCHEMA_OBJECTS" MODIFY ("SCHEMA_OBJECT_FILTER_ID" CONSTRAINT "GENERATE_DDL_SESSION_SCHEMA_OBJECTS$NNC$SCHEMA_OBJECT_FILTER_ID" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_SCHEMA_OBJECTS" MODIFY ("SCHEMA_OBJECT_ID" CONSTRAINT "GENERATE_DDL_SESSION_SCHEMA_OBJECTS$NNC$SCHEMA_OBJECT_ID" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_SCHEMA_OBJECTS" MODIFY ("SESSION_ID" CONSTRAINT "GENERATE_DDL_SESSION_SCHEMA_OBJECTS$NNC$SESSION_ID" NOT NULL ENABLE);

