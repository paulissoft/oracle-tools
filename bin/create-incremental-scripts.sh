#!/usr/bin/env bash
set -xeu
dir=$1

cd $dir
test -d full && test -d incr
tm=$(date "+%Y%m%d%H%M%S")
# all non REF_CONSTRAINT files
for f in $(ls -1 full/????.*.sql | grep -v .REF_CONSTRAINT.); do t=$(basename $f); t="V${tm}.$(echo $t | sed -e 's/.ORACLE_TOOLS./__/')"; cp $f incr/$t; done
# all REF_CONSTRAINT files at the end
sleep 1
tm=$(date "+%Y%m%d%H%M%S")
for f in $(ls -1 full/????.*.sql | grep .REF_CONSTRAINT.); do t=$(basename $f); t="V${tm}.$(echo $t | sed -e 's/.ORACLE_TOOLS./__/')"; cp $f incr/$t; done
