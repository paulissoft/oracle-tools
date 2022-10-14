#!/bin/sh -xeu

# Script to be invoked from a Jenkins build.
# Environment variables must be set otherwise an error occurs (-eu above).

# The following variables need to be set:
# - SCM_BRANCH      
# - CONF_DIR
# - DB
# - DB_USERNAME
# - DB_PASSWORD
# - DB_DIR
# - DB_ACTIONS
# - APEX_DIR
# - APEX_ACTIONS
# - BUILD_NUMBER
# - WORKSPACE
# 
# The following variables may be set:
# - SCM_USERNAME    
# - SCM_EMAIL       
# - SCM_BRANCH_PREV
# - GIT
# - MVN
# - MVN_ARGS
# - MVN_LOG_DIR
# - APP_ENV (must be set when parallel processing)
# - APP_ENV_PREV (may be set when parallel processing)
#
# See also libraries/maven/steps/process.groovy.

# Functions:
# - init
# - invoke_mvn
# - process_git
# - process_db
# - process_apex
# - main

init() {
    oracle_tools_dir="`dirname $0`/.."

    # checking environment
    pwd

    set +eu # some variables may be unset

    ${GIT:=git} --version

    if [ -n "${SCM_USERNAME}" -a -n "${SCM_EMAIL}" ]
    then
        export GIT_SSH_COMMAND="ssh -oStrictHostKeyChecking=no"
        ${GIT} config user.name ${SCM_USERNAME}
        ${GIT} config user.email ${SCM_EMAIL}
    fi

    test -n "$SCM_BRANCH_PREV" || export SCM_BRANCH_PREV=""
    test -n "$DB_ACTIONS" || export DB_ACTIONS=""
    test -n "$APEX_ACTIONS" || export APEX_ACTIONS=""
    # equivalent of Maven 4 MAVEN_ARGS
    test -n "$MVN" || export MVN=mvn
    test -n "$MVN_ARGS" || export MVN_ARGS=""
    test -n "$APP_ENV" || export APP_ENV=""
    test -n "$APP_ENV_PREV" || export APP_ENV_PREV=""
    
    # ensure that -l $MVN_LOG_DIR by default does not exist so Maven will log to stdout
    if [ -n "$MVN_LOG_DIR" ]
    then
        if [ -d "$MVN_LOG_DIR" ]
        then
            # let MVN_LOG_DIR point to an absolute file path
            MVN_LOG_DIR=`cd ${MVN_LOG_DIR} && pwd`
        else
            echo "Maven log directory '$MVN_LOG_DIR' is not a directory." 1>&2
            exit 1
        fi
    else
        # let MVN_LOG_DIR point to a non existing directory so ${MVN} will not create the log file
        MVN_LOG_DIR=
    fi
    export MVN_LOG_DIR

    # Maven property db.password is by default the environment variable DB_PASSWORD
    if ! printenv DB_PASSWORD 1>/dev/null
    then
        echo "Environment variable DB_PASSWORD is not set." 1>&2
        exit 1
    fi

    set -xeu

    # get absolute path
    db_config_dir=`cd ${CONF_DIR} && pwd`

    db_scm_write=
    if echo "$DB_ACTIONS" | grep db-generate-ddl-full
    then
        db_scm_write=1
    fi

    apex_scm_write=
    if echo "$APEX_ACTIONS" | grep apex-export
    then
        apex_scm_write=1
    fi

    workspace="${WORKSPACE}"
    echo "APP_ENV: $APP_ENV"
    echo "APP_ENV_PREV: $APP_ENV_PREV"
}

signal_scm_ready() {
    tool=$1

    if [ -n "$APP_ENV" ]
    then
        # signal the rest of the jobs that this part is ready
        touch "${workspace}/${APP_ENV}.${tool}.scm.ready"
    fi
}

# simple implementation of a wait for file: better use iwatch / inotifywait
wait_for_scm_ready_prev() {
    tool=$1
    increment=10
    timeout=60
    elapsed=0
    
    if [ -n "$APP_ENV" -a -n "$APP_ENV_PREV" ]
    then
        scm_ready_file="${workspace}/${APP_ENV_PREV}.${tool}.scm.ready"
        while [ ! -f "$scm_ready_file" -a $elapsed -lt $timeout ]
        do
            sleep $increment
            elapsed=`expr $elapsed + $increment`
        done
        if [ ! -f "$scm_ready_file" ]
        then
            echo "Timeout after waiting $timeout seconds for file $scm_ready_file" 1>&2
            exit 1
        fi
        rm "$scm_ready_file"
    fi
}

invoke_mvn()
{
    if [ -n "$MVN_LOG_DIR" ]
    then
        mvn_log_args="-l $MVN_LOG_DIR/mvn-${2}.log"
    else
        mvn_log_args=" "
    fi
    ${MVN} -B -f ${1} -Doracle-tools.dir=${oracle_tools_dir} -Ddb.config.dir=${db_config_dir} -Ddb=${DB} -P${2} $mvn_log_args ${MVN_ARGS}
}

process_git()
{
    description=$1

    workspace_changes="`${GIT} status --porcelain`" 

    echo "workspace changes: ${workspace_changes}"
    
    if [ -n "$workspace_changes" ]
    then
        ${GIT} add --all .
        ${GIT} commit -m"${description}. Triggered Build: $BUILD_NUMBER"
    fi
    if [ "`${GIT} diff --stat=1000 --cached origin/${SCM_BRANCH} | wc -l`" -ne 0 ]
    then
        ${GIT} push --set-upstream origin ${SCM_BRANCH}
    fi
}

process_db() {
    # First DB run
    echo "processing DB actions ${DB_ACTIONS} in ${DB_DIR} with configuration directory $db_config_dir"

    set -- ${DB_ACTIONS}
    for profile; do invoke_mvn ${DB_DIR} $profile; done
    
    process_git "Database changes"
    
    # Both db-install and db-generate-ddl-full part of DB_ACTIONS?
    # If so, a second run should change nothing
    if echo $DB_ACTIONS | grep db-install && echo $DB_ACTIONS | grep db-generate-ddl-full
    then
        # Second DB run: verify that there are no changes after a second round (just install and generate DDL)
        DB_ACTIONS="db-install db-generate-ddl-full"
        echo "checking that there are no changes after a second round of ${DB_ACTIONS} (standard output is suppressed)"
        set -- ${DB_ACTIONS}
        for profile; do invoke_mvn ${DB_DIR} $profile; done
        echo "there should be no files to add for Git:"
        test -z "`${GIT} status --porcelain`"
    fi
}

process_apex() {
    echo "processing APEX actions ${APEX_ACTIONS} in ${APEX_DIR} with configuration directory $db_config_dir"

    set -- ${APEX_ACTIONS}
    for profile; do invoke_mvn ${APEX_DIR} $profile; done

    # ${APEX_DIR}/src/export/application/create_application.sql changes its p_flow_version so use ${GIT} diff --stat=1000 to verify it is just that file and that line
    # 
    # % ${GIT} diff --stat=1000
    #  apex/app/src/export/application/create_application.sql | 2 +-
    #  1 file changed, 1 insertion(+), 1 deletion(-)

    # Check if only create_application.sql files have changed their p_flow_version.
    # Be aware of a default output width of 80, so use --stat=1000
    result="`${GIT} diff --stat=1000 -- ${APEX_DIR} | awk -f $oracle_tools_dir/jenkins/only_create_application_changed.awk`"
    if [ "$result" = "YES" ]
    then
        # 1) Retrieve all create_application.sql files that have changed only in two places (one insertion, one deletion) 
        # 2) Restore them since the change is due to the version date change
        # 3) This prohibits a git commit when the APEX export has not changed really
        for create_application in "`${GIT} diff --stat=1000 -- ${APEX_DIR} | grep -E '\bcreate_application\.sql\s+\|\s+2\s+\+-$' | cut -d '|' -f 1`"
        do    
            ${GIT} checkout -- $create_application
        done
    fi

    process_git "APEX changes"
}

main() {
    init

    # signal as soon as possible both DB and APEX
    test -n "$db_scm_write" || signal_scm_ready db
    test -n "$apex_scm_write" || signal_scm_ready apex    

    wait_for_scm_ready_prev db    
    wait_for_scm_ready_prev apex

    if [ -n "$SCM_BRANCH_PREV" -a "$SCM_BRANCH_PREV" != "$SCM_BRANCH" ]
    then
        ${GIT} checkout "$SCM_BRANCH_PREV"
        ${GIT} checkout "$SCM_BRANCH"
        ${GIT} merge "$SCM_BRANCH_PREV"
    fi

    test -z "${DB_ACTIONS}" || process_db
    # inverse
    test -z "$db_scm_write" || signal_scm_ready db
    
    test -z "${APEX_ACTIONS}" || process_apex
    # inverse
    test -z "$apex_scm_write" || signal_scm_ready apex    
}

main
