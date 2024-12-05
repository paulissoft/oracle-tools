ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_BATCHES" ADD CONSTRAINT "GENERATE_DDL_SESSION_BATCHES$PK" PRIMARY KEY ("SESSION_ID", "SEQ") ENABLE;

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_BATCHES" ADD UNIQUE ("BASE_OBJECT_NAME_TAB") RELY ENABLE;

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_BATCHES" ADD UNIQUE ("OBJECT_NAME_TAB") RELY ENABLE;

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_BATCHES" ADD UNIQUE ("SCHEMA_OBJECT_FILTER"."OBJECT_CMP_TAB$") RELY ENABLE;

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_BATCHES" ADD UNIQUE ("SCHEMA_OBJECT_FILTER"."OBJECT_TAB$") RELY ENABLE;

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_BATCHES" MODIFY ("CREATED" CONSTRAINT "GENERATE_DDL_SESSION_BATCHES$NNC$CREATED" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_BATCHES" MODIFY ("SEQ" CONSTRAINT "GENERATE_DDL_SESSION_BATCHES$NNC$SEQ" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_BATCHES" MODIFY ("SESSION_ID" CONSTRAINT "GENERATE_DDL_SESSION_BATCHES$NNC$SESSION_ID" NOT NULL ENABLE);
