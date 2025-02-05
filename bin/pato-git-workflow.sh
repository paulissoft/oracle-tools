#!/usr/bin/env bash

function usage {
    declare -r exit_status=${1:-0}
    
    cat <<EOF
Usage: $0 <COMMAND> [ <OPTIONS> ]

Git workflow based on a LOCAL and CLEAN repository workspace.
The remote repository will NEVER be updated since that is your responsability.
You can update (push) the remote repository either using some GUI or the git command line tool.

You can debug what is going by setting environment variable DEBUG.

You can have a (kind of a) dry run by setting environment variable DRY_RUN.
In this case "set -nv" will be used (enable syntax checking and verbosity).

COMMAND
=======
These are the options:
- clean (workspace)
- copy (from/to a branch)
- merge (from/to a branch)

clean
-----
The workspace will be cleaned (Git will use file(s) .gitignore for that),
but you will decide what to clean interactively.
The Git command used is: "git clean -d -x -i".

copy <from> <to>
----------------
When the branch to copy does NOT exist, the Git command will be "git checkout -b <to> <from>".
When the branch exists: "git switch <to> && git reset --hard '@{u}'".
In both cases, the <to> branch will be the current branch ("git switch <to>").

merge <from> <to> <git merge options>
-------------------------------------
First make <from> up to date with respect to <to>, i.e. merge <to> into <from>.
Next switch back to <to> and merge <from> into <to> using the <git merge options>.

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

These are your workflow actions:
1. pato-git-workflow.sh copy development export/development
2. # do your export, commit and push export/development (current branch) to the remote repository
3. pato-git-workflow.sh merge export/development development

alias
-----
Since you do not like to type in more than needed, you can make an alias in your shell source script:

  alias pgw="~/dev/oracle-tools/bin/pato-git-workflow.sh $@"

Now you can just type pgw.

EOF
    exit $exit_status
}

function error {
    echo ""
    echo "ERROR: $*" 1>&2
    echo ""
}

function _check_no_changes {
    test -z "$(git status --porcelain)" || { error "You have changes in your workspace"; git status; exit 1; }
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

function _switch {
    declare -r branch=$1
    
    _x git switch $branch
    _x git pull origin $branch
}

function clean {
    _x git clean -d -x -i
}

function copy {
    declare -r from=$1
    declare -r to=$2
    
    _check_no_changes
    _switch $from
    
    # $from exists but $to maybe not
    if ! _ignore_stderr git checkout -b $to $from
    then
        # $to exists: switch to it and reset
        _x git switch $to
        _x git reset --hard '@{u}'
    fi
    _x git switch $to
}

function merge {
    declare -r from=$1
    shift
    declare -r to=$1
    shift
    declare -r options="$@"
    
    _check_no_changes

    # merge the changes made to $to in the meantime back into $from before we will merge back
    _switch $from
    _x git merge $to
    _x git commit -m"Make $from up to date with $to"

    # now the real merge
    _switch $to    
    _x git merge $options $from
}

# MAIN

! printenv DEBUG 1>/dev/null 2>&1 || set -x
! printenv DRY_RUN 1>/dev/null 2>&1 || set -nv

# check unset variables and exit on error
set -eu

test $# -ne 0 || usage

command=$1
shift
case "$command" in
    clean)
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
    *)
        error "Unknown command ($command)"
        usage 1
        ;;
esac
