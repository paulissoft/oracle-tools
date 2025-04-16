#!/usr/bin/env bash
set -eu
set -x

declare -r srcdir=$(cd $(dirname $0) && pwd)

declare -r sql=$1
declare -r userid=$2
declare -r workspace_name=$3
declare -r application=$4

$sql -S "$userid" @${srcdir}/export_plsql.sql "$workspace_name" "$application" | perl $srcdir/export_plsql.pl
