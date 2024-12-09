ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECT_FILTERS" ADD CONSTRAINT "SCHEMA_OBJECT_FILTERS$CK$HASH_BUCKET_NR" CHECK (hash_bucket_nr >= 1) ENABLE;

ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECT_FILTERS" ADD CONSTRAINT "SCHEMA_OBJECT_FILTERS$CK$ID" CHECK (id between 1 and 2147483647) ENABLE;

ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECT_FILTERS" ADD CONSTRAINT "SCHEMA_OBJECT_FILTERS$CK$OBJ_JSON" CHECK (obj_json is json strict) ENABLE;

ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECT_FILTERS" ADD CONSTRAINT "SCHEMA_OBJECT_FILTERS$PK" PRIMARY KEY ("ID") ENABLE;

ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECT_FILTERS" ADD CONSTRAINT "SCHEMA_OBJECT_FILTERS$UK$1" UNIQUE ("HASH_BUCKET", "HASH_BUCKET_NR") ENABLE;

ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECT_FILTERS" MODIFY ("CREATED" CONSTRAINT "SCHEMA_OBJECT_FILTERS$NNC$CREATED" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECT_FILTERS" MODIFY ("HASH_BUCKET" CONSTRAINT "SCHEMA_OBJECT_FILTERS$NNC$HASH_BUCKET" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECT_FILTERS" MODIFY ("HASH_BUCKET_NR" CONSTRAINT "SCHEMA_OBJECT_FILTERS$NNC$HASH_BUCKET_NR" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECT_FILTERS" MODIFY ("ID" CONSTRAINT "SCHEMA_OBJECT_FILTERS$NNC$ID" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECT_FILTERS" MODIFY ("LAST_MODIFICATION_TIME_SCHEMA" CONSTRAINT "SCHEMA_OBJECT_FILTERS$NNC$LAST_MODIFICATION_TIME_SCHEMA" NOT NULL ENABLE);

ALTER TABLE "ORACLE_TOOLS"."SCHEMA_OBJECT_FILTERS" MODIFY ("OBJ_JSON" CONSTRAINT "SCHEMA_OBJECT_FILTERS$NNC$OBJ_JSON" NOT NULL ENABLE);

