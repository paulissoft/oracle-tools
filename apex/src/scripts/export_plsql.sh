#!/usr/bin/env bash
set -eu

declare -r sql=$1
declare -r workspace_name=$2
declare -r application=$3

declare -r srcdir=$(cd $(dirname $0) && pwd)
declare -r tmpfile=$(mktemp ${TMP:-/tmp}/export_plsql.XXXXXX)

cleanup() {
    rm $tmpfile
}

trap cleanup EXIT

# only you should be able to read the file (while it runs)
echo > $tmpfile
chmod 600 $tmpfile

cat > $tmpfile <<EOF
connect $USERID
@${srcdir}/export_plsql.sql $workspace_name $application
exit sql.sqlcode
EOF

$sql /nolog @$tmpfile | perl $srcdir/export_plsql.pl
