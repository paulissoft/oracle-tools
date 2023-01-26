#!/usr/bin/env bash

set -eu

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
DB_ACTIONS
GIT
MVN
MVN_ARGS
MVN_LOG_DIR
SCM_BRANCH_PREV
SCM_EMAIL
SCM_USERNAME

EOF`

# The following variables may be unset or empty (and should be exported):
parallel_variables=`cat <<EOF
APEX_ACTIONS_PREV
APP_ENV
APP_ENV_PREV
DB_ACTIONS_PREV

EOF`

#
# See also libraries/maven/steps/process.groovy.

# Functions:
# - x
# - init
# - invoke_mvn
# - process_git
# - process_db
# - process_apex
# - main


# start a subshell to set -x and run the command
function x() { (set -x; "$@") } 

init() {
    oracle_tools_dir="`dirname $0`/.."
    parallel=0
    db_scm_write_prev=0
    db_scm_write=0
    apex_scm_write_prev=0
    apex_scm_write=0

    # checking environment
    pwd

    set +eu # some variables may be unset

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

    set -- $optional_variables $parallel_variables
    for v
    do
        test -n "`printenv ${v}`" || eval ${v}=
        export $v
        echo "$v: '`printenv ${v}`'"
    done

    set -eu

    if [ -n "$APP_ENV" ]
    then
        parallel=1

        # Does the previous application environment write to Git after its db actions?
        if echo "$DB_ACTIONS_PREV" | grep db-generate-ddl-full
        then
            db_scm_write_prev=1
        fi

        # Does the current application environment write to Git after its db actions?
        if echo "$DB_ACTIONS" | grep db-generate-ddl-full
        then
            db_scm_write=1
        fi

        # Does the previous application environment write to Git after its APEX actions?
        if echo "$APEX_ACTIONS_PREV" | grep apex-export
        then
            apex_scm_write_prev=1
        fi

        # Does the current application environment write to Git after its APEX actions?
        if echo "$APEX_ACTIONS" | grep apex-export
        then
            apex_scm_write=1
        fi
    fi

    # set some defaults
    test -n "${GIT}" || GIT=git
    test -n "${MVN}" || MVN=mvn
    
    $GIT --version
    $MVN -B --version

    if [ -n "${SCM_USERNAME}" -a -n "${SCM_EMAIL}" ]
    then
        export GIT_SSH_COMMAND="ssh -oStrictHostKeyChecking=no"
        x ${GIT} config user.name ${SCM_USERNAME}
        x ${GIT} config user.email ${SCM_EMAIL}
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

    trap 'echo "EXIT; status: $?"' EXIT
    trap 'echo "ERR; status: $?"' ERR
}

signal_scm_ready() {
    if [ -n "$APP_ENV" ]
    then
        declare -r status=$1
        declare -r tool=$2
        declare -r scm_ready_file="${WORKSPACE}/${APP_ENV}.${tool}.scm.ready"

        # signal the rest of the jobs that this part is ready
        echo $status > $scm_ready_file
        echo "pwd: `pwd`"
        echo "scm_ready_file: $scm_ready_file"
        ls -l ${WORKSPACE}
    fi
}

# simple implementation of a wait for file: better use iwatch / inotifywait?
wait_for_scm_ready_prev() {    
    if [ -n "$APP_ENV" -a -n "$APP_ENV_PREV" ]
    then
        declare -r tool=$1        
        declare -r scm_ready_file="${WORKSPACE}/${APP_ENV_PREV}.${tool}.scm.ready"
        declare -r increment=10
        declare -r timeout=3600

        echo "pwd: `pwd`"
        echo "scm_ready_file: $scm_ready_file"
        x perl ${oracle_tools_dir}/src/scripts/timeout.pl -t $timeout sh -xc "while [ ! -f $scm_ready_file ]; do sleep $increment; date; ls -l ${WORKSPACE}; done"

        if [ ! -f "$scm_ready_file" ]
        then
            # Should never come here due to timeout.pl script but it does not hurt neither
            echo "Timeout after waiting $timeout seconds for file $scm_ready_file" 1>&2
            exit 1
        fi

        declare -r status=`cat $scm_ready_file`

        rm -f "$scm_ready_file"
        test "$status" = 'OK' || { echo "Process that wrote $scm_ready_file failed with status '$status'" 1>&2; exit 1; }
    fi
}

invoke_mvn()
{
    declare -r dir=$1
    declare -r profile=$2
    declare -r tool=$3
    
    if [ -n "$MVN_LOG_DIR" ]
    then
        mvn_log_args="-l $MVN_LOG_DIR/mvn-${profile}.log"
    else
        mvn_log_args=" "
    fi

    # disable error checking to catch the mvn error status
    set +e

    x ${MVN} -B -f ${dir} -Doracle-tools.dir=${oracle_tools_dir} -Ddb.config.dir=${db_config_dir} -Ddb=${DB} -P${profile} $mvn_log_args ${MVN_ARGS}

    declare -r status=$?

    # enable error checking
    set -e
    if [ $status -ne 0 ]
    then
        case $tool in
            db)
                # APEX comes always after db so we need to signal that scm is ready for APEX too
                test $db_scm_write -eq 0 || x signal_scm_ready FAIL db
                test $apex_scm_write -eq 0 || x signal_scm_ready FAIL apex
                ;;
            apex)
                # APEX comes always after db so there is no need to signal scm ready for db (should have been already)
                test $apex_scm_write -eq 0 || x signal_scm_ready FAIL apex
                ;;
        esac
        exit $status
    fi
}

process_git()
{
    declare -r description=$1
    declare -r workspace_changes="`${GIT} status --porcelain`" 

    echo "workspace changes: ${workspace_changes}"
    
    if [ -n "$workspace_changes" ]
    then
        x ${GIT} add --all .
        x ${GIT} commit -m"${description}. Triggered Build: $BUILD_NUMBER"
    fi
    if [ "`${GIT} diff --stat=1000 --cached origin/${SCM_BRANCH} | wc -l`" -ne 0 ]
    then
        x ${GIT} push --set-upstream origin ${SCM_BRANCH}
    fi
}

process_db() {
    # First DB run
    echo "processing DB actions ${DB_ACTIONS} in ${DB_DIR} with configuration directory $db_config_dir"

    set -- ${DB_ACTIONS}
    for profile; do invoke_mvn ${DB_DIR} $profile db; done
    
    process_git "Database changes"
    
    # Both db-install and db-generate-ddl-full part of DB_ACTIONS?
    # If so, a second run should change nothing
    if echo $DB_ACTIONS | grep db-install && echo $DB_ACTIONS | grep db-generate-ddl-full
    then
        # Second DB run: verify that there are no changes after a second round (just install and generate DDL)
        DB_ACTIONS="db-install db-generate-ddl-full"
        echo "checking that there are no changes after a second round of ${DB_ACTIONS} (standard output is suppressed)"
        set -- ${DB_ACTIONS}
        for profile; do invoke_mvn ${DB_DIR} $profile db; done
        echo "there should be no files to add for Git:"
        test -z "`${GIT} status --porcelain`"
    fi
}

process_apex() {
    echo "processing APEX actions ${APEX_ACTIONS} in ${APEX_DIR} with configuration directory $db_config_dir"

    set -- ${APEX_ACTIONS}
    for profile; do invoke_mvn ${APEX_DIR} $profile apex; done

    # ${APEX_DIR}/src/export/application/create_application.sql changes its p_flow_version so use ${GIT} diff --stat=1000 to verify it is just that file and that line
    # 
    # % ${GIT} diff --stat=1000
    #  apex/app/src/export/application/create_application.sql | 2 +-
    #  1 file changed, 1 insertion(+), 1 deletion(-)

    # Check if only create_application.sql files have changed their p_flow_version.
    # Be aware of a default output width of 80, so use --stat=1000
    declare -r result="`${GIT} diff --stat=1000 -- ${APEX_DIR} | awk -f $oracle_tools_dir/jenkins/only_create_application_changed.awk`"
    
    if [ "$result" = "YES" ]
    then
        # 1) Retrieve all create_application.sql files that have changed only in two places (one insertion, one deletion) 
        # 2) Restore them since the change is due to the version date change
        # 3) This prohibits a git commit when the APEX export has not changed really
        for create_application in "`${GIT} diff --stat=1000 -- ${APEX_DIR} | grep -E '\bcreate_application\.sql\s+\|\s+2\s+\+-$' | cut -d '|' -f 1`"
        do    
            x ${GIT} checkout -- $create_application
        done
    fi

    process_git "APEX changes"
}

main() {
    init

    if [ "$parallel" -ne 0 ]
    then
        # signal as soon as possible both DB and APEX
        test "$db_scm_write" -ne 0 || x signal_scm_ready OK db
        test "$apex_scm_write" -ne 0 || x signal_scm_ready OK apex

        test "$db_scm_write_prev" -eq 0 || x wait_for_scm_ready_prev db    
        test "$apex_scm_write_prev" -eq 0 || x wait_for_scm_ready_prev apex
    fi

    if [ -n "$SCM_BRANCH_PREV" -a "$SCM_BRANCH_PREV" != "$SCM_BRANCH" ]
    then
        # GJP 2023-01-26 https://github.com/paulissoft/oracle-tools/issues/111
        x ${GIT} config pull.ff only
        x ${GIT} pull origin "$SCM_BRANCH_PREV"
        x ${GIT} pull origin "$SCM_BRANCH"
        x ${GIT} checkout "$SCM_BRANCH_PREV"
        x ${GIT} checkout "$SCM_BRANCH"
        x ${GIT} merge "$SCM_BRANCH_PREV"
    fi

    test -z "${DB_ACTIONS}" || process_db
    # inverse
    test "$parallel" -eq 0 || test "$db_scm_write" -eq 0 || x signal_scm_ready OK db
    
    test -z "${APEX_ACTIONS}" || process_apex
    # inverse
    test "$parallel" -eq 0 || test "$apex_scm_write" -eq 0 || x signal_scm_ready OK apex    
}

main
