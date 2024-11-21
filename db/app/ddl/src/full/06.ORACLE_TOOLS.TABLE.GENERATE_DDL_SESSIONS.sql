CREATE TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSIONS" 
   (	"SESSION_ID" NUMBER DEFAULT to_number(sys_context('USERENV', 'SESSIONID')) NOT NULL ENABLE, 
	"SCHEMA_OBJECT_FILTER_ID" NUMBER(*,0) NOT NULL ENABLE, 
	"CREATED" TIMESTAMP (6) DEFAULT sys_extract_utc(systimestamp) NOT NULL ENABLE, 
	"UPDATED" TIMESTAMP (6), 
	 CONSTRAINT "GENERATE_DDL_SESSIONS$PK" PRIMARY KEY ("SESSION_ID") ENABLE
   )  
  ORGANIZATION INDEX NOCOMPRESS PCTFREE 10 INITRANS 2 MAXTRANS 255 LOGGING
  TABLESPACE "USERS" 
 PCTTHRESHOLD 50;

