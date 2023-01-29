#!/bin/bash -eu

# See https://tm-apex.blogspot.com/2022/06/running-apex-in-docker-container.html

function init {
    CURDIR=$(cd $(dirname $0) && pwd)

    if [ -f $CURDIR/.env ]
    then
        source $CURDIR/.env
    fi

    # container-registry.oracle.com/database/express:latest
    echo ${DB_IMAGE=oracle-xe-21.3}
    echo ${DB_CONTAINER:=oracle-xe}
    # container-registry.oracle.com/database/ords:latest
    echo ${ORDS_IMAGE:=ords-21.4}
    echo ${ORDS_CONTAINER:=ords}
    echo ${NETWORK:=oracle-network}
    echo ${VOLUME:=oracle-data-volume}
    echo ${ORDS_DIR:=$(cd ~ && pwd)/opt/oracle/ords}
    echo ${ORACLE_HOSTNAME:=database}
    echo ${ORACLE_PORT:=1521}
    echo ${APEX_PORT:=8181}

    if [ ! -f $CURDIR/.env ]
    then
        cat > $CURDIR/.env <<EOF
DB_IMAGE=$DB_IMAGE
DB_CONTAINER=$DB_CONTAINER
ORDS_IMAGE=$ORDS_IMAGE
ORDS_CONTAINER=$ORDS_CONTAINER
NETWORK=$NETWORK
VOLUME=$VOLUME
ORDS_DIR=$ORDS_DIR
ORACLE_HOSTNAME=$ORACLE_HOSTNAME
ORACLE_PORT=$ORACLE_PORT
APEX_PORT=$APEX_PORT
EOF
    fi

    export DB_IMAGE DB_CONTAINER ORDS_IMAGE ORDS_CONTAINER NETWORK VOLUME ORDS_DIR ORACLE_HOSTNAME ORACLE_PORT APEX_PORT

    printenv ORACLE_PWD 1>/dev/null 2>&1 || read -p "Oracle password? " ORACLE_PWD
    export ORACLE_PWD
    for d in variables config
    do
        test -d $ORDS_DIR/$d || mkdir -p $ORDS_DIR/$d
    done
    echo "CONN_STRING=sys/${ORACLE_PWD}@${ORACLE_HOSTNAME}:${ORACLE_PORT}/XEPDB1" > $ORDS_DIR/variables/conn_string.txt

    # Mac M1 & M2 architectures
    if which colima
    then
        if ! colima list | grep Running
        then
            colima start -c 4 -m 12 -a x86_64
        fi
    fi

    docker network ls | grep $NETWORK || docker network create $NETWORK
    docker network ls
    docker volume ls | grep $VOLUME || docker volume create $VOLUME
    docker volume ls
    
    docker login container-registry.oracle.com
}

function setup {
    # Oracle XE
    docker pull container-registry.oracle.com/database/express:latest
    docker image tag container-registry.oracle.com/database/express:latest ${DB_IMAGE}
#    docker rmi container-registry.oracle.com/database/express:latest
    docker images

    # ORDS and APEX
    docker pull container-registry.oracle.com/database/ords:latest
    docker image tag container-registry.oracle.com/database/ords:latest ${ORDS_IMAGE}
#    docker rmi container-registry.oracle.com/database/ords:latest
}

function run_oracle_xe {
    if docker ps | grep ${DB_CONTAINER}
    then
        docker stop ${DB_CONTAINER} || true
        docker rm ${DB_CONTAINER}
    fi
    docker run -d --name ${DB_CONTAINER} \
           -p ${ORACLE_PORT}:1521 \
           -e ORACLE_PWD=${ORACLE_PWD} \
           -v $VOLUME:/opt/oracle/oradata \
           --network=$NETWORK \
           --hostname $ORACLE_HOSTNAME \
           ${DB_IMAGE}
    while ! docker logs ${DB_CONTAINER} | grep 'DATABASE IS READY TO USE!'
    do
        sleep 5
    done
}

function run_ords {
    if docker ps | grep ${ORDS_CONTAINER}
    then
        docker stop ${ORDS_CONTAINER} || true
        docker rm ${ORDS_CONTAINER}
    fi
    docker run -d --name ${ORDS_CONTAINER} \
           --network=$NETWORK \
           -p ${APEX_PORT}:8181 \
           -v $ORDS_DIR/variables:/opt/oracle/variables \
           ${ORDS_IMAGE}
    docker exec -it ords tail -f /tmp/install_container.log
    open http://localhost:${APEX_PORT}/ords/
}

function main {
    ! printenv DEBUG 1>/dev/null 2>&1 || set -x
    if [ $# -eq 0 ]
    then
        echo "Usage: $0 [ docker | docker-compose [OPTIONS] COMMAND ]" 1>&2
        exit 1
    else
        init
        case "$1" in
            "docker")
                # Use Docker to start all
                shift
                if [ $# -eq 0 ]
                then
                    set -- setup run_oracle_xe run_ords
                fi
                while [ $# -gt 0 ]
                do
                    eval $1
                    shift
                done
                ;;
            "docker-compose")
                shift
                if [ $# -eq 0 ]
                then
                    set -- up --detach --remove-orphans
                fi
                docker-compose -f $CURDIR/docker-compose.yml "$@"
                ;;
        esac
    fi
}

main "$@"
