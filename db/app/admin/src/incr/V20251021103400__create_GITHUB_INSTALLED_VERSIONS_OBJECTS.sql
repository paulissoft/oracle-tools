declare
begin
  execute immediate q'<
CREATE TABLE "GITHUB_INSTALLED_VERSIONS_OBJECTS" (
    "GITHUB_INSTALLED_VERSIONS_ID" INTEGER
        CONSTRAINT "NNC_GITHUB_INSTALLED_VERSIONS_OBJECTS_GITHUB_INSTALLED_VERSIONS_ID" NOT NULL,
    "OBJECT_TYPE"                  VARCHAR2(23)
        CONSTRAINT "NNC_GITHUB_INSTALLED_VERSIONS_OBJECTS_OBJECT_TYPE" NOT NULL,
    "OBJECT_NAME"                  VARCHAR2(128)
        CONSTRAINT "NNC_GITHUB_INSTALLED_VERSIONS_OBJECTS_OBJECT_NAME" NOT NULL,
    "LAST_DDL_TIME"                DATE
        CONSTRAINT "NNC_GITHUB_INSTALLED_VERSIONS_OBJECTS_LAST_DDL_TIME" NOT NULL
)
LOGGING
>';

  execute immediate q'<
COMMENT ON TABLE "GITHUB_INSTALLED_VERSIONS_OBJECTS" IS
    'GitHub installed versions objects. Used to determine whether at least one of the objects has changed since the installation date.'
>';
    
  execute immediate q'<
COMMENT ON COLUMN "GITHUB_INSTALLED_VERSIONS_OBJECTS"."OBJECT_TYPE" IS
    'ALL_OBJECTS.OBJECT_TYPE'
>';
   
  execute immediate q'<
COMMENT ON COLUMN "GITHUB_INSTALLED_VERSIONS_OBJECTS"."OBJECT_NAME" IS
    'ALL_OBJECTS.OBJECT_NAME'
>';

  execute immediate q'<
COMMENT ON COLUMN "GITHUB_INSTALLED_VERSIONS_OBJECTS"."LAST_DDL_TIME" IS
    'ALL_OBJECTS.LAST_DDL_TIME'
>';

  execute immediate q'<
ALTER TABLE "GITHUB_INSTALLED_VERSIONS_OBJECTS"
    ADD CONSTRAINT "GITHUB_INSTALLED_VERSIONS_OBJECTS_PK" PRIMARY KEY ( "GITHUB_INSTALLED_VERSIONS_ID",
                                                                        "OBJECT_TYPE",
                                                                        "OBJECT_NAME" )
>';
                                                                       
  execute immediate q'<
ALTER TABLE "GITHUB_INSTALLED_VERSIONS_OBJECTS"
    ADD CONSTRAINT "GITHUB_INSTALLED_VERSIONS_FK" FOREIGN KEY ( "GITHUB_INSTALLED_VERSIONS_ID" )
        REFERENCES "ADMIN"."GITHUB_INSTALLED_VERSIONS" ( "ID" )
    NOT DEFERRABLE
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
