FROM jenkins/ssh-agent:latest
RUN apt-get update -y -q && apt-get upgrade -y -q && apt-get install -y -q git openssh-client ca-certificates maven default-jdk
USER jenkins
RUN mkdir ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
USER root
