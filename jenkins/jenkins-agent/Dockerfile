ARG SQLCL_ZIP=sqlcl-21.4.1.17.1458.zip
ARG SQLCL_URL=https://download.oracle.com/otn_software/java/sqldeveloper/$SQLCL_ZIP
ARG IMAGE=jenkins/ssh-agent:latest

FROM $IMAGE as builder

USER root
# Install Maven
RUN apt-get update -y -q && \
		apt-get upgrade -y -q && \
		apt-get install -y -q maven curl unzip

# Install SQLcl

# must redeclare an ARG after FROM (see also https://benkyriakou.com/posts/docker-args-empty)
ARG SQLCL_ZIP
ARG SQLCL_URL
RUN mkdir -p /opt/oracle && \
    cd /opt/oracle && \
    curl -o $SQLCL_ZIP $SQLCL_URL && \
    ls -l $SQLCL_ZIP && \
    unzip $SQLCL_ZIP && \
    cd -

ENV SQL_HOME /opt/oracle/sqlcl
ENV TNS_ADMIN /opt/oracle/network/admin

# Setup Maven environment and run the build.sh script to download all Maven plugins
WORKDIR /tmp
RUN git clone --branch docker-socat  http://github.com/paulissoft/oracle-tools.git
WORKDIR /tmp/oracle-tools/jenkins/jenkins-agent
RUN ./build.sh

# FROM $IMAGE
# 
# USER root
# # Install Maven and Docker
# RUN apt-get update -y -q && \
# 		apt-get upgrade -y -q && \
# 		apt-get install -y -q maven openssh-client ca-certificates lsb-release iputils-ping
# RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
#   https://download.docker.com/linux/debian/gpg
# RUN echo "deb [arch=$(dpkg --print-architecture) \
#   signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
#   https://download.docker.com/linux/debian \
#   $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
# RUN apt-get update && apt-get install -y docker-ce-cli iputils-ping
# 
# # Let github.com be a known host for user jenkins
# USER jenkins
# RUN mkdir -p -m 755 ~/.m2/repository && mkdir -m 700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
# 
# # copy local repository with all downloaded plugins
# COPY --from=builder /home/jenkins/.m2/repository /home/jenkins/.m2/repository
# USER root
# COPY --from=builder /opt /opt
# USER jenkins
