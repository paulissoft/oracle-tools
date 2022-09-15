ARG SQLCL_ZIP=sqlcl-21.4.1.17.1458.zip
ARG SQLCL_URL=https://download.oracle.com/otn_software/java/sqldeveloper/$SQLCL_ZIP
ARG IMAGE=jenkins/agent:latest

FROM $IMAGE

# Labels.

#LABEL maintainer="paulissoft@gmail.com"

# Used by GitHub to link to the site, see https://blog.codecentric.de/en/2021/03/github-container-registry/
LABEL org.opencontainers.image.source="https://github.com/paulissoft/oracle-tools"
LABEL org.opencontainers.image.title="pato-jenkins-agent"
LABEL org.opencontainers.image.description="Paulissoft Application Tools for Oracle - Jenkins agent"
  
# From https://medium.com/@chamilad/lets-make-your-docker-image-better-than-90-of-existing-ones-8b1e5de950d
#LABEL org.label-schema.schema-version="1.0"
#LABEL org.label-schema.name="ghcr.io/paulissoft/pato-jenkins-agent"
#LABEL org.label-schema.description="Paulissoft Application Tools for Oracle - Jenkins agent"
#LABEL org.label-schema.url="https://github.com/paulissoft/oracle-tools"

USER root
# Install Maven and Docker
RUN apt-get update -y -q && \
		apt-get upgrade -y -q && \
		apt-get install -y -q maven git curl unzip openssh-client ca-certificates lsb-release iputils-ping
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli iputils-ping

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

# Let github.com be a known host for user jenkins
USER jenkins
RUN mkdir -m 700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
