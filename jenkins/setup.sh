#!/bin/bash -eu

# Setup Jenkins via Docker on Linux/Mac, see https://www.jenkins.io/doc/book/installing/docker/#setup-wizard

min_nr=${1:-0}
max_nr=${2:-5}

nr=$min_nr

while [ "$nr" -le $max_nr ]
do
    echo "step: $nr"
    case $nr in
        0) docker network create jenkins;;
        1) docker run \
  --name jenkins-docker \
  --rm \
  --detach \
  --privileged \
  --network jenkins \
  --network-alias docker \
  --env DOCKER_TLS_CERTDIR=/certs \
  --volume jenkins-docker-certs:/certs/client \
  --volume jenkins-data:/var/jenkins_home \
  --publish 2376:2376 \
  docker:dind \
  --storage-driver overlay2
           ;;
        2) cat <<'EOF' | docker build -t myjenkins-blueocean:2.319.2-1 -f - .
FROM jenkins/jenkins:2.319.2-jdk11
USER root
RUN apt-get update && apt-get install -y lsb-release
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli
USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean:1.25.2 docker-workflow:1.27"
EOF
           ;;
        3) docker run \
  --name jenkins-blueocean \
  --rm \
  --detach \
  --network jenkins \
  --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client \
  --env DOCKER_TLS_VERIFY=1 \
  --publish 8080:8080 \
  --publish 50000:50000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  myjenkins-blueocean:2.319.2-1
           ;;
        4) docker container exec -it jenkins-blueocean ssh-keygen -t rsa -f /var/jenkins_home/.ssh/id_rsa -N ""
           ;;
        5) open http://localhost:8080
           ;;
    esac
    nr=$(expr $nr + 1)
done
