ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_SCHEMA_DDL_BATCHES" ADD CONSTRAINT "GENERATE_DDL_SESSION_SCHEMA_DDL_BATCHES$FK$1" FOREIGN KEY ("SESSION_ID")
	  REFERENCES "ORACLE_TOOLS"."GENERATE_DDL_SESSIONS" ("SESSION_ID") ON DELETE CASCADE ENABLE;
