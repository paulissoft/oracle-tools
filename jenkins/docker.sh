#!/bin/sh -eu

# See:
# - https://davelms.medium.com/run-jenkins-in-a-docker-container-part-1-docker-in-docker-7ca75262619d
# - https://stackoverflow.com/questions/51119922/how-to-connect-to-docker-via-tcp-on-macos
# - https://davelms.medium.com/run-jenkins-in-a-docker-container-part-2-socat-d5f18820fe1d
# - https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/

# docker network create jenkins || true
# 
# docker container run --name jenkins-docker \
#   --detach --restart unless-stopped \
#   --privileged \
#   --network jenkins --network-alias docker \
#   --env DOCKER_TLS_CERTDIR="/certs" \
#   --volume jenkins-docker-certs:/certs/client \
#   --volume jenkins-data:/var/jenkins_home \
#   docker:dind || true
# 
# docker container run --name jenkins-blueocean \
#   --detach --restart unless-stopped \
#   --network jenkins \
#   --env DOCKER_HOST="tcp://docker:2376" \
#   --env DOCKER_CERT_PATH=/certs/client \
#   --env DOCKER_TLS_VERIFY=1 \
#   --volume jenkins-docker-certs:/certs/client:ro \
#   --volume jenkins-data:/var/jenkins_home \
#   --publish 8080:8080 --publish 50000:50000 \
#   jenkinsci/blueocean:latest || true
# 
# docker logs jenkins-blueocean

test $# -gt 0 || set -- 1 2 4 5

jenkins_network=jenkins
export JENKINS_IMAGE=jenkinsci/blueocean
export JENKINS_IMAGE=jenkins/jenkins
jenkins_image=myjenkins-blueocean
           
for nr
do
    echo "step: $nr"
    case $nr in
        1) docker network ls | grep " $jenkins_network " || docker network create $jenkins_network
           ;;
        2) docker container run --name jenkins-docker \
                  --detach --restart unless-stopped \
                  --network jenkins --network-alias docker \
                  --volume /var/run/docker.sock:/var/run/docker.sock \
                  --publish 2375:2375 \
                  alpine/socat \
                  tcp-listen:2375,fork,reuseaddr unix-connect:/var/run/docker.sock
           ;;
        3) cat <<'EOF' | docker build --build-arg JENKINS_IMAGE -t $jenkins_image -f - .
ARG JENKINS_IMAGE
FROM $JENKINS_IMAGE
USER root
RUN apt-get update && apt-get install -y lsb-release iputils-ping
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli
# RUN usermod -a -G docker jenkins
USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean docker-workflow"
EOF
           ;;
# docker run --name jenkins-blueocean --restart=on-failure --detach \
#   --network jenkins --env DOCKER_HOST=tcp://docker:2376 \
#   --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 \
#   --publish 8080:8080 --publish 50000:50000 \
#   --volume jenkins-data:/var/jenkins_home \
#   --volume jenkins-docker-certs:/certs/client:ro \
#   $jenkins_image

#         4) docker run --name jenkins-blueocean \
#                   --restart=on-failure --detach \
#                   --network jenkins \
#                   --env DOCKER_HOST=tcp://docker:2376 \
#                   --env DOCKER_TLS_VERIFY="" \
#                   --publish 8080:8080 --publish 50000:50000 \
#                   --volume jenkins-data:/var/jenkins_home \
#                   $jenkins_image
# 
        4) docker container run --name jenkins-blueocean \
                  --detach --restart unless-stopped \
                  --network jenkins \
                  --env DOCKER_HOST="tcp://docker:2375" \
                  --env DOCKER_TLS_VERIFY="" \
                  --volume jenkins-blueocean-data:/var/jenkins_home \
                  --publish 8080:8080 --publish 50000:50000 \
                  jenkinsci/blueocean
           ;;
        5) while ! docker logs jenkins-blueocean 2>&1 | grep 'Jenkins is fully up and running'
           do
               sleep 1
           done
           ;;
    esac
done
      


