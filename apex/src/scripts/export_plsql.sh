#!/usr/bin/env bash
set -eu
set -x

declare -r srcdir=$(cd $(dirname $0) && pwd)

declare -r sql=$1
declare -r workspace_name=$2
declare -r application=$3

$sql -S @${srcdir}/export_plsql.sql "$workspace_name" "$application" <<< "$USERID" | perl $srcdir/export_plsql.pl
