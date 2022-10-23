#!/bin/bash -eu

! printenv DEBUG 1>/dev/null || set -x

# all possible volumes used
for item in \
    maven-local-repository:/home/jenkins/.m2/repository \
        jenkins-agent-workspace:/home/jenkins/agent/workspace \
        jenkins-m2-repository:/home/jenkins/.m2/repository
do
    v=$(echo $item | cut -d ':' -f 1)
    d=$(echo $item | cut -d ':' -f 2)
    if docker volume ls | grep $v 1>/dev/null
    then
        docker_cmd="docker run --rm -it -v $v:$d ghcr.io/paulissoft/pato-jenkins-agent:latest"
        echo "Docker volume $v has $($docker_cmd find $d -print | wc -l) files"
        if printenv DEBUG 1>/dev/null
        then
            docker_cmd="$docker_cmd find $d -ls"
            eval $docker_cmd
            echo ""
            echo "The output above has been created by this command: $docker_cmd"
            echo ""
        fi
    fi    
done
