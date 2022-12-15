#!/usr/bin/env bash

set -eu

if [ $# -eq 0 ]
then
    echo "usage: create-incremental-scripts.sh WORK-DIRECTORY [ FULL DIRECTORY ] [ INCR DIRECTORY ]" 1>&2
    exit 1
fi

! printenv DEBUG 1>/dev/null || set -x
dry_run=${DRY_RUN:-}

dir=$1
shift
if [ $# -gt 0 ]; then full=$1; shift; else full=full; fi
if [ $# -gt 0 ]; then incr=$1; shift; else incr=incr; fi

cd $dir
test -d $full && test -d $incr

function process {
    declare -r grep_flag=$1

    tm=$(date "+%Y%m%d%H%M%S")
    for f in $(ls -1 $full/????.*.sql | grep $grep_flag .REF_CONSTRAINT.)
    do
        t=$(basename $f)
        t="V${tm}.$(echo $t | sed -e 's/\./__/')"
        echo "cp $f $incr/$t"
        if [ -z $dry_run ]
        then
            cp $f $incr/$t
        fi
    done
}

# all non REF_CONSTRAINT files
process -v

sleep 1

# all REF_CONSTRAINT files at the end
process ""

