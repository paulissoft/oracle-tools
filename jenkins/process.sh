#!/bin/sh -xeu

# The following variables need to be set:
# - SCM_BRANCH      
# - SCM_CREDENTIALS 
# - SCM_URL         
# - SCM_USERNAME    
# - SCM_EMAIL       
# - CONF_DIR
# - DB
# - DB_USERNAME
# - DB_PASSWORD
# - DB_DIR
# - DB_ACTIONS
# - APEX_DIR
# - APEX_ACTIONS
# 
# The following variables may be set:
# - SCM_BRANCH_PREV
#
# See also libraries/maven/steps/process.groovy.

check_username()
{
    dir=$1
    
    username=$(mvn -f ${dir} -Doracle-tools.dir=$oracle_tools_dir -Ddb.config.dir=$db_config_dir -N help:all-profiles -Pconf-inquiry compile || grep -E '\[echoproperties\] db(.proxy)?.username=' | cut -d '=' -f 2)
    if [ "$DB_USERNAME" != "$username" ]
    then
        echo "The POM in ${dir} says that username equals to '$username' and Jenkins says it equals to '$DB_USERNAME'" 1>&2
        exit 1
    fi
}

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
    if [ "`git diff --stat=1000 --cached origin/${SCM_BRANCH} | wc -l`" -ne 0 ]
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

set +eu # some variables may be unset

if [ -n "$SCM_BRANCH_PREV" -a "$SCM_BRANCH_PREV" != "$SCM_BRANCH" ]
then
  git checkout "$SCM_BRANCH_PREV"
  git checkout "$SCM_BRANCH"
  git merge "$SCM_BRANCH_PREV"
fi

test -n "$DB_ACTIONS" || export DB_ACTIONS=""
test -n "$APEX_ACTIONS" || export APEX_ACTIONS=""
# equivalent of Maven 4 MAVEN_ARGS
test -n "$MVN_ARGS" || export MVN_ARGS=""

# ensure that -l $MVN_LOG_DIR by default does not exist so Maven will log to stdout
if [ -n "$MVN_LOG_DIR" -a -d "$MVN_LOG_DIR" ]
then
    # let MVN_LOG_DIR point to an absolute file path
    MVN_LOG_DIR=`cd ${MVN_LOG_DIR} && pwd`
else
    # let MVN_LOG_DIR point to a non existing directory so mvn will not create the log file
    MVN_LOG_DIR=/directory-does-not-exist
fi
export MVN_LOG_DIR

# Maven property db.password is by default the environment variable DB_PASSWORD
if ! printenv DB_PASSWORD 1>/dev/null
then
    echo "Environment variable DB_PASSWORD is not set." 1>&2
    exit 1
fi

set -xeu

db_config_dir=`cd ${CONF_DIR} && pwd`

# First DB run
echo "processing DB actions ${DB_ACTIONS} in ${DB_DIR} with configuration directory $db_config_dir"
test -z "$DB_ACTIONS" || check_username "$DB_DIR"
set -- ${DB_ACTIONS}
for profile; do mvn -f ${DB_DIR} -Doracle-tools.dir=$oracle_tools_dir -Ddb.config.dir=$db_config_dir -Ddb=${DB} -P$profile -l $MVN_LOG_DIR/mvn-${profile}.log ${MVN_ARGS}; done
process_git "Database changes"

# Both db-install and db-generate-ddl-full part of DB_ACTIONS?
# If so, a second run should change nothing
if echo $DB_ACTIONS | grep db-install && echo $DB_ACTIONS | grep db-generate-ddl-full
then
    # Second DB run: verify that there are no changes after a second round (just install and generate DDL)
    DB_ACTIONS="db-install db-generate-ddl-full"
    echo "checking that there are no changes after a second round of ${DB_ACTIONS} (standard output is suppressed)"
    set -- ${DB_ACTIONS}
    for profile; do mvn -f ${DB_DIR} -Doracle-tools.dir=$oracle_tools_dir -Ddb.config.dir=$db_config_dir -Ddb=${DB} -P$profile -l mvn-${profile}.log ${MVN_ARGS}; rm mvn-${profile}.log; done
    echo "there should be no files to add for Git:"
    test -z "`git status --porcelain`"
fi

echo "processing APEX actions ${APEX_ACTIONS} in ${APEX_DIR} with configuration directory $db_config_dir"
test -z "$APEX_ACTIONS" || check_username "$APEX_DIR"
set -- ${APEX_ACTIONS}
for profile; do mvn -f ${APEX_DIR} -Doracle-tools.dir=$oracle_tools_dir -Ddb.config.dir=$db_config_dir -Ddb=${DB} -P$profile -l $MVN_LOG_DIR/mvn-${profile}.log ${MVN_ARGS}; done

# ${APEX_DIR}/src/export/application/create_application.sql changes its p_flow_version so use git diff --stat=1000 to verify it is just that file and that line
# 
# % git diff --stat=1000
#  apex/app/src/export/application/create_application.sql | 2 +-
#  1 file changed, 1 insertion(+), 1 deletion(-)

# Check if only create_application.sql files have changed their p_flow_version.
# Be aware of a default output width of 80, so use --stat=1000
result="`git diff --stat=1000 -- ${APEX_DIR} | awk -f $oracle_tools_dir/jenkins/only_create_application_changed.awk`"
if [ "$result" = "YES" ]
then
    # 1) Retrieve all create_application.sql files that have changed only in two places (one insertion, one deletion) 
    # 2) Restore them since the change is due to the version date change
    # 3) This prohibits a git commit when the APEX export has not changed really
    for create_application in "`git diff --stat=1000 -- ${APEX_DIR} | grep -E '\bcreate_application\.sql\s+\|\s+2\s+\+-$' | cut -d '|' -f 1`"
    do    
        git checkout -- $create_application
    done
fi

process_git "APEX changes"
