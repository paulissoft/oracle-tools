#!/bin/bash -eu

# Setup Jenkins via Docker on Linux/Mac, see https://www.jenkins.io/doc/book/installing/docker/#setup-wizard

# Setup SSH between Jenkins and Github, see https://levelup.gitconnected.com/setup-ssh-between-jenkins-and-github-e4d7d226b271

# TBD: setting up SSH agent later
test $# -gt 0 || set -- 1 2 3 4 5 6

jenkins_network=jenkins
dind_image='docker:dind'
dind_name=jenkins-docker
jenkins_image=myjenkins-blueocean
jenkins_name=jenkins-blueocean
ssh_agent_image=jenkins/ssh-agent:latest
ssh_agent_name1=agent1
ssh_agent_name2=agent2

export SQLCL_ZIP=sqlcl-21.4.1.17.1458.zip
export SQLCL_URL=https://download.oracle.com/otn_software/java/sqldeveloper/$SQLCL_ZIP
export JENKINS_PLUGINS="blueocean:latest docker-workflow:latest"

# version: latest or lts (long term support)
JENKINS_IMAGE_VERSION=latest
export JENKINS_IMAGE=jenkins/jenkins:${JENKINS_IMAGE_VERSION}-jdk11

for nr
do
    echo "step: $nr"
    case $nr in
        1) docker network ls | grep " $jenkins_network " || docker network create $jenkins_network
           ;;
        2) if ! docker ps | grep " $dind_image "
           then
               docker run \
  --name $dind_name \
  --rm \
  --detach \
  --privileged \
  --network $jenkins_network \
  --network-alias docker \
  --env DOCKER_TLS_CERTDIR=/certs \
  --volume jenkins-docker-certs:/certs/client \
  --volume jenkins-data:/var/jenkins_home \
  --publish 2376:2376 \
  $dind_image \
  --storage-driver overlay2
           fi          
           ;;
        3) cat <<'EOF' | docker build --build-arg SQLCL_ZIP --build-arg SQLCL_URL --build-arg JENKINS_PLUGINS --build-arg JENKINS_IMAGE -t $jenkins_image -f - .
ARG JENKINS_IMAGE
FROM $JENKINS_IMAGE
USER root
RUN apt-get update && apt-get install -y lsb-release
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli iputils-ping
ARG SQLCL_ZIP
ARG SQLCL_URL
RUN curl -o /tmp/$SQLCL_ZIP $SQLCL_URL
RUN mkdir -p /opt/oracle && \
    cd       /opt/oracle && \
    unzip    /tmp/$SQLCL_ZIP && \
    cd -
USER jenkins
ARG JENKINS_PLUGINS
RUN jenkins-plugin-cli --plugins $JENKINS_PLUGINS
EOF
           ;;
        4) docker ps | grep " $jenkins_image " || docker run \
  --name $jenkins_name \
  --rm \
  --detach \
  --network $jenkins_network \
  --network-alias jenkins-controller \
  --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client \
  --env DOCKER_TLS_VERIFY=1 \
  --publish 8080:8080 \
  --publish 50000:50000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  $jenkins_image
           ;;
        5) docker container exec -it $jenkins_name /bin/sh -c 'test -f /var/jenkins_home/.ssh/jenkins_agent_key || ssh-keygen -t rsa -f /var/jenkins_home/.ssh/jenkins_agent_key'
           ;;
        6) url='http://localhost:8080'
           msg='Jenkins is fully up and running'
           while ! docker logs $jenkins_name 2>&1 | grep "$msg"
           do
               echo "Sleeping till $msg"
               sleep 5
           done
           if which open 1>/dev/null
           then
               nohup open $url 1>/dev/null 2>&1 &
           else
               echo "Please open $url in your browser."
           fi
           ;;
        # TBD: setting up SSH agent later
        7) if ! docker ps | grep " $ssh_agent_name1"
           then
               jenkins_agent_public_key=$(docker container exec -it $jenkins_name cat /var/jenkins_home/.ssh/jenkins_agent_key.pub)
               docker run \
                      --network $jenkins_network \
                      --network-alias jenkins-agent \
                      --detach \
                      --rm \
                      --name=$ssh_agent_name1 \
                      --publish 22:22 \
                      --env "JENKINS_AGENT_SSH_PUBKEY=$jenkins_agent_public_key" \
                      $ssh_agent_image
               VARS1="HOME=|USER=|MAIL=|LC_ALL=|LS_COLORS=|LANG="
               VARS2="HOSTNAME=|PWD=|TERM=|SHLVL=|LANGUAGE=|_="
               VARS="${VARS1}|${VARS2}"
               docker exec $ssh_agent_name1 /bin/sh -c "env | egrep -v '^(${VARS})' >> /etc/environment"
           fi
           ;;
        8) docker exec -u jenkins $ssh_agent_name1 /bin/sh -c 'test -f /home/jenkins/.ssh/id_rsa || ssh-keygen -t rsa -f /home/jenkins/.ssh/id_rsa'
           docker exec -u jenkins $ssh_agent_name1 /bin/sh -c "ssh-keygen -R github.com; ssh-keyscan -t rsa github.com >> /home/jenkins/.ssh/known_hosts"
           ;;
        9) if ! docker ps | grep " $ssh_agent_name2"
           then
               docker run \
                      --detach \
                      --rm \
                      --name=$ssh_agent_name2 \
                      --publish 22:22 \
                      --volume ~/.ssh:/home/jenkins/.ssh:ro \
                      $ssh_agent_image
               VARS1="HOME=|USER=|MAIL=|LC_ALL=|LS_COLORS=|LANG="
               VARS2="HOSTNAME=|PWD=|TERM=|SHLVL=|LANGUAGE=|_="
               VARS="${VARS1}|${VARS2}"
               docker exec $ssh_agent_name2 /bin/sh -c "env | egrep -v '^(${VARS})' >> /etc/environment"
           fi
           ;;
    esac
done
