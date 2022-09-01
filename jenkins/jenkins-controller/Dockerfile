ARG JENKINS_IMAGE=jenkins/jenkins:latest
ARG JENKINS_PLUGINS="blueocean:latest docker-workflow:latest"

FROM $JENKINS_IMAGE
USER jenkins

# must redeclare an ARG after FROM (see also https://benkyriakou.com/posts/docker-args-empty)
ARG JENKINS_PLUGINS
RUN jenkins-plugin-cli --plugins $JENKINS_PLUGINS
