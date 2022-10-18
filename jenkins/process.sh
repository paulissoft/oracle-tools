#!/bin/sh -eux

# Script to be invoked from a Jenkins build.
# Environment variables must be set otherwise an error occurs (-eu above).

# The following variables need to be set and not empty (and should be exported):
mandatory_variables=`cat <<EOF
APEX_DIR
BUILD_NUMBER
CONF_DIR
DB
DB_DIR
SCM_BRANCH
WORKSPACE

EOF`

# Also mandatory but do not echo them
secret_mandatory_variables=`cat <<EOF
DB_PASSWORD
DB_USERNAME

EOF`

# 
# The following variables may be unset or empty (and should be exported):
optional_variables=`cat <<EOF
APEX_ACTIONS
APP_ENV
APP_ENV_PREV
DB_ACTIONS
GIT
MVN
MVN_ARGS
MVN_LOG_DIR
SCM_BRANCH_PREV
SCM_EMAIL
SCM_USERNAME

EOF`

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

    set +eux # some variables may be unset

    # Stop when variable unset
    set -- $mandatory_variables
    for v
    do
        test -n "`printenv ${v}`" || { echo "Variable ${v} not set or null" 1>&2; exit 1; }
        export $v
        echo "$v: '`printenv ${v}`'"
    done

    set -- $secret_mandatory_variables
    for v
    do
        test -n "`printenv ${v}`" || { echo "Variable ${v} not set or null" 1>&2; exit 1; }
        export $v
    done

    set -- $optional_variables
    for v
    do
        test -n "`printenv ${v}`" || eval ${v}=
        export $v
        echo "$v: '`printenv ${v}`'"
    done

    set -eux

    parallel=0
    if [ -n "$APP_ENV" ]
    then
        parallel=1
    fi

    trap 'signal_scm_ready FAIL db; signal_scm_ready FAIL apex' ERR

    db_scm_write=0
    if echo "$DB_ACTIONS" | grep db-generate-ddl-full
    then
        db_scm_write=1
    fi

    apex_scm_write=0
    if echo "$APEX_ACTIONS" | grep apex-export
    then
        apex_scm_write=1
    fi

    # set some defaults
    test -n "${GIT}" || GIT=git
    test -n "${MVN}" || MVN=mvn
    
    $GIT --version
    $MVN -B --version

    if [ -n "${SCM_USERNAME}" -a -n "${SCM_EMAIL}" ]
    then
        export GIT_SSH_COMMAND="ssh -oStrictHostKeyChecking=no"
        ${GIT} config user.name ${SCM_USERNAME}
        ${GIT} config user.email ${SCM_EMAIL}
    fi

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

    # get absolute path
    db_config_dir=`cd ${CONF_DIR} && pwd`
}

signal_scm_ready() {
    status=$1
    tool=$2

    if [ -n "$APP_ENV" ]
    then
        # signal the rest of the jobs that this part is ready
        echo $status > "${WORKSPACE}/${APP_ENV}.${tool}.scm.ready"

        # change trap only when status is OK
        if [ $status = 'OK' ]
        then
            if [ $tool = 'db' ]
            then
                trap 'signal_scm_ready FAIL apex' ERR
            else
                # clear all
                trap - ERR
            fi
        fi
    fi
}

# simple implementation of a wait for file: better use iwatch / inotifywait
wait_for_scm_ready_prev() {    
    if [ -n "$APP_ENV" -a -n "$APP_ENV_PREV" ]
    then
        tool=$1
        export SCM_READY_FILE="${WORKSPACE}/${APP_ENV_PREV}.${tool}.scm.ready"
        export INCREMENT=10
        timeout=3600

        perl ${oracle_tools_dir}/src/scripts/timeout.pl -t $timeout sh -xc 'while [ ! -f "$SCM_READY_FILE" ]; do sleep $INCREMENT; done'

        if [ ! -f "$SCM_READY_FILE" ]
        then
            # Should never come here due to timeout.pl script but it does not hurt neither
            echo "Timeout after waiting $timeout seconds for file $SCM_READY_FILE" 1>&2
            exit 1
        fi
        status=`cat $SCM_READY_FILE`
        rm -f "$SCM_READY_FILE"
        test "$status" = 'OK' || { echo "Process that wrote $SCM_READY_FILE failed with status '$status'" 1>&2; exit 1 }
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

    if [ "$parallel" -ne 0 ]
    then
        # signal as soon as possible both DB and APEX
        test "$db_scm_write" -ne 0 || signal_scm_ready OK db
        test "$apex_scm_write" -ne 0 || signal_scm_ready OK apex

        wait_for_scm_ready_prev db    
        wait_for_scm_ready_prev apex
    fi

    if [ -n "$SCM_BRANCH_PREV" -a "$SCM_BRANCH_PREV" != "$SCM_BRANCH" ]
    then
        ${GIT} checkout "$SCM_BRANCH_PREV"
        ${GIT} checkout "$SCM_BRANCH"
        ${GIT} merge "$SCM_BRANCH_PREV"
    fi

    test -z "${DB_ACTIONS}" || process_db
    # inverse
    test "$parallel" -eq 0 || test "$db_scm_write" -eq 0 || signal_scm_ready OK db
    
    test -z "${APEX_ACTIONS}" || process_apex
    # inverse
    test "$parallel" -eq 0 || test "$apex_scm_write" -eq 0 || signal_scm_ready OK apex    
}

main
