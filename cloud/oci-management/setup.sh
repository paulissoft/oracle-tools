# not a regular Shell script but a script that will be sourced by a Shell
export COMPARTMENT_NAME=${COMPARTMENT_NAME:=database-compartment}
export COMPARTMENT_ID=$(oci iam compartment list --query "data[?name=='${COMPARTMENT_NAME}'].id | [0]" --raw-output)
export DB_NAME=${DB_NAME:=PATO}
export DB_ID=$(oci db autonomous-database list -c $COMPARTMENT_ID --query "data[?\"db-name\"=='${DB_NAME}'].id | [0]" --raw-output)
