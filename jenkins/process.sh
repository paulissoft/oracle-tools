#!/bin/sh -eu

# Script to be invoked from a Jenkins build.
# Environment variables must be set otherwise an error occurs (-eu above).

oracle_tools_dir="`dirname $0`/.."

pwd
export GIT_SSH_COMMAND="ssh -oStrictHostKeyChecking=no"
git config user.name ${SCM_USERNAME}
git config user.email ${SCM_EMAIL}
if [ -n "$SCM_BRANCH_PREV" ]
then
  git checkout "$SCM_BRANCH_PREV"
  git checkout "$SCM_BRANCH"
  git merge "$SCM_BRANCH_PREV"
fi

db_config_dir=`cd ${CONF_DIR} && pwd`

# First DB run
echo "processing DB actions ${DB_ACTIONS} in ${DB_DIR} with configuration directory $db_config_dir"
set -- ${DB_ACTIONS}
for profile; do mvn -f ${DB_DIR} -Doracle-tools.dir=$oracle_tools_dir -Ddb.config.dir=$db_config_dir -Ddb=${DB} -D$DB_USERNAME_PROPERTY=$DB_USERNAME -Ddb.password=$DB_PASSWORD -P$profile; done
if [ -n "`git status --porcelain`" ]
then
  git add --all .
  git commit -m"Database changes. Triggered Build: $BUILD_NUMBER"
fi
if [ "`git diff --stat --cached origin/${SCM_BRANCH} | wc -l`" -ne 0 ]
then
  git push --set-upstream origin ${SCM_BRANCH}
fi

# Second DB run: verify that there are no changes after a second round (just install and generate DDL)
DB_ACTIONS="db-install db-generate-ddl-full"
echo "checking that there are no changes after a second round of ${DB_ACTIONS} (standard output is suppressed)"
set -- ${DB_ACTIONS}
for profile; do mvn -f ${DB_DIR} -Doracle-tools.dir=$oracle_tools_dir -Ddb.config.dir=$db_config_dir -Ddb=${DB} -D$DB_USERNAME_PROPERTY=$DB_USERNAME -Ddb.password=$DB_PASSWORD -P$profile -l mvn-${profile}.log; done
echo "there should be no files to add for Git:"
test -z "`git status --porcelain`"

echo "processing APEX actions ${APEX_ACTIONS} in ${APEX_DIR} with configuration directory $db_config_dir"
set -- ${APEX_ACTIONS}
for profile; do mvn -f ${APEX_DIR} -Doracle-tools.dir=$oracle_tools_dir -Ddb.config.dir=$db_config_dir -Ddb=${DB} -D$DB_USERNAME_PROPERTY=$DB_USERNAME -Ddb.password=$DB_PASSWORD -P$profile; done

# ${APEX_DIR}/src/export/application/create_application.sql changes its p_flow_version so use git diff --compact-summary to verify it is just that file and that line
# 
# % git diff --compact-summary                                          
#  apex/app/src/export/application/create_application.sql | 2 +-
#  1 file changed, 1 insertion(+), 1 deletion(-)

create_application=${APEX_DIR}/src/export/application/create_application.sql
# Use a little bit of awk to check that the file and its changes are matched and that the total number of lines is just 2
result="`git diff --compact-summary | awk -f $oracle_tools_dir/jenkins/only_create_application_changed.awk`"
if [ "$result" = "YES" ]
then
  git update-index --assume-unchanged    $create_application
  workspace_changed="`git status --porcelain`"
  git update-index --no-assume-unchanged $create_application
else
  workspace_changed="`git status --porcelain`"
fi

if [ -n "$workspace_changed" ]
then
  git add --all .
  git commit -m"APEX changes. Triggered Build: $BUILD_NUMBER"
fi
if [ "`git diff --stat --cached origin/${SCM_BRANCH} | wc -l`" -ne 0 ]
then
  git push --set-upstream origin ${SCM_BRANCH}
fi
