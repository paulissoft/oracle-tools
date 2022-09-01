FROM jenkins/ssh-agent:latest

# Install Maven, JDK and Docker
RUN apt-get update -y -q && \
		apt-get upgrade -y -q && \
		apt-get install -y -q curl git openssh-client ca-certificates maven default-jdk lsb-release zip unzip
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli iputils-ping

# Install SQLcl
ARG SQLCL_ZIP
ARG SQLCL_URL
RUN curl -o /tmp/$SQLCL_ZIP $SQLCL_URL
RUN mkdir -p /opt/oracle && \
    cd       /opt/oracle && \
    unzip    /tmp/$SQLCL_ZIP && \
    cd -
ENV SQL_HOME /opt/oracle/sqlcl

# Let github.com be a known host for user jenkins
USER jenkins
RUN mkdir ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
USER root



