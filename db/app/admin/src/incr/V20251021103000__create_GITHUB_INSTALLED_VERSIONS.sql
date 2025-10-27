begin
  execute immediate q'<
CREATE SEQUENCE "ADMIN"."GITHUB_INSTALLED_VERSIONS_SEQ" START WITH 1 NOCACHE ORDER
>';
exception
  when others
  then
    -- ORA-00955: name is already used by an existing object
    if sqlcode in (-955) then null; else raise; end if;  
end;
/

begin
  execute immediate q'<
CREATE TABLE "ADMIN"."GITHUB_INSTALLED_VERSIONS" (
    "ID"                           INTEGER DEFAULT ON NULL "ADMIN"."GITHUB_INSTALLED_VERSIONS_SEQ".nextval
        CONSTRAINT "NNC_GITHUB_INSTALLED_VERSIONS_ID" NOT NULL,
    "GITHUB_INSTALLED_PROJECTS_ID" NUMBER
        CONSTRAINT "NNC_GITHUB_INSTALLED_VERSIONS_GITHUB_INSTALLED_PROJECTS_ID" NOT NULL,
    "BASE_NAME"                    VARCHAR2(4000 BYTE)
        CONSTRAINT "NNC_GITHUB_INSTALLED_VERSIONS_BASE_NAME" NOT NULL,
    "DATE_CREATED"                 DATE
        CONSTRAINT "NNC_GITHUB_INSTALLED_VERSIONS_DATE_CREATED" NOT NULL,
    "CHECKSUM"                     VARCHAR2(128)
        CONSTRAINT "NNC_GITHUB_INSTALLED_VERSIONS_CHECKSUM" NOT NULL,
    "BYTES"                        INTEGER
        CONSTRAINT "NNC_GITHUB_INSTALLED_VERSIONS_BYTES" NOT NULL,
    "ERROR_MSG"                    VARCHAR2(4000 BYTE)
)
>';
exception
  when others
  then
    -- ORA-00955: name is already used by an existing object
    if sqlcode in (-955) then null; else raise; end if;  
end;
/

begin
  execute immediate q'<
ALTER TABLE "ADMIN"."GITHUB_INSTALLED_VERSIONS" ADD CONSTRAINT "CK_GITHUB_INSTALLED_VERSIONS_BYTES" CHECK ( "BYTES" >= 0 )
>';
exception
  when others
  then
    -- ORA-02264: name already used by an existing constraint
    if sqlcode in (-2264) then null; else raise; end if;  
end;
/

begin
  execute immediate q'<
COMMENT ON COLUMN "ADMIN"."GITHUB_INSTALLED_VERSIONS"."ERROR_MSG" IS
    'The SQLERRM message if there is an error.'
>';
end;
/

begin
  execute immediate q'<
COMMENT ON TABLE "ADMIN"."GITHUB_INSTALLED_VERSIONS" IS
    'GitHub installation history.'
>';
end;
/

begin
  execute immediate q'<
ALTER TABLE "ADMIN"."GITHUB_INSTALLED_VERSIONS" ADD CONSTRAINT "GITHUB_INSTALLED_VERSIONS_PK" PRIMARY KEY ( "ID" )
>';
exception
  when others
  then
    -- ORA-02260: table can have only one primary key
    if sqlcode in (-2260) then null; else raise; end if;  
end;
/

begin
  execute immediate q'<
ALTER TABLE "ADMIN"."GITHUB_INSTALLED_VERSIONS"
    ADD CONSTRAINT "GITHUB_INSTALLED_VERSIONS_UK" UNIQUE ( "GITHUB_INSTALLED_PROJECTS_ID",
                                                           "BASE_NAME",
                                                           "DATE_CREATED" )
>';
exception
  when others
  then
    -- ORA-02261: such unique or primary key already exists in the table
    if sqlcode in (-2261) then null; else raise; end if;  
end;
/

begin                                                           
  execute immediate q'<
ALTER TABLE "ADMIN"."GITHUB_INSTALLED_VERSIONS"
    ADD CONSTRAINT "GITHUB_INSTALLED_PROJECTS_FK" FOREIGN KEY ( "GITHUB_INSTALLED_PROJECTS_ID" )
        REFERENCES "ADMIN"."GITHUB_INSTALLED_PROJECTS" ( "ID" )
            ON DELETE CASCADE
>';
exception
  when others
  then
    -- ORA-02275: such a referential constraint already exists in the table
    if sqlcode in (-2275) then null; else raise; end if;  
end;
/

begin
  execute immediate q'<
CREATE TRIGGER "ADMIN"."FKNTM_GITHUB_INSTALLED_VERSIONS" BEFORE
    UPDATE OF "GITHUB_INSTALLED_PROJECTS_ID" ON "ADMIN"."GITHUB_INSTALLED_VERSIONS"
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table "ADMIN"."GITHUB_INSTALLED_VERSIONS" is violated');
END;
>';
exception
  when others
  then
    -- ORA-04081: trigger 'FKNTM_GITHUB_INSTALLED_VERSIONS' already exists
    if sqlcode in (-4081) then null; else raise; end if;
end;
/
