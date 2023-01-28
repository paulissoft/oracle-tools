#!/bin/bash -xeu

# See https://tm-apex.blogspot.com/2022/06/running-apex-in-docker-container.html

function init {
    echo ${NETWORK:=demo-network}
    echo ${VOLUME:=db-demo-volume}
    echo ${ORDS_DIR:=~/opt/oracle/ords}
    echo ${ORACLE_PWD:=1230123}
    echo ${ORACLE_HOSTNAME:=database}
    echo ${ORACLE_PORT:=1521}
    echo ${APEX_PORT:=8181}

    # colima start -c 4 -m 12 -a x86_64
}

function setup {
    docker network ls | grep $NETWORK || docker network create $NETWORK
    docker network ls
    docker volume ls | grep $VOLUME || docker volume create $VOLUME
    docker volume ls
    
    docker login container-registry.oracle.com

    # Oracle XE
    docker pull container-registry.oracle.com/database/express:latest
    docker image tag container-registry.oracle.com/database/express:latest oracle-xe-21.3
    docker rmi container-registry.oracle.com/database/express:latest
    docker images

    # ORDS and APEX
    docker pull container-registry.oracle.com/database/ords:latest
    docker image tag container-registry.oracle.com/database/ords:latest ords-21.4
    docker rmi container-registry.oracle.com/database/ords:latest
    test -f $ORDS_DIR || mkdir -p $ORDS_DIR
    echo "CONN_STRING=sys/${ORACLE_PWD}@${ORACLE_HOSTNAME}:${ORACLE_PORT}/XEPDB1" > $ORDS_DIR/conn_string.txt
}

function run_oracle_xe {
    docker run -d --name db-container \
           -p 1521:${ORACLE_PORT} \
           -e ORACLE_PWD=${ORACLE_PWD} \
           -v $VOLUME:/opt/oracle/oradata \
           --network=$NETWORK \
           --hostname $ORACLE_HOSTNAME \
           oracle-xe-21.3
}

function run_ords {
    docker run -d --name ords --network=$NETWORK -p 8181:${APEX_PORT} -v $ORDS_DIR:/opt/oracle/variables ords-21.4
    docker exec -it ords tail -f /tmp/install_container.log
    open http://localhost:${APEX_PORT}/ords/
}

function main {
    init
    setup
    run_oracle_xe
    run_ords
}

main
