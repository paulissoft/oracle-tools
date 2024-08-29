#!/usr/bin/env bash
this_dir=$(dirname $0)

set -eu
source $this_dir/setup.sh
echo "Using this wallet file for database $DB_NAME:" ${WALLET_FILE:=${WALLET_DIR:=$HOME/wallets}/${DB_NAME}.zip}

oci db autonomous-database generate-wallet --autonomous-database-id $DB_ID --password ${WALLET_PASSWORD:-Pw4ZipFile} --file $WALLET_FILE

adb_variables="$this_dir/../terraform/oci_adb_variables.auto.tfvars"

test -f "$adb_variables"

# read amongst other admin_password
while IFS='=' read -r key value
do
    key=$(echo ${key} | tr -d ' ')
    case "$key" in
        admin_password)
            eval ${key}=\${value}
            break
            ;;
    esac        
done < "$adb_variables"

admin_username='ADMIN'
sql_query='select sysdate from dual;'

sql -s /nolog <<-EOF
set cloudconfig ${WALLET_FILE}
show tns
connect $admin_username/$admin_password@${DB_NAME}_TP
$sql_query
EOF
