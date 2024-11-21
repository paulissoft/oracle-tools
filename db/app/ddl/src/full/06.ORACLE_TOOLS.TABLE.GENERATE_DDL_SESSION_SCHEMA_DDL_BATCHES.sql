CREATE TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_SCHEMA_DDL_BATCHES" 
   (	"SESSION_ID" NUMBER NOT NULL ENABLE, 
	"SEQ" NUMBER(*,0) NOT NULL ENABLE, 
	"CREATED" TIMESTAMP (6) DEFAULT sys_extract_utc(systimestamp) NOT NULL ENABLE, 
	"SCHEMA" VARCHAR2(128), 
	"TRANSFORM_PARAM_LIST" VARCHAR2(4000), 
	"OBJECT_SCHEMA" VARCHAR2(128), 
	"OBJECT_TYPE" VARCHAR2(30), 
	"BASE_OBJECT_SCHEMA" VARCHAR2(128), 
	"BASE_OBJECT_TYPE" VARCHAR2(30), 
	"OBJECT_NAME_TAB" "ORACLE_TOOLS"."T_TEXT_TAB" , 
	"BASE_OBJECT_NAME_TAB" "ORACLE_TOOLS"."T_TEXT_TAB" , 
	"NR_OBJECTS" NUMBER(*,0)
   )  
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS NOLOGGING
  TABLESPACE "USERS" 
 NESTED TABLE "OBJECT_NAME_TAB" STORE AS "GENERATE_DDL_SESSION_SCHEMA_DDL_BATCHES$OBJECT_NAME_TAB"
 (PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 LOGGING
 NOCOMPRESS 
  TABLESPACE "USERS" ) RETURN AS VALUE
 NESTED TABLE "BASE_OBJECT_NAME_TAB" STORE AS "GENERATE_DDL_SESSION_SCHEMA_DDL_BATCHES$BASE_OBJECT_NAME_TAB"
 (PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 LOGGING
 NOCOMPRESS 
  TABLESPACE "USERS" ) RETURN AS VALUE;
