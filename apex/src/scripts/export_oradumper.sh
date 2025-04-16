#!/usr/bin/env bash
set -eu

declare -r oradumper=$1
declare -r workspace_name=$2
declare -r application=$3

declare -r srcdir=$(cd $(dirname $0) && pwd)

# get USERID from a heredoc
$oradumper \
    feedback=0 \
    column_heading=0 \
    enclosure_string= \
    query="select  line
from    table
        ( oracle_tools.ui_apex_export_pkg.get_application
          ( p_workspace_name => '$workspace_name'
          , p_application_id => $application
          , p_split => 1
          , p_with_date => 0
          , p_with_ir_public_reports => 1
          , p_with_ir_private_reports => 1
          , p_with_ir_notifications => 0
          , p_with_translations => 1
          , p_with_original_ids => 1
          , p_with_no_subscriptions => 0
          , p_with_comments => 0
          )
        )" <<< "$USERID" | perl $srcdir/export_plsql.pl
