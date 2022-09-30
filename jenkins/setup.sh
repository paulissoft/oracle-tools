#!/bin/bash -eux

# See https://serverfault.com/questions/789601/check-is-container-service-running-with-docker-compose

service=jenkins-controller
if [ -z `docker-compose ps -q $service` ] || [ -z `docker ps -q --no-trunc | grep $(docker-compose ps -q $service)` ]
then
    echo "Service $service is not running."
else
    echo "Service $service is running: shutting it down."
    docker-compose down --remove-orphans
fi

docker-compose build
docker-compose up -d
