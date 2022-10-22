#!/bin/bash -eu

init() {
    ! printenv DEBUG 1>/dev/null || set -x
    
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
    fi

    # The docker-compose.yml is the common file.
    # The $DOCKER_COMPOSE_FILE is environment specific.
    docker_compose_files="-f docker-compose.yml"
    test $NFS -eq 0 || docker_compose_files="$docker_compose_files -f docker-compose-jenkins-nfs-server.yml -f docker-compose-jenkins-nfs-client.yml"
    test -z "$DOCKER_COMPOSE_FILE" || docker_compose_files="$docker_compose_files -f $DOCKER_COMPOSE_FILE"
}

build() {
    # See https://serverfault.com/questions/789601/check-is-container-service-running-with-docker-compose
    
    # common service
    service=jenkins-docker
    if [ -z `docker-compose $docker_compose_files ps -q $service` ] || [ -z `docker ps -q --no-trunc | grep $(docker-compose $docker_compose_files ps -q $service)` ]
    then
        echo "Service $service is not running."
    else
        echo "Service $service is running: shutting it down."
        docker-compose $docker_compose_files down --remove-orphans
    fi

    docker-compose $docker_compose_files build
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

start() {
    if [ $NFS -ne 0 ]
    then
        set_lib_module_dir
    fi
    
    # Remove the volumes since they may have been created with the wrong JENKINS_NFS_SERVER variables
    set -- jenkins-m2-repository jenkins-agent-workspace
    for v
    do
        if docker volume ls | grep $v
        then
            docker volume rm $v
        fi
    done

    ( set -x; docker-compose $docker_compose_files $docker_compose_command_and_options )

    $curdir/show_volumes.sh
}

# main

curdir=$(dirname $0)
if [ $# -ge 1 ]
then
    docker_compose_command_and_options="$@"
else
    docker_compose_command_and_options="up -d"
fi
# No NFS for the time being
NFS=0

init
build
start
