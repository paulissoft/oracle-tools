#!/bin/bash -eu

# all possible volumes used
for v in maven-local-repository jenkins-agent-workspace jenkins-m2-repository jenkins-agent-workspace
do
    if docker volume ls | grep $v
    then
        echo "Showing Docker volume $v"
        echo ""
        docker run --rm -it -v $v:/tmp/volume ghcr.io/paulissoft/pato-jenkins-agent:latest find /tmp/volume -ls
    fi    
done
