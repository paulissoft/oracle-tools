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

