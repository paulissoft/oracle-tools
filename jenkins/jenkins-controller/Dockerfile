ARG JENKINS_IMAGE=jenkins/jenkins:latest
FROM $JENKINS_IMAGE

USER root
RUN apt-get update && apt-get install -y iputils-ping

USER jenkins

# see also https://github.com/jenkinsci/docker

COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY jenkins.yaml /var/jenkins_home/jenkins.yaml

RUN jenkins-plugin-cli --plugin-file  /usr/share/jenkins/ref/plugins.txt

# No banner to install additional plugins
# RUN echo 2.0 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state

# Let github.com be a known host for user jenkins
RUN mkdir -m 700 /var/jenkins_home/.ssh && ssh-keyscan github.com >> /var/jenkins_home/.ssh/known_hosts
