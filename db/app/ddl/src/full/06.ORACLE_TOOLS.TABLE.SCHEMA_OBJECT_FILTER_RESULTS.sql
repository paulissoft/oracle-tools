CREATE TABLE "ORACLE_TOOLS"."SCHEMA_OBJECT_FILTER_RESULTS" 
   (	"SCHEMA_OBJECT_FILTER_ID" NUMBER(*,0) CONSTRAINT "SCHEMA_OBJECT_FILTER_RESULTS$NNC$SCHEMA_OBJECT_FILTER_ID" NOT NULL ENABLE, 
	"SCHEMA_OBJECT_ID" VARCHAR2(500) CONSTRAINT "SCHEMA_OBJECT_FILTER_RESULTS$NNC$SCHEMA_OBJECT_ID" NOT NULL ENABLE, 
	"GENERATE_DDL" NUMBER(1,0) CONSTRAINT "SCHEMA_OBJECT_FILTER_RESULTS$NNC$GENERATE_DDL" NOT NULL ENABLE, 
	"CREATED" TIMESTAMP (6) DEFAULT sys_extract_utc(systimestamp) CONSTRAINT "SCHEMA_OBJECT_FILTER_RESULTS$NNC$CREATED" NOT NULL ENABLE, 
	 CONSTRAINT "SCHEMA_OBJECT_FILTER_RESULTS$PK" PRIMARY KEY ("SCHEMA_OBJECT_FILTER_ID", "SCHEMA_OBJECT_ID") ENABLE
   )  
  ORGANIZATION INDEX NOCOMPRESS PCTFREE 10 INITRANS 2 MAXTRANS 255 LOGGING
  TABLESPACE "USERS" 
 PCTTHRESHOLD 50;

