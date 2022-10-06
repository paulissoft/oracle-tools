#!/bin/bash -eu

init() {
    ! printenv DEBUG || set -x
    
    if ! printenv DOCKER_COMPOSE_FILE
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
        if ! printenv SHARED_DIRECTORY
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

start() {
    if [ $NFS -ne 0 ]
    then
        for item in \
            JENKINS_NFS_SERVER_M2_REPOSITORY:jenkins_nfs_server_m2_repository:jenkins-nfs-server-m2-repository \
                JENKINS_NFS_SERVER_AGENT_WORKSPACE:jenkins_nfs_server_agent_workspace:jenkins-nfs-server-agent-workspace
        do
            var=$(echo $item | cut -d ':' -f 1)
            container=$(echo $item | cut -d ':' -f 2)
            service=$(echo $item | cut -d ':' -f 3)

            if ! printenv $var
            then
                case $(uname) in
                    # We need the IP address of the jenkins-nfs-server on a Mac for the NFS volume
                    # since the host can not obtain a Docker container IP address via DNS.
                    Darwin)
                        docker-compose -f docker-compose-jenkins-nfs-server.yml up -d $service
                        eval export $var=$(docker inspect $container --format '{{.NetworkSettings.Networks.jenkins.IPAddress}}')
                        ;;
                    # Here the dns-proxy-server should be able to do the right thing.
                    *)
                        eval $var=$service
                        ;;
                esac
            fi
        done
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
