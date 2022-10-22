#!/bin/bash -eux

init() {
    ! printenv DEBUG 1>/dev/null || set -x

    if [ $JENKINS -ne 0 ]
    then
        if ! printenv DOCKER_COMPOSE_FILE 1>/dev/null
        then
            case $(uname) in
                Linux)
                    DOCKER_COMPOSE_FILE=
                    ;;
                *)
                    DOCKER_COMPOSE_FILE=docker-compose-jenkins-controller.yml
                    ;;
            esac
        fi
        # The docker-compose.yml is the common file.
        # The $DOCKER_COMPOSE_FILE is environment specific.
        docker_compose_files="-f docker-compose.yml"
        test -z "$DOCKER_COMPOSE_FILE" || docker_compose_files="$docker_compose_files -f $DOCKER_COMPOSE_FILE"
    else
        docker_compose_files=
    fi
    
    if [ $NFS -ne 0 ]
    then
        if ! printenv SHARED_DIRECTORY 1>/dev/null
        then
            export SHARED_DIRECTORY=~/nfs/jenkins/home
        fi
    
        rm -fr $SHARED_DIRECTORY
    
        # Create the shared directory as well as the Maven .m2/repository directory and the workspace
        for d in $SHARED_DIRECTORY $SHARED_DIRECTORY/.m2/repository $SHARED_DIRECTORY/agent/workspace
        do
            test -d $d || mkdir -p $d
            chmod -R 755 $d
        done

        if [ ! -d $SHARED_DIRECTORY/.ssh ]
        then
            mkdir -m 700 $SHARED_DIRECTORY/.ssh
            ssh-keyscan github.com > $SHARED_DIRECTORY/.ssh/known_hosts
            chmod 700 $SHARED_DIRECTORY/.ssh/known_hosts
        fi
        docker_compose_files="$docker_compose_files -f docker-compose-jenkins-nfs-server.yml -f docker-compose-jenkins-nfs-client.yml"
    fi
}

set_lib_module_dir()
{
    if test "$(uname)" = "Darwin"
    then
        declare dir=./.initrd
        test -d $dir || mkdir -p $dir
        # make dir absolute
        dir=$(cd $dir && pwd)
        test -d $dir/lib/modules || (cd $dir && gzip -dc /Applications/Docker.app/Contents//Resources/linuxkit/initrd.img | cpio -id 'lib/modules')
        LIB_MODULES_DIR=$dir/lib/modules
    else
        LIB_MODULES_DIR=/lib/modules               
    fi
    export LIB_MODULES_DIR
}

build() {
    if [ $NFS -ne 0 ]
    then
        set_lib_module_dir
    fi
    
    # See https://serverfault.com/questions/789601/check-is-container-service-running-with-docker-compose
    
    # common service
    if [ $JENKINS -ne 0 ]
    then
        service=jenkins-docker
    elif [ $NFS -ne 0 ]
    then
        service=jenkins-nfs-server
    else
        echo "Either JENKINS or NFS must be true" 1>&2
        exit 1
    fi
    
    if [ -z `docker-compose $docker_compose_files ps -q $service` ] || [ -z `docker ps -q --no-trunc | grep $(docker-compose $docker_compose_files ps -q $service)` ]
    then
        echo "Service $service is not running."
    else
        echo "Service $service is running: shutting it down."
        docker-compose $docker_compose_files down --remove-orphans
    fi

    docker-compose $docker_compose_files build
}

start() {
    if [ $RM_VOLUMES -ne 0 ]
    then
        # Remove the volumes since they may have been created with the wrong JENKINS_NFS_SERVER variables
        set -- jenkins-m2-repository jenkins-agent-workspace
        for v
        do
            if docker volume ls | grep $v
            then
                docker volume rm $v || true
            fi
        done
    fi

    ( set -x; docker-compose $docker_compose_files $docker_compose_command_and_options )

    # $curdir/show_volumes.sh
}

# main

curdir=$(dirname $0)
if [ $# -ge 1 ]
then
    docker_compose_command_and_options="$@"
else
    docker_compose_command_and_options="up -d"
fi

echo "JENKINS: ${JENKINS:=0}"
echo "NFS: ${NFS:=1}"
echo "RM_VOLUMES: ${RM_VOLUMES:=1}"

init
build
start
