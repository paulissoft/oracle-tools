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

# Use -S switch to remove this:
#
# Disconnected from Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
# Version 19.29.0.1.0

$sql -S /nolog @$tmpfile | perl $srcdir/export_plsql.pl
