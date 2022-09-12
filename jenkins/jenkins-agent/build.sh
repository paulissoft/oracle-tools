#!/bin/sh -eu
curdir=`dirname $0`

export SCM_BRANCH=master
export SCM_USERNAME=nobody
export SCM_EMAIL=nobody@gmail.com
export CONF_DIR=conf
export DB=orcl
export DB_USERNAME=ORACLE_TOOLS
# Use today as password (hoping the connection will fail)
export DB_PASSWORD=`date -Idate`
export DB_DIR=db
export DB_ACTIONS="db-info db-test db-generate-ddl-incr db-code-check db-generate-ddl-full"
export DB_ACTIONS="db-info"
export APEX_DIR=apex
export APEX_ACTIONS="apex-export apex-import"
export APEX_ACTIONS="apex-export"
export MVN_ARGS=--fail-never
export SCM_BRANCH_PREV=
export GIT='echo git'
export BUILD_NUMBER=0

cd $curdir/../..

./jenkins/process.sh
