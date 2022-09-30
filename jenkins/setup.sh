#!/bin/bash -eux

test -n "$(docker-compose ls jenkins | grep running)" || \
    docker-compose down --remove-orphans
docker-compose build
docker-compose up -d
