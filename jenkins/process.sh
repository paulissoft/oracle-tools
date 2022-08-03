#!/bin/sh -xeu

process_git()
{
    description=$1

    workspace_changes="`git status --porcelain`" 

    echo "workspace changes: ${workspace_changes}"
    
    if [ -n "$workspace_changes" ]
    then
        git add --all .
        git commit -m"${description}. Triggered Build: $BUILD_NUMBER"
    fi
    if [ "`git diff --stat --cached origin/${SCM_BRANCH} | wc -l`" -ne 0 ]
    then
        git push --set-upstream origin ${SCM_BRANCH}
    fi
}

# Script to be invoked from a Jenkins build.
# Environment variables must be set otherwise an error occurs (-eu above).

oracle_tools_dir="`dirname $0`/.."

# checking environment
pwd
git --version

export GIT_SSH_COMMAND="ssh -oStrictHostKeyChecking=no"
git config user.name ${SCM_USERNAME}
git config user.email ${SCM_EMAIL}

set +eu # come variables may be unset

if [ -n "$SCM_BRANCH_PREV" -a "$SCM_BRANCH_PREV" != "$SCM_BRANCH" ]
then
  git checkout "$SCM_BRANCH_PREV"
  git checkout "$SCM_BRANCH"
  git merge "$SCM_BRANCH_PREV"
fi

test -n "$DB_ACTIONS" || export DB_ACTIONS=""
test -n "$APEX_ACTIONS" || export APEX_ACTIONS=""
test -n "$EXTRA_MAVEN_COMMAND_LINE_OPTIONS" || export EXTRA_MAVEN_COMMAND_LINE_OPTIONS=""
# ensure that -l $LOG_DIR by default does not exist so Maven will log to stdout
if [ -n "$LOG_DIR" -a -d "$LOG_DIR" ]
then
    # let log_dir point to an absolute file path
    log_dir=`cd ${LOG_DIR} && pwd`
else
    # let log_dir point to a non existing directory so mvn will not create the log file
    log_dir=/directory-does-not-exist
fi

echo "log_dir: ${log_dir}"

set -xeu

db_config_dir=`cd ${CONF_DIR} && pwd`

# First DB run
echo "processing DB actions ${DB_ACTIONS} in ${DB_DIR} with configuration directory $db_config_dir"
set -- ${DB_ACTIONS}
for profile; do mvn -f ${DB_DIR} -Doracle-tools.dir=$oracle_tools_dir -Ddb.config.dir=$db_config_dir -Ddb=${DB} -D$DB_USERNAME_PROPERTY=$DB_USERNAME -Ddb.password=$DB_PASSWORD -P$profile -l $log_dir/mvn-${profile}.log ${EXTRA_MAVEN_COMMAND_LINE_OPTIONS}; done
process_git "Database changes"

# Both db-install and db-generate-ddl-full part of DB_ACTIONS?
# If so, a second run should change nothing
if echo $DB_ACTIONS | grep db-install && echo $DB_ACTIONS | grep db-generate-ddl-full
then
    # Second DB run: verify that there are no changes after a second round (just install and generate DDL)
    DB_ACTIONS="db-install db-generate-ddl-full"
    echo "checking that there are no changes after a second round of ${DB_ACTIONS} (standard output is suppressed)"
    set -- ${DB_ACTIONS}
    for profile; do mvn -f ${DB_DIR} -Doracle-tools.dir=$oracle_tools_dir -Ddb.config.dir=$db_config_dir -Ddb=${DB} -D$DB_USERNAME_PROPERTY=$DB_USERNAME -Ddb.password=$DB_PASSWORD -P$profile -l mvn-${profile}.log ${EXTRA_MAVEN_COMMAND_LINE_OPTIONS}; rm mvn-${profile}.log; done
    echo "there should be no files to add for Git:"
    test -z "`git status --porcelain`"
fi

echo "processing APEX actions ${APEX_ACTIONS} in ${APEX_DIR} with configuration directory $db_config_dir"
set -- ${APEX_ACTIONS}
for profile; do mvn -f ${APEX_DIR} -Doracle-tools.dir=$oracle_tools_dir -Ddb.config.dir=$db_config_dir -Ddb=${DB} -D$DB_USERNAME_PROPERTY=$DB_USERNAME -Ddb.password=$DB_PASSWORD -P$profile -l $log_dir/mvn-${profile}.log ${EXTRA_MAVEN_COMMAND_LINE_OPTIONS}; done

# ${APEX_DIR}/src/export/application/create_application.sql changes its p_flow_version so use git diff --stat to verify it is just that file and that line
# 
# % git diff --stat
#  apex/app/src/export/application/create_application.sql | 2 +-
#  1 file changed, 1 insertion(+), 1 deletion(-)

# Check if only create_application.sql files have changed their p_flow_version.
result="`git diff --stat -- ${APEX_DIR} | awk -f $oracle_tools_dir/jenkins/only_create_application_changed.awk`"
if [ "$result" = "YES" ]
then
    # 1) Retrieve all create_application.sql files that have changed only in two places (one insertion, one deletion) 
    # 2) Restore them since the change is due to the version date change
    # 3) This prohibits a git commit when the APEX export has not changed really
    for create_application in "`git diff --stat -- ${APEX_DIR} | grep -E '\bcreate_application\.sql\s+\|\s+2\s+\+-$' | cut -d '|' -f 1`"
    do    
        git checkout -- $create_application
    done
fi

process_git "APEX changes"
