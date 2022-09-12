ARG SQLCL_ZIP=sqlcl-21.4.1.17.1458.zip
ARG SQLCL_URL=https://download.oracle.com/otn_software/java/sqldeveloper/$SQLCL_ZIP
ARG IMAGE=jenkins/ssh-agent:latest
ARG SCM_BRANCH=docker-socat

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

ARG SCM_BRANCH
ENV SCM_BRANCH=$SCM_BRANCH
ENV SCM_USERNAME=nobody
ENV SCM_EMAIL=nobody@gmail.com
ENV CONF_DIR=conf
ENV DB=orcl
ENV DB_USERNAME=ORACLE_TOOLS
# Use today as password (hoping the connection will fail)
ENV DB_PASSWORD=`date -Idate`
ENV DB_DIR=db
ENV DB_ACTIONS="db-info db-test db-generate-ddl-incr db-code-check db-generate-ddl-full"
ENV DB_ACTIONS="db-info"
ENV APEX_DIR=apex
ENV APEX_ACTIONS="apex-export apex-import"
ENV APEX_ACTIONS="apex-export"
ENV SCM_BRANCH_PREV=
ENV GIT='echo git'
ENV BUILD_NUMBER=0
ENV MVN_ARGS=--fail-never
ENV MVN_LOG_DIR=.

# Setup Maven environment and run the build.sh script to download all Maven plugins
WORKDIR /tmp
RUN git clone --branch $SCM_BRANCH  http://github.com/paulissoft/oracle-tools.git
WORKDIR /tmp/oracle-tools

RUN ./jenkins/process.sh

FROM $IMAGE

USER root
ENV SQL_HOME /opt/oracle/sqlcl
ENV TNS_ADMIN /opt/oracle/network/admin

COPY --from=builder /opt/oracle/sqlcl /opt/oracle/sql

# Install Maven and Docker
RUN apt-get update -y -q && \
		apt-get upgrade -y -q && \
		apt-get install -y -q maven openssh-client ca-certificates lsb-release iputils-ping
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli iputils-ping

# Let github.com be a known host for user jenkins
USER jenkins
RUN mkdir -p -m 755 ~/.m2/repository && mkdir -m 700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

# copy local repository with all downloaded plugins
COPY --from=builder /root/.m2/repository /home/jenkins/.m2/repository
