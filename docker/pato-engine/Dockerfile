ARG IMAGE=maven:3.9.9-eclipse-temurin-21-alpine
ARG SQLCL_ZIP=sqlcl-latest.zip
ARG SQLCL_URL=https://download.oracle.com/otn_software/java/sqldeveloper/$SQLCL_ZIP

FROM ${IMAGE}

# Labels.

#LABEL maintainer="paulissoft@gmail.com"

# Used by GitHub to link to the site, see https://blog.codecentric.de/en/2021/03/github-container-registry/
LABEL org.opencontainers.image.source="https://github.com/paulissoft/oracle-tools"
LABEL org.opencontainers.image.title="pato-engine"
LABEL org.opencontainers.image.description="Paulissoft Application Tools for Oracle - engine"

# -------------
# Install SQLcl
# -------------

# must redeclare an ARG after FROM (see also https://benkyriakou.com/posts/docker-args-empty)
ARG SQLCL_ZIP
ARG SQLCL_URL

WORKDIR /opt/oracle

ADD $SQLCL_URL .

# unpacks to sqlcl
RUN unzip $SQLCL_ZIP && ls -l /opt/oracle/sqlcl/bin/sql && rm $SQLCL_ZIP 

ENV SQL_HOME=/opt/oracle/sqlcl

# -------
# SQL*Net
# -------

WORKDIR /opt/oracle/network/admin

WORKDIR /opt/oracle/wallet

RUN chmod -R 755 /opt

ENV TNS_ADMIN=/opt/oracle/network/admin
