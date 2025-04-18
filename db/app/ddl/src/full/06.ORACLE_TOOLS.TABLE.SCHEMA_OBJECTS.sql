CREATE TABLE "ORACLE_TOOLS"."SCHEMA_OBJECTS" 
   (	"ID" VARCHAR2(500) CONSTRAINT "SCHEMA_OBJECTS$NNC$ID" NOT NULL ENABLE, 
	"OBJ" "ORACLE_TOOLS"."T_SCHEMA_OBJECT" , 
	"CREATED" TIMESTAMP (6) DEFAULT sys_extract_utc(systimestamp) CONSTRAINT "SCHEMA_OBJECTS$NNC$CREATED" NOT NULL ENABLE, 
	"UPDATED" TIMESTAMP (6)
   )  
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS NOLOGGING
  TABLESPACE "USERS" 
 NESTED TABLE TREAT("OBJ" AS "T_TABLE_COLUMN_OBJECT")."DATA_DEFAULT$" STORE AS "SYSNTK+QW8MJWLUT2PNS1SWG7J40B"
 (PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 LOGGING
 NOCOMPRESS 
  TABLESPACE "USERS" ) RETURN AS VALUE
 NESTED TABLE TREAT("OBJ" AS "T_TYPE_METHOD_OBJECT")."ARGUMENTS" STORE AS "SYSNTO4G+P95DX26B4C=2SWG7J40B"
 (PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 LOGGING
 NOCOMPRESS 
  TABLESPACE "USERS" ) RETURN AS VALUE;

