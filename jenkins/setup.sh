#!/bin/bash -eu

usage() {
    echo "=== usage ==="
    cat <<EOF

Description
===========
This script sets up the Jenkins environment for Docker Compose.  Docker
Compose is executed with one or more Docker Compose profiles using the command
supplied on the command line (default 'up --build --detach' meaning build and
run containers in the background).

Usage
=====
setup.sh [ up | down | -h | --help | docker-compose COMMAND and OPTIONS ]

Environment variables
=====================
- CLEANUP: do we clean up Docker volumes and the NFS_SERVER_VOLUME host path 
  (0=false; 1=true)? Defaults to no.
- COMPOSE_PROFILES: a comma separated list of Docker Compose profiles.
- DEBUG: for executing with set -x
- JENKINS: will we set up containers necessary for Jenkins (0=false; 1=true)? 
  Defaults to yes.
- JENKINS_CONTROLLER: do we setup a Jenkins Docker controller or not 
  (0=false; 1=true)? On Linux no, else yes.
- JENKINS_SSH_AGENT_PRIVATE: file with the SSH private key for the Jenkins SSH agent.
  Defaults to ~/.ssh/jenkins_ssh_agent.
- NFS: will we set up NFS (0=false; 1=true)? Defaults to yes.
- NFS_SERVER_VOLUME: the NFS server Docker volume or bind host path. 
  Defaults to a path (~/nfs/jenkins/home).

Examples
========
To bring down all services:

\$ setup.sh down

To add debugging while starting up:

\$ DEBUG=1 setup.sh

EOF
}

add_to_list() {
    declare -r list=$1
    shift
    declare -r sep=$1
    shift

    for e
    do
        if [ -z "${!list}" ]
        then
            eval ${list}="${e}"
        else
            eval ${list}="${!list}${sep}${e}"
        fi
    done
}

init() {
    echo "=== init ==="
    ! printenv DEBUG 1>/dev/null || set -x

    echo "CLEANUP: ${CLEANUP:=0}"
    echo "JENKINS: ${JENKINS:=1}"
    echo "NFS: ${NFS:=1}"
    echo "JENKINS_SSH_AGENT_PRIVATE: ${JENKINS_SSH_AGENT_PRIVATE:=~/.ssh/jenkins_ssh_agent}"

    jenkins_ssh_agent_private_dir=$(eval cd $(dirname ${JENKINS_SSH_AGENT_PRIVATE}) && pwd)
    jenkins_ssh_agent_private_base=$(basename ${JENKINS_SSH_AGENT_PRIVATE})
    JENKINS_SSH_AGENT_PRIVATE="${jenkins_ssh_agent_private_dir}/${jenkins_ssh_agent_private_base}"

    compose_profiles=
    if [ $JENKINS -ne 0 ]
    then
        # The profile docker is common.
        add_to_list compose_profiles , docker
        if ! printenv JENKINS_CONTROLLER 1>/dev/null
        then
            case $(uname) in
                Linux)
                    # Assume that Jenkins is installed as a service 
                    JENKINS_CONTROLLER=0
                    ;;
                *)
                    JENKINS_CONTROLLER=1
                    ;;
            esac
        fi
        echo "JENKINS_CONTROLLER: ${JENKINS_CONTROLLER}"
        test "$JENKINS_CONTROLLER" -eq 0 || add_to_list compose_profiles , controller
    fi
    
    if [ $NFS -ne 0 ]
    then
        if ! printenv NFS_SERVER_VOLUME 1>/dev/null
        then
            NFS_SERVER_VOLUME=nfs-server-volume
        fi

        # Is NFS_SERVER_VOLUME a Docker volume or a path?
        case "$NFS_SERVER_VOLUME" in
            ~* | */*)
                NFS_SERVER_VOLUME_TYPE=bind
                ;;
            *)
                NFS_SERVER_VOLUME_TYPE=volume
                ;;
        esac

        if [ "$NFS_SERVER_VOLUME_TYPE" = "bind" ]
        then
            test "$CLEANUP" -eq 0 || test ! -d "$NFS_SERVER_VOLUME" || rm -fr "$NFS_SERVER_VOLUME"
    
            # Create the shared directory as well as the Maven .m2/repository directory and the workspace
            for d in $NFS_SERVER_VOLUME $NFS_SERVER_VOLUME/repository $NFS_SERVER_VOLUME/workspace
            do
                test -d $d || mkdir -p $d
                chmod -R 755 $d
            done
            # make NFS_SERVER_VOLUME absolute
            NFS_SERVER_VOLUME=$(cd $NFS_SERVER_VOLUME && pwd)
        fi

        # Both NFS_SERVER_VOLUME_TYPE and NFS_SERVER_VOLUME will be used in docker-compose.yml
        export NFS_SERVER_VOLUME_TYPE NFS_SERVER_VOLUME
        echo "NFS_SERVER_VOLUME_TYPE: ${NFS_SERVER_VOLUME_TYPE}"
        echo "NFS_SERVER_VOLUME: ${NFS_SERVER_VOLUME}"

        # Setup Jenkins SSH agent
        if [ ! -f "$JENKINS_SSH_AGENT_PRIVATE" ]
        then
            echo "SSH private key file '$JENKINS_SSH_AGENT_PRIVATE' does not exist: starting ssh-keygen"
            ssh-keygen
        fi
        test -f "$JENKINS_SSH_AGENT_PRIVATE" || { echo "SSH privated key file '$JENKINS_SSH_AGENT_PRIVATE' does still not exist" 1>&2; exit 1; }
        export JENKINS_SSH_AGENT_PUB_KEY=$(eval cat ${JENKINS_SSH_AGENT_PRIVATE}.pub)
        echo "JENKINS_SSH_AGENT_PUB_KEY: ${JENKINS_SSH_AGENT_PUB_KEY}"
        add_to_list compose_profiles , nfs jenkins-ssh-agent

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
        echo "LIB_MODULES_DIR: ${LIB_MODULES_DIR}"
    fi

    # Do not overwrite COMPOSE_FILES when set
    printenv COMPOSE_PROFILES 1>/dev/null || export COMPOSE_PROFILES=${compose_profiles}
    echo "COMPOSE_PROFILES: ${COMPOSE_PROFILES}"
    echo ""
}

shutdown() {
    echo "=== shutdown ==="
    # See https://serverfault.com/questions/789601/check-is-container-service-running-with-docker-compose
    
    # common service(s)
    services='jenkins-docker jenkins-nfs-server'

    for service in $services
    do
        if [ -z `docker-compose ps -q $service` ] || [ -z `docker ps -q --no-trunc | grep $(docker-compose ps -q $service)` ]
        then
            echo "Service $service is not running."
        else
            echo "Service $service is running: shutting it down."
            services=
            break
        fi
    done
    
    if [ -n "$services" ]
    then
        echo "Doing nothing since no services are running."
    else
        docker-compose down --remove-orphans
    fi

    if [ $CLEANUP -ne 0 ]
    then
        # Remove the volumes since they may have been created with the wrong JENKINS_NFS_SERVER variables
        set -- nfs-server-volume jenkins-m2-repository jenkins-agent-workspace
        for v
        do
            if docker volume ls | grep $v
            then
                docker volume rm $v || true
            fi
        done
    fi
}

process() {
    echo "=== process (docker-compose $@) ==="
    ( set -x; docker-compose "$@" )
}

# MAIN

if [ $# -ge 1 ]
then
    case "$1" in
        up)
            init
            shutdown
            process "$@"
            ;;
        down)
            init
            shutdown
            ;;
        -h | --help)
            usage
            ;;
    esac
else
    init
    shutdown
    process up --build --detach
fi
