#!/bin/bash -eux

# Setup Jenkins via Docker on Linux/Mac, see https://www.jenkins.io/doc/book/installing/docker/#setup-wizard

# Setup SSH between Jenkins and Github, see https://levelup.gitconnected.com/setup-ssh-between-jenkins-and-github-e4d7d226b271

# TBD: setting up SSH agent later
test $# -gt 0 || set -- 1 2 3 4 5 6

jenkins_network=jenkins

# Generate a SSH keypair in order to access the Jenkins agent from the Jenkins controller
test -d ~/.ssh || mkdir -m 700 ~/.ssh
test -f ~/.ssh/jenkins_agent_key || ssh-keygen -t rsa -f ~/.ssh/jenkins_agent_key

export JENKINS_AGENT_SSH_PUBKEY=$(cat ~/.ssh/jenkins_agent_key.pub)

docker network ls | grep " $jenkins_network " || docker network create $jenkins_network
! docker compose ls jenkins | grep running || docker-compose down
docker-compose build
docker-compose up -d
# Add jenkins-agent to known hosts
docker exec jenkins_controller sh -c 'cd; test -d .ssh || mkdir .ssh; touch .ssh/known_hosts; ssh-keygen -R jenkins-agent; ssh-keyscan jenkins-agent >> .ssh/known_hosts'
