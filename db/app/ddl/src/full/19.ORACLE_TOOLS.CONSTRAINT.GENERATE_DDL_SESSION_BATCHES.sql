ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_BATCHES" ADD CONSTRAINT "GENERATE_DDL_SESSION_BATCHES$CK$PARAMS" CHECK (params is json strict) ENABLE;

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_BATCHES" ADD CONSTRAINT "GENERATE_DDL_SESSION_BATCHES$PK" PRIMARY KEY ("SESSION_ID", "SEQ") ENABLE;

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_BATCHES" MODIFY ("CREATED" CONSTRAINT "GENERATE_DDL_SESSION_BATCHES$NNC$CREATED" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_BATCHES" MODIFY ("SEQ" CONSTRAINT "GENERATE_DDL_SESSION_BATCHES$NNC$SEQ" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_BATCHES" MODIFY ("SESSION_ID" CONSTRAINT "GENERATE_DDL_SESSION_BATCHES$NNC$SESSION_ID" NOT NULL ENABLE);

