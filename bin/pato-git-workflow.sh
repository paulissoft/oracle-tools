#!/usr/bin/env bash

usage() {
    declare -r exit_status=${1:-0}
    
    cat <<EOF | more

USAGE
=====
$0 <COMMAND> [ <OPTIONS> ]

Git workflow based on a LOCAL and CLEAN repository workspace.

You can debug what is going by setting environment variable DEBUG.

You can have a (kind of a) dry run by setting environment variable DRY_RUN.
In this case "set -nv" will be used (enable syntax checking and verbosity).

COMMAND
=======
These are the options:
- info
- clean (workspace)
- copy (from/to a branch)
- merge (from/to a branch)
- merge_abort
- release (from lowest to highest protected branch)


info
----
Show information about the workspace:
- git status
- git remote -v


clean
-----
The workspace will be cleaned (Git will use file(s) .gitignore for that),
but you will decide what to clean interactively.
The Git command used is: "git clean -d -x -i".


copy <from> <to>
----------------
The branch to copy must not be protected.
When the branch to copy does NOT exist, the Git command will be "git checkout -b <to> <from>".
When the branch exists: "git switch <to> && git reset --hard <from>".
In both cases, the <to> branch will be the current branch ("git switch <to>").


merge <from> <to> <git merge options>
-------------------------------------
First make <from> up to date with respect to <to>, i.e. merge <to> into <from>.
Next switch back to <to> and:
- merge <from> into <to> using the <git merge options> (not a protected branch) OR
- create a Pull Request (PR)

A PR will be used withe appropiate tooling:
- GitHub command line client "gh" OR
- Azure DevOps command line client "az"

You need to install the client first.


merge_abort
-----------
Issues "git merge --abort".


release <protected_branch_1> <protected_branch_2> ... <protected_branch_N>
--------------------------------------------------------------------------
All branches must be protected.

The branch <protected_branch_1> will usually be 'development',
<protected_branch_2> 'acceptance' and
 <protected_branch_3> 'main' or 'master' (N = 3).

This is a prompted workflow, meaning that at every step the user is asked to do something.

While executing the release command steps, a release state file is updated
so you restart from where you left in case of an error (or quitting from your side).
This file is located in the \`target\` folder and starts with \`pato-git-workflow\`.

These are the steps:
0. Each branch <protected_branch_n> will be copied to export/<protected_branch_n> and
   the user will be asked to create an export using the PATO GUI (export APEX and generate DDL).
   This is a safety measure that is MANDATORY.
1. Next, branch <protected_branch_1> may need to be installed first to ensure that all
   development stuff is correctly installed from feature branches.
   A database install (with the PATO GUI) is needed in ANOTHER SESSION.
2. Next every branch n will be released to release/<protected_branch_n>-<protected_branch_m> (m = n+1):
   a. using the copy command first, see above (no user action needed):
      the first release branch will copy from the modified <protected_branch_1> (due to the database install in step 1),
      the rest from export/<protected_branch_n> (n > 1)
   b. export APEX and/or database (generate DDL) next (for branch/environment <protected_branch_1> only)
      using the PATO GUI (user action in ANOTHER SESSION)
   c. pushing the changes back to the GitHub repo (no user action needed)
3. Next every release branch (release/<protected_branch_n>-<protected_branch_m>) is merged into <protected_branch_m> (m = n+1):
   - by using the merge strategy 'ours', effectively replacing branch <protected_branch_m> (but keeping history)
   - the resulting branch will be tagged with "\`basename \$0 .sh\`-\`date -I\`" (for example pato-git-workflow-2025-03-04)
4. Now every protected branch has the new code, so just install the branches m, 1 < m <= N.
   Please note that branch 1 has already been installed.


ENVIRONMENT VARIABLES
=====================

These environment variables can be set from the outside:
- DEBUG
- DRY_RUN
- PROTECTED_BRANCHES


DEBUG
-----
When set, the script will issue "set -x".


DRY_RUN
-------
When set, the script will issue "set -nv".


PROTECTED_BRANCHES
------------------
Defaults to "development test acceptance main master".


USE CASES
=========

feature development
-------------------
Say you want to develop a feature branch "feature/PF-1234" from branch "development".
You do your stuff, but in the meanwhile someone else has merged back his work into "development",
so your feature branch is not up to date anymore.

These are your workflow actions:
1. pato-git-workflow.sh copy development feature/PF-1234
2. # do your thing, commit and push feature/PF-1234 (current branch) to the remote repository
3. pato-git-workflow.sh merge feature/PF-1234 development --squash

The latter step will first make your feature branch up to date.


export
------
Say you want to make a DDL export from the development database.
You have the branch "development" for the status of the development database,
but you want to store the export in branch "export/development" and
later create a Pull Request from "export/development" to "development".
In case of merge conflicts you want to keep the latest changes (ours).

These are your workflow actions:
1. pato-git-workflow.sh copy development export/development
2. # do your export, commit and push export/development (current branch) to the remote repository
3. pato-git-workflow.sh merge export/development development -X ours


alias
-----
Since you do not like to type in more than needed, you can make an alias in your shell source script:

  alias pgw='~/dev/oracle-tools/bin/pato-git-workflow.sh'

Now you can just type pgw.

The export from development and merging it back into development from above
can now be written as (provided variable r is a repo and you are in folder ~/dev):

  set -e
  cd \$r; b=development
  pgw copy \$b export/\$b
  cd ../pato-gui
  pato-gui ../\$r/db/pom.xml
  pato-gui ../\$r/apex/pom.xml
  cd ../\$r
  pgw merge export/\$b \$b -X ours

alias pato-gui:

  pato-gui='sdk use java 17.0.9-sem && mamba run -n pato-gui pato-gui'

alias pgw;

  pgw='~/dev/oracle-tools/bin/pato-git-workflow.sh'

EOF
    exit $exit_status
}

_info() {
    echo ""
    for msg in "$@"
    do
        echo "INFO: $msg" 1>&2
    done
    echo ""
}

_error() {
    echo ""
    echo "ERROR: $*" 1>&2
    echo ""
}

# start a subshell to set -x and run the command
_x() { (echo ""; set -x; "$@") } 

export -f _x

# to be used with 'eval COMMAND $ignore_stdout'
export ignore_stdout='1>/dev/null'
export ignore_stderr='2>/dev/null'
export ignore_output='1>/dev/null 2>&1'

! printenv DEBUG 1>/dev/null 2>&1 || { ignore_stdout=; ignore_stderr=; ignore_output=; }

_ignore_stdout() { eval "$@" $ignore_stdout; }
_ignore_stderr() { eval "$@" $ignore_stderr; }
_ignore_output() { eval "$@" $ignore_output; }

export -f _ignore_stdout _ignore_stderr _ignore_output

[[ -n "${PROTECTED_BRANCHES:-}" ]] || PROTECTED_BRANCHES="development test acceptance main master"
export PROTECTED_BRANCHES

_prompt() {
    declare -r msg=${1:?}
    
    echo ""
    read -p "PROMPT: $msg. Press RETURN when ready..." dummy
}

_error_branch_protected() {
    declare -r branch=${1:?}
    
    _error "Branch $branch is protected (i.e. one of $(echo ${PROTECTED_BRANCHES} | sed 's/ /,/g'))"
    exit 1
}

_error_branch_not_protected() {
    declare -r branch=${1:?}
    
    _error "Branch $branch is NOT protected (i.e. one of $(echo ${PROTECTED_BRANCHES} | sed 's/ /,/g'))"
    exit 1
}

_check_branch_not_protected() {
    declare -r branch=${1:?}

    echo " ${PROTECTED_BRANCHES} " | grep -q " $branch "
    [[ $? -eq 0 ]] && return 1 || return 0
}

_current_branch() {
    git rev-parse --abbrev-ref HEAD
}

_get_upstream() {
    declare -r branch=${1:-}
    declare -r current_branch=$(_current_branch)
    
    if [ -n "$branch" -a "$current_branch" != "$branch" ]
    then
        git switch $branch 1>/dev/null
        git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null
        git switch $current_branch 1>/dev/null
    else
        git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null
    fi
}   

_error_upstream_does_not_exist() {
    declare -r branch=${1:?}
    
    _error "Branch $branch does not have an upstream"
    exit 1
}

_check_upstream_exists() {
    declare -r branch=${1:?}
    declare -r upstream=$(_get_upstream $branch)

    [[ -n "$upstream" ]]
}

_check_no_changes() {
    [[ -z "$(git status --porcelain)" ]] || { _error "You have changes in your workspace"; git status; exit 1; }
}

_switch() {
    declare -r branch=${1:?}
    
    _x git switch $branch
    _x git pull || _x git branch --set-upstream-to=origin/$branch $branch
}

_tag() {
    declare -r branch=${1:?}
    declare -r tag="`basename $0 .sh`-`date -I`-${branch}"
    
    _x git tag $tag
}

_pull_request() {
    declare -r from=${1:?}
    declare -r to=${2:?}

    if `git remote -v | grep github 1>/dev/null`
    then
        if _x gh pr create --title "$from => $to" --editor --head $from --base $to
        then
            _x gh pr view --web $from
        else
            _prompt "Something went wrong"
        fi
    elif `git remote -v | grep azure 1>/dev/null`
    then
        _x az repos pr create \
          --auto-complete false \
          --bypass-policy false \
          --delete-source-branch true \
          --detect true \
          --draft false \
          --open \
          --source-branch $from \
          --squash true \
          --target-branch $to \
          --title "$from => $to"
    else
        _error "There is no GitHub nor Azure \"git remote -v\" info available."
        exit 1
    fi

    _switch $to
}

info() {    
    # _info "Current branch : $(_current_branch)" "Upstream branch: $(_get_upstream)"
    _info "=== git status ==="
    git status || true
    _info "=== git remote -v ==="
    git remote -v || true
    echo ""
}

clean() {
    _x git clean -d -x -i
}

copy() {
    declare -r from=${1:?}
    declare -r to=${2:?}

    # We will never copy to a protected branch since it implies a hard reset (NEVER).
    _check_branch_not_protected $to || _error_branch_protected $to
    _check_no_changes
    _switch $from
    # _x git pull
    
    # $from exists but $to maybe not
    if ! _ignore_stderr git checkout -b $to $from || ! _ignore_stderr git push --set-upstream origin $to
    then
        # delete local and remote branch (just pointers)
        _prompt "This script is about to remove local (and remote) branch $to before re-creating it from branch $from"
        _x git branch -D $to
        _x git push origin --delete $to || true
        _x git checkout -b $to $from
    fi
    if [[ -n "${DEBUG:-}" ]]
    then
        _prompt "This script is about to show \"git diff $from $to\" for both local and remote branches"
        _x git diff --name-status $from $to
        _x git diff --name-status origin/$from origin/$to
    fi
    _info "Copied branch $from to $to"
}

merge() {
    declare -r from=${1:?}
    shift
    declare -r to=${1:?}
    shift
    declare -r options="$@"
    
    _check_no_changes
    _check_upstream_exists $from || _error_upstream_does_not_exist $from
    _check_upstream_exists $to || _error_upstream_does_not_exist $to

    # merge the changes made to $to in the meantime back into $from before we will merge back
    _switch $from
    _x git merge $to || _prompt "You must fix the conflicts"
    _x git commit -m "Make $from up to date with $to" || true

    # now the real merge
    if _check_branch_not_protected $to
    then
        _switch $to
        _x git merge $options $from
    else
        # to merge into a protected branch we need a Pull Request
        _prompt "This script is about to push branch $from"
        _x git push # push $from to remote
        _switch $to # must be on a branch named differently than "release/acceptance-main"
        _pull_request $from $to
    fi        
}

merge_abort() {
    _x git merge --abort
}

declare release_state_file=
_release_state_file_reuse() { # usage: PROTECTED_BRANCHE_1 ... PROTECTED_BRANCHE_N
    declare yes_no=

    release_state_file="target/$(basename $0 .sh)-release-$(echo $* | sed -e 's/ /-/g').txt"

    if [[ -f ${release_state_file} ]]
    then
        read -p "Do you want to reuse the previous state (from file ${release_state_file}) ? [Y] " yes_no
        case "${yes_no}" in
            n | N)
                rm ${release_state_file}
                ;;
            *)
                :
                ;;
        esac        
    fi
}

_release_state_file_cleanup() {
    test ! -f ${release_state_file} || mv ${release_state_file} "${release_state_file}~"
}

_release_step_skip() { # usage: BRANCH STEP
    declare -r branch=${1:?}
    declare -r step=${2:?}

    # do not show the result
    [[ -f ${release_state_file} ]] && grep -E "^${branch}:${step}$" ${release_state_file} 1>/dev/null

    declare -r result=$? # 0 it exists

    [[ $result -ne 0 ]] || _info "Skipping step ${step} for branch ${branch} since it has already been executed"
    
    return $result
}

_release_step_write() { # usage: BRANCH STEP
    declare -r branch=${1:?}
    declare -r step=${2:?}

    [[ -d target ]] || mkdir target
    echo "${branch}:${step}" >> ${release_state_file}
    _info "Finished step ${step} for branch ${branch}"
}

release() {
    declare -r branches=$*
    declare from=
    declare to=
    declare first=
    declare step=
    declare export=
    declare release=

    _check_no_changes

    _release_state_file_reuse $*

    # step 0 from usage for release
    step=0
    for to in $branches
    do
        _check_upstream_exists $to || _error_upstream_does_not_exist $to
        ! _check_branch_not_protected $to || _error_branch_not_protected $to
        
        if [[ -n "$from" ]]
        then
            # check direction
            case "$from|$to" in
                "development|test" | \
                    "development|acceptance" | \
                    "test|acceptance" | \
                    "acceptance|main" | \
                    "acceptance|master")
                    ;;
                *)
                    _error "Wrong combination for release: $from => $to"
                    exit 1
                    ;;
            esac
        fi

        if ! _release_step_skip $to $step
        then
            export="export/$to"
            
            copy $to $export
            _prompt "You must create an export (APEX and/or database) for '$to' in ANOTHER SESSION (using PATO GUI with POMs from $pwd/apex and $pwd/db)"
            _x git add .
            _x git commit -m "Created export $export" || true
            _prompt "This script is about to push export branch $export"
            _x git push
            _release_step_write $to $step
        fi

        from=$to
    done
    
    # steps 1, 2 from usage for release
    from=
    first=
    for to in $branches
    do
        for step in 1 2a 2b 2c
        do
            if [[ $step == "1" ]]
            then
                if [[ -n "$from" ]]; then continue; fi
                release=
            else
                if [[ -z "$from" ]]; then continue; fi
                release="release/$from-$to"                        
            fi

            if ! _release_step_skip $to $step
            then
                case $step in
                    # install first branch
                    1)  _switch $to
                        _prompt "You may need to install (database only) for '$to' first in ANOTHER SESSION (using PATO GUI with POMs from $pwd/apex and $pwd/db)"
                        ;;

                    # copy to release branch
                    2a) if [[ "$first" == "$to" ]]
                        then
                            copy $from $release
                        else
                            copy "export/$from" $release
                        fi
                        ;;

                    # create a release export (only for the first, the others can use the previous export)
                    2b) if [[ "$first" == "$to" ]]
                        then
                            _prompt "You must create an export (APEX and/or database) for '$to' in ANOTHER SESSION (using PATO GUI with POMs from $pwd/apex and $pwd/db)"
                            _x git add .
                            _x git commit -m "Created release $release" || true
                        fi
                        ;;

                    # push the release branch
                    2c) _prompt "This script is about to push branch $release"
                        _x git push || _x git push --set-upstream origin $release
                        ;;
                esac
                _release_step_write $to $step
            fi
        done
        
        from=$to
        [[ -n "$first" ]] || first=$to
    done

    # step 3 from usage for release
    from=
    step=3
    for to in $branches
    do
        if [[ -n "$from" ]]
        then
            release="release/$from-$to"                        

            if ! _release_step_skip $to $step
            then
                _prompt "The contents of branch $to will be REPLACED (not MERGED) with the contents of $release"
                _switch $release
                # replace $to by $release but keep history
                _x git merge --strategy=ours --no-commit $to
                ! _x git commit -m"Replaced contents of branch $to by branch $release" || _x git push
                # normal merge to $to
                _switch $to
                _x git merge $release
                _prompt "You must fix any existing conflicts (using GitHub Desktop for instance)"
                url=$(git config --get remote.origin.url)
                url=$(basename $url .git)
                # _switch $to
                _tag $to
                _x git push

                _release_step_write $to $step
            fi
        fi
        
        from=$to
    done

    # step 4 from usage for release
    from=
    step=4
    for to in $branches
    do
        if [[ -n "$from" ]]
        then
            if ! _release_step_skip $to $step
            then
                # install all except the first branch
                _switch $to
                _prompt "You must install branch $to first in ANOTHER SESSION (using PATO GUI with POMs from $pwd/apex and $pwd/db)"
                _release_step_write $to $step
            fi
        fi
        
        from=$to
    done

    _release_state_file_cleanup # on success remove release state
}

# ----
# MAIN
# ----

! printenv DEBUG 1>/dev/null 2>&1 || set -x
! printenv DRY_RUN 1>/dev/null 2>&1 || set -nv

# check unset variables and exit on error
set -eu

test $# -ne 0 || usage

pwd=$(pwd)
command=$1
shift
case "$command" in
    info | clean | merge_abort)
        test $# -eq 0 || usage 1
        $command
        ;;
    copy)
        test $# -eq 2 || usage 1
        $command $*
        ;;
    merge)
        test $# -ge 2 || usage 1
        $command $*
        ;;
    release)
        test $# -ge 2 || usage 1
        $command $*
        ;;
    *)
        _error "Unknown command ($command)"
        usage 1
        ;;
esac
