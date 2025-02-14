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
- release (from/to a protected branch)

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

release <from> <to>
-------------------
Both branches must be protected.
Branch <from> is merged into <to> (franch <from> is not updated).

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

  alias pgw="~/dev/oracle-tools/bin/pato-git-workflow.sh $@"

Now you can just type pgw.

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
        _x gh pr create --title "$from => $to" --editor --base $from
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
    _prompt "Showing \"git diff $from $to\" for both local and remote branches"
    _x git diff --name-status $from $to
    _x git diff --name-status origin/$from origin/$to
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

release() {
    declare -r from=${1:?}
    declare -r to=${2:?}
    declare -r release="release/$from-$to"
    
    _check_no_changes
    _check_upstream_exists $from || _error_upstream_does_not_exist $from
    _check_upstream_exists $to || _error_upstream_does_not_exist $to

    ! _check_branch_not_protected $from || _error_branch_not_protected $from
    ! _check_branch_not_protected $to || _error_branch_not_protected $to

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

    copy $from $release
    _prompt "Pushing branch $release"
    _x git push
    _switch $to # must be on a branch named differently than "release/acceptance-main"
    _tag
    _pull_request $release $to
}

# ----
# MAIN
# ----

! printenv DEBUG 1>/dev/null 2>&1 || set -x
! printenv DRY_RUN 1>/dev/null 2>&1 || set -nv

# check unset variables and exit on error
set -eu

test $# -ne 0 || usage

command=$1
shift
case "$command" in
    info | clean | merge_abort)
        test $# -eq 0 || usage 1
        $command
        ;;
    copy | release)
        test $# -eq 2 || usage 1
        $command $*
        ;;
    merge)
        test $# -ge 2 || usage 1
        $command $*
        ;;
    *)
        _error "Unknown command ($command)"
        usage 1
        ;;
esac
