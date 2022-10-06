#!/bin/bash -eu

# all possible volumes used
for v in maven-local-repository jenkins-agent-workspace jenkins-m2-repository
do
    if docker volume ls | grep $v 1>/dev/null
    then
        docker_cmd="docker run --rm -it -v $v:/tmp/volume ghcr.io/paulissoft/pato-jenkins-agent:latest"
        echo "Docker volume $v has $($docker_cmd find /tmp/volume -print | wc -l) files"
        if printenv DEBUG 1>/dev/null
        then
            docker_cmd="$docker_cmd find /tmp/volume -ls"
            eval $docker_cmd
            echo ""
            echo "The output above has been created by this command: $docker_cmd"
            echo ""
        fi
    fi    
done
