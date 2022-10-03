#!/bin/bash -eux

if [ $# -ge 1 ]
then
    docker_compose_file=$1
else    
    case $(uname) in
        Linux)
            docker_compose_file=docker-compose-jenkins-as-service.yml
            ;;
        *)
            docker_compose_file=docker-compose-jenkins-as-docker-container.yml
            ;;
    esac
fi

# See https://serverfault.com/questions/789601/check-is-container-service-running-with-docker-compose

service=jenkins-controller
if [ -z `docker-compose -f $docker_compose_file ps -q $service` ] || [ -z `docker ps -q --no-trunc | grep $(docker-compose -f $docker_compose_file ps -q $service)` ]
then
    echo "Service $service is not running."
else
    echo "Service $service is running: shutting it down."
    docker-compose -f $docker_compose_file down --remove-orphans
fi

docker-compose -f $docker_compose_file build
docker-compose -f $docker_compose_file up -d
