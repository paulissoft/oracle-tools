begin
  execute immediate q'<
ALTER TABLE "ADMIN"."GITHUB_INSTALLED_PROJECTS" DROP CONSTRAINT "GITHUB_INSTALLED_PROJECTS_UK" CASCADE
>';

  execute immediate q'<
ALTER TABLE "ADMIN"."GITHUB_INSTALLED_PROJECTS"
    ADD CONSTRAINT "GITHUB_INSTALLED_PROJECTS_UK" UNIQUE ( "GITHUB_REPO",
                                                           "DIRECTORY_NAME",
                                                           "OWNER" )
>';
end;
/
