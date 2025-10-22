declare
begin
  execute immediate q'<
CREATE SEQUENCE "GITHUB_INSTALLED_VERSIONS_OBJECTS_SEQ" START WITH 1 NOCACHE ORDER
>';

  execute immediate q'<
CREATE TABLE "GITHUB_INSTALLED_VERSIONS_OBJECTS" (
    "ID"                           INTEGER DEFAULT ON NULL "GITHUB_INSTALLED_VERSIONS_OBJECTS_SEQ".NEXTVAL
        CONSTRAINT "NNC_GITHUB_INSTALLED_VERSIONS_OBJECTS_ID" NOT NULL,
    "GITHUB_INSTALLED_VERSIONS_ID" INTEGER
        CONSTRAINT "NNC_GITHUB_INSTALLED_VERSIONS_OBJECTS_GITHUB_INSTALLED_VERSIONS_ID" NOT NULL,
    "OBJECT_TYPE"                  VARCHAR2(30)
        CONSTRAINT "NNC_GITHUB_INSTALLED_VERSIONS_OBJECTS_OBJECT_TYPE" NOT NULL,
    "OBJECT_SCHEMA"                VARCHAR2(128),
    "OBJECT_NAME"                  VARCHAR2(128),
    "BASE_OBJECT_TYPE"             VARCHAR2(30),
    "BASE_OBJECT_SCHEMA"           VARCHAR2(128),
    "BASE_OBJECT_NAME"             VARCHAR2(128),
    "COLUMN_NAME"                  VARCHAR2(128),
    "GRANTEE"                      VARCHAR2(128),
    "PRIVILEGE"                    VARCHAR2(40),
    "GRANTABLE"                    VARCHAR2(3),
    "CREATED"                      DATE
        CONSTRAINT "NNC_GITHUB_INSTALLED_VERSIONS_OBJECTS_CREATED" NOT NULL,
    "LAST_DDL_TIME"                DATE
        CONSTRAINT "NNC_GITHUB_INSTALLED_VERSIONS_OBJECTS_LAST_DDL_TIME" NOT NULL
)
>';

  execute immediate q'<
COMMENT ON TABLE "GITHUB_INSTALLED_VERSIONS_OBJECTS" IS
    'GitHub installed versions objects. Used to determine whether at least one of the objects has changed since the installation date.'
>';

  execute immediate q'<
COMMENT ON COLUMN "GITHUB_INSTALLED_VERSIONS_OBJECTS"."OBJECT_TYPE" IS
    'oracle_tools.t_schema_object.object_type'
>';

  execute immediate q'<
COMMENT ON COLUMN "GITHUB_INSTALLED_VERSIONS_OBJECTS"."OBJECT_SCHEMA" IS
    'oracle_tools.t_schema_object.object_schema'
>';

  execute immediate q'<
COMMENT ON COLUMN "GITHUB_INSTALLED_VERSIONS_OBJECTS"."OBJECT_NAME" IS
    'oracle_tools.t_schema_object.object_name'
>';

  execute immediate q'<
COMMENT ON COLUMN "GITHUB_INSTALLED_VERSIONS_OBJECTS"."BASE_OBJECT_TYPE" IS
    'oracle_tools.t_schema_object.base_object_type'
>';

  execute immediate q'<
COMMENT ON COLUMN "GITHUB_INSTALLED_VERSIONS_OBJECTS"."BASE_OBJECT_SCHEMA" IS
    'oracle_tools.t_schema_object.base_object_schema'
>';

  execute immediate q'<
COMMENT ON COLUMN "GITHUB_INSTALLED_VERSIONS_OBJECTS"."BASE_OBJECT_NAME" IS
    'oracle_tools.t_schema_object.base_object_name'
>';

  execute immediate q'<
COMMENT ON COLUMN "GITHUB_INSTALLED_VERSIONS_OBJECTS"."COLUMN_NAME" IS
    'oracle_tools.t_schema_object.column_name'
>';

  execute immediate q'<
COMMENT ON COLUMN "GITHUB_INSTALLED_VERSIONS_OBJECTS"."GRANTEE" IS
    'oracle_tools.t_schema_object.grantee'
>';

  execute immediate q'<
COMMENT ON COLUMN "GITHUB_INSTALLED_VERSIONS_OBJECTS"."PRIVILEGE" IS
    'oracle_tools.t_schema_object.privilege'
>';

  execute immediate q'<
COMMENT ON COLUMN "GITHUB_INSTALLED_VERSIONS_OBJECTS"."GRANTABLE" IS
    'oracle_tools.t_schema_object.grantable'
>';

  execute immediate q'<
COMMENT ON COLUMN "GITHUB_INSTALLED_VERSIONS_OBJECTS"."CREATED" IS
    'ALL_OBJECTS.CREATED'
>';

  execute immediate q'<
COMMENT ON COLUMN "GITHUB_INSTALLED_VERSIONS_OBJECTS"."LAST_DDL_TIME" IS
    'ALL_OBJECTS.LAST_DDL_TIME'
>';

  execute immediate q'<
ALTER TABLE "GITHUB_INSTALLED_VERSIONS_OBJECTS" ADD CONSTRAINT "GITHUB_INSTALLED_VERSIONS_OBJECTS_PK" PRIMARY KEY ( "ID" )
>';

  execute immediate q'<
ALTER TABLE "GITHUB_INSTALLED_VERSIONS_OBJECTS"
    ADD CONSTRAINT "GITHUB_INSTALLED_VERSIONS_OBJECTS_UK" UNIQUE ( "GITHUB_INSTALLED_VERSIONS_ID",
                                                                   "OBJECT_TYPE",
                                                                   "OBJECT_SCHEMA",
                                                                   "OBJECT_NAME",
                                                                   "BASE_OBJECT_TYPE",
                                                                   "BASE_OBJECT_SCHEMA",
                                                                   "BASE_OBJECT_NAME",
                                                                   "COLUMN_NAME",
                                                                   "GRANTEE",
                                                                   "PRIVILEGE",
                                                                   "GRANTABLE" )
>';
                                                                   
  execute immediate q'<
ALTER TABLE "GITHUB_INSTALLED_VERSIONS_OBJECTS"
    ADD CONSTRAINT "GITHUB_INSTALLED_VERSIONS_FK" FOREIGN KEY ( "GITHUB_INSTALLED_VERSIONS_ID" )
        REFERENCES "ADMIN"."GITHUB_INSTALLED_VERSIONS" ( "ID" )
            ON DELETE CASCADE
>';

  execute immediate q'<
CREATE TRIGGER "FKNTM_GITHUB_INSTALLED_VERSIONS_OBJECTS" BEFORE
    UPDATE OF "GITHUB_INSTALLED_VERSIONS_ID" ON "GITHUB_INSTALLED_VERSIONS_OBJECTS"
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table "GITHUB_INSTALLED_VERSIONS_OBJECTS" is violated');
END;
>';

exception
  when others
  then
    -- ORA-00955: name is already used by an existing object
    if sqlcode in (-955) then null; else raise; end if;
end;
/
