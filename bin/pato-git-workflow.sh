#!/usr/bin/env bash

usage() {
    declare -r exit_status=${1:-0}
    
    cat <<EOF | more

USAGE
=====
$0 <COMMAND> [ <OPTIONS> ]

Git workflow based on a LOCAL and CLEAN repository workspace.
The remote repository will NEVER be updated since that is your responsability.
You can update (push) the remote repository either using some GUI or the git command line tool.

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
- release_init (from lowest to highest protected branch)
- release_exec (from lowest to highest protected branch)


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


release      <protected_branch_1> <protected_branch_2> ... <protected_branch_N>
release_init <protected_branch_1> <protected_branch_2> ... <protected_branch_N>
release_exec <protected_branch_1> <protected_branch_2> ... <protected_branch_N>
--------------------------------------------------------------------------
All branches must be protected.
The branch <protected_branch_1> will usually be 'development', <protected_branch_2> 'acceptance' and <protected_branch_3> 'main' or 'master' (N = 3).
This is a prompted workflow, meaning that at every step the user is asked to do something.
0. Each branch <protected_branch_n> will be copied to export/<protected_branch_n> and the user will be asked to create an export using the PATO GUI (export APEX and generate DDL). This is a safety measure that is MANDATORY.
1. Next, branch <protected_branch_1> may need to be installed first to ensure that all development stuff is correctly installed from feature branches.
   A user action (with the PATO GUI) for APEX and/or database is needed in ANOTHER SESSION.
2. Next every branch n will be released to release/<protected_branch_n>-<protected_branch_m> (m = n+1):
   a. using the copy command first, see above (no user action needed)
   b. export APEX and/or database (generate DDL) next (for environment n) using the PATO GUI (user action in ANOTHER SESSION)
   c. pushing the changes back to the GitHub repo (no user action needed)
3. Next every release branch (release/<protected_branch_n>-<protected_branch_m>) is merged into <protected_branch_m> (m = n+1):
   a. use a Pull Request
   b. tag the resulting branch with "\`basename \$0 .sh\`-\`date -I\`" (for example pato-git-workflow-2025-03-04)
4. Now every protected branch has the new code, so just install the branches m, 1 < m <= N. Please note that branch 1 has already been installed.

Option release invokes release_init (steps 0 till 3) to prepare the release and then release_exec (step 4) to execute it.
This allows to prepare and execute a release on different moments.

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

The export from development and merging it back into development from above can now be written as (provided variable r is a repo and you are in folder ~/dev):

  (set -e; cd \$r; b=development; pgw copy \$b export/\$b; cd ../pato-gui; pato-gui ../\$r/db/pom.xml; pato-gui ../\$r/apex/pom.xml; cd ../\$r; pgw merge export/\$b \$b -X ours)

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

test -n "${PROTECTED_BRANCHES:-}" || PROTECTED_BRANCHES="development test acceptance main master"
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
    test -z "$(git status --porcelain)" || { _error "You have changes in your workspace"; git status; exit 1; }
}

_switch() {
    declare -r branch=${1:?}
    
    _x git switch $branch
    _x git pull || _x git branch --set-upstream-to=origin/$branch $branch
}

_tag() {
    declare -r tag="`basename $0 .sh`-`date -I`"
    
    _x git tag $tag
}

_pull_request() {
    declare -r from=${1:?}
    declare -r to=${2:?}

    if `git remote -v | grep github 1>/dev/null`
    then
        _x gh pr create --title "$from => $to" --editor --head $from --base $to
        _x gh pr view --web
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
    _x git pull
    
    # $from exists but $to maybe not
    if ! _ignore_stderr git checkout -b $to $from
    then
        # delete local and remote branch (just pointers)
        _prompt "Remove local (and remote) branch $to before re-creating it from branch $from"
        _x git branch -D $to
        _x git push origin --delete $to || true
        _x git checkout -b $to $from
    fi
    _x git push --set-upstream origin $to
    if [[ -n "${DEBUG:-}" ]]
    then
        _prompt "Showing \"git diff $from $to\" for both local and remote branches"
        _x git diff --name-status $from $to
        _x git diff --name-status origin/$from origin/$to
    fi
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
    _x git merge $to || _prompt "Fix the conflicts"
    _x git commit -m "Make $from up to date with $to" || true

    # now the real merge
    if _check_branch_not_protected $to
    then
        _switch $to
        _x git merge $options $from
    else
        # to merge into a protected branch we need a Pull Request
        _prompt "Pushing branch $from"
        _x git push # push $from to remote
        _switch $to # must be on a branch named differently than "release/acceptance-main"
        _pull_request $from $to
    fi        
}

merge_abort() {
    _x git merge --abort
}

release_init() {
    declare -r branches=$*
    declare from=
    declare to=
    declare release=
    declare export=

    _check_no_changes

    # step 0 from usage for release
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
                    echo "Releasing from $from to $to"
                    ;;
                *)
                    _error "Wrong combination for release: $from => $to"
                    exit 1
                    ;;
            esac
        fi
            
        export="export/$to"
        copy $to $export
        _prompt "Please create a backup export (APEX and/or database) in ANOTHER SESSION (using PATO GUI with POMs from $pwd/apex and $pwd/db)"
        _prompt "Pushing branch $export"
        _x git push

        from=$to
    done

    # steps 1, 2 and 3 from usage for release
    from=
    for to in $branches
    do
        if [[ -z "$from" ]]
        then
            # step 1 from usage for release
            # install first branch
            _switch $to
            _prompt "You may need to install branch $to first in ANOTHER SESSION (using PATO GUI with POMs from $pwd/apex and $pwd/db)"
        fi
        
        if [[ -n "$from" ]]
        then
            # step 2 from usage for release
            # step 2a
            release="release/$from-$to"
            copy $from $release
            # step 2b
            _prompt "Please create a release export (APEX and/or database) in ANOTHER SESSION (using PATO GUI with POMs from $pwd/apex and $pwd/db)"
            # step 2c
            _prompt "Pushing branch $release"
            _x git push

            # step 3 from usage for release
            # step 3a
            _pull_request $release $to
            # step 3b
            _tag
            url=$(git config --get remote.origin.url)
            url=$(basename $url .git)
            _prompt "Please ensure that the Pull Request from $release to $to has been accepted (go to $url)"
        fi
        
        from=$to
    done
}

release_exec() {
    declare -r branches=$*
    declare from=
    declare to=

    _check_no_changes

    # step 4 from usage for release
    from=
    for to in $branches
    do
        if [[ -n "$from" ]]
        then
            # install all except the first branch
            _switch $to
            _prompt "Install branch $to first in ANOTHER SESSION (using PATO GUI with POMs from $pwd/apex and $pwd/db)"
        fi
        
        from=$to
    done
}

release() {
    release_init "$@"
    release_exec "$@"
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
    release | release_init | release_exec)
        test $# -ge 2 || usage 1
        $command $*
        ;;
    *)
        _error "Unknown command ($command)"
        usage 1
        ;;
esac
