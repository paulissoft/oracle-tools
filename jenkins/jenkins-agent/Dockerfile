ARG SQLCL_ZIP=sqlcl-21.4.1.17.1458.zip
ARG SQLCL_URL=https://download.oracle.com/otn_software/java/sqldeveloper/$SQLCL_ZIP
ARG MVND_VERSION=0.8.2
ARG MVND_ZIP_BASE=maven-mvnd-$MVND_VERSION-linux-amd64
ARG MVND_ZIP=$MVND_ZIP_BASE.zip
ARG MVND_DOWNLOAD_URL=https://github.com/apache/maven-mvnd/releases/download/$MVND_VERSION/$MVND_ZIP
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

# --------------
# Install Docker
# --------------

# Here we need several RUN commands since we create the docker list for the docker-ce-cli installation

RUN apt-get update -y -q && \
    apt-get install -y -q git curl unzip openssh-client ca-certificates lsb-release iputils-ping
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli

# --------------------
# Install Maven daemon
# --------------------

# must redeclare an ARG after FROM (see also https://benkyriakou.com/posts/docker-args-empty)
ARG MVND_ZIP_BASE
ARG MVND_ZIP
ARG MVND_DOWNLOAD_URL

WORKDIR /opt

ADD $MVND_DOWNLOAD_URL .

RUN unzip $MVND_ZIP && mv $MVND_ZIP_BASE mvnd

ENV MVND_HOME=/opt/mvnd

# -------------
# Install SQLcl
# -------------

# must redeclare an ARG after FROM (see also https://benkyriakou.com/posts/docker-args-empty)
ARG SQLCL_ZIP
ARG SQLCL_URL

WORKDIR /opt/oracle

ADD $SQLCL_URL .

# unpacks to sqlcl
RUN unzip $SQLCL_ZIP && ls -l /opt/oracle/sqlcl/bin/sql

ENV SQL_HOME=/opt/oracle/sqlcl

# -------
# SQL*Net
# -------

WORKDIR /opt/oracle/network/admin

WORKDIR /opt/oracle/wallet

RUN chmod -R 755 /opt

ENV TNS_ADMIN=/opt/oracle/network/admin

# -----------------------
# Update /etc/environment
# -----------------------

RUN echo "SQL_HOME=$SQL_HOME" >> /etc/environment && \
		echo "TNS_ADMIN=$TNS_ADMIN" >> /etc/environment && \
		echo "PATH=$MVND_HOME/bin:$PATH" >> /etc/environment && \
		cat /etc/environment
 
# ------------
# User jenkins
# ------------

# Let github.com be a known host for user jenkins
USER jenkins
RUN mkdir -m 700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

# As stated in the documentation, a inherits the directory content and permissions existing in the container.
# So when volume maven-local-repository attaches to /home/jenkins/.m2/repository,
# that directory must already exist and have the correct ownership
# otherwise it will be root giving Maven download permission problems.
# See also https://github.com/paulissoft/oracle-tools/issues/66.
RUN mkdir -m 755 -p /home/jenkins/.m2/repository
# Also create a workspace directory owned by jenkins
RUN mkdir -m 755 -p /home/jenkins/agent/workspace
