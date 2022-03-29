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
ssh_agent_image=jenkins/ssh-agent:alpine
ssh_agent_name=agent1

export SQLCL_ZIP=sqlcl-21.4.1.17.1458.zip
export SQLCL_URL=https://download.oracle.com/otn_software/java/sqldeveloper/$SQLCL_ZIP

for nr
do
    echo "step: $nr"
    case $nr in
        1) docker network ls | grep " $jenkins_network " || docker network create $jenkins_network
           ;;
        2) docker ps | grep " $dind_image " || docker run \
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
           ;;
        3) cat <<'EOF' | docker build --build-arg SQLCL_ZIP --build-arg SQLCL_URL -t $jenkins_image -f - .
FROM jenkins/jenkins:latest-jdk11
USER root
RUN apt-get update && apt-get install -y lsb-release
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli
ARG SQLCL_ZIP
ARG SQLCL_URL
RUN cd /opt && \
    curl -o $SQLCL_ZIP $SQLCL_URL && unzip $SQLCL_ZIP && rm $SQLCL_ZIP && ln -s /opt/sqlcl/bin/sql /usr/local/bin && \
    mkdir -p /opt/sqlcl/network/admin && touch /opt/sqlcl/network/admin/tnsnames.ora && touch /opt/sqlcl/network/admin/sqlnet.ora && echo TNS_ADMIN=/opt/sqlcl/network/admin >> /etc/environment && \
    cd -
USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean:latest docker-workflow:latest"
EOF
           ;;
        4) docker ps | grep " $jenkins_image " || docker run \
  --name $jenkins_name \
  --rm \
  --detach \
  --network $jenkins_network \
  --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client \
  --env DOCKER_TLS_VERIFY=1 \
  --publish 8080:8080 \
  --publish 50000:50000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  $jenkins_image
           ;;
        5) docker container exec -it $jenkins_name /bin/sh -c 'test -f /var/jenkins_home/.ssh/id_rsa || ssh-keygen -t rsa -f /var/jenkins_home/.ssh/id_rsa' # generate SSH keys
           ;;
        6) nohup open http://localhost:8080 1>/dev/null 2>&1 &
           ;;
        # TBD: setting up SSH agent later
        7) docker container exec -it $jenkins_name /bin/sh -c 'test -f /var/jenkins_home/.ssh/jenkins_agent_key || ssh-keygen -t rsa -f /var/jenkins_home/.ssh/jenkins_agent_key' # generate SSH keys
           ;;
        8) if ! docker ps | grep " $ssh_agent_name"
           then
               jenkins_agent_public_key=$(docker container exec -it $jenkins_name cat /var/jenkins_home/.ssh/jenkins_agent_key.pub)
               docker run -d --rm --name=$ssh_agent_name -p 22:22 \
-e "JENKINS_AGENT_SSH_PUBKEY=$jenkins_agent_public_key" \
                      $ssh_agent_image
               VARS1="HOME=|USER=|MAIL=|LC_ALL=|LS_COLORS=|LANG="
               VARS2="HOSTNAME=|PWD=|TERM=|SHLVL=|LANGUAGE=|_="
               VARS="${VARS1}|${VARS2}"
               docker exec $ssh_agent_name sh -c "env | egrep -v '^(${VARS})' >> /etc/environment"
           fi
           ;;           
    esac
done
