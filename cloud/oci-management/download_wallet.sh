#!/usr/bin/env bash
this_dir=$(dirname $0)

set -eu
source $this_dir/setup.sh
test -d ${WALLET_DIR:=$HOME/wallets} || mkdir -p $WALLET_DIR
echo "Downloading wallet for database $DB_NAME to:" ${WALLET_FILE:=${WALLET_DIR}/${DB_NAME}.zip}
oci db autonomous-database generate-wallet --autonomous-database-id $DB_ID --password ${WALLET_PASSWORD:-Pw4ZipFile} --file $WALLET_FILE
