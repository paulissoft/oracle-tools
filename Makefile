## -*- mode: make -*-

GIT      := git
PERL     := perl
BRANCH   := master
MVN      := mvn

PLATFORM              := linux/amd64
UID                   := $(shell id -u)
GID                   := $(shell id -g)
ENV_FILE_POSTGRES     ?= $(MAKEFILE_DIR)postgres/.env
ENV_FILE              ?= $(MAKEFILE_DIR).env

ifneq '$(shell type podman 2>/dev/null)' ''

# podman / podman-compose

PODMAN                := PODMAN_IGNORE_CGROUPSV1_WARNING=1 podman
DOCKER                := $(PODMAN)
DOCKER_BUILDKIT       := $(DOCKER)
DOCKER_COMPOSE_CMD    := podman-compose

else

# docker / docker-compose

DOCKER                := docker
DOCKER_BUILDKIT       := DOCKER_BUILDKIT=1 docker buildx
DOCKER_COMPOSE_CMD    := DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 docker-compose

endif

DOCKER_BUILD          := $(DOCKER_BUILDKIT) build
#DOCKER_BUILD_OPTIONS  := --no-cache
DOCKER_BUILD_OPTIONS  := --platform $(PLATFORM) -t pato:latest .
COMPOSE_PROFILES      ?=
DOCKER_COMPOSE        := $(DOCKER_COMPOSE_CMD) $(COMPOSE_PROFILES)

MVN_CMD               := mvn --help

# export these variables to the environment when running commands
export PLATFORM UID GID ENV_FILE_POSTGRES ENV_FILE

.PHONY: help install deploy tag docker-build docker-run

# This is GNU specific I guess
VERSION = $(shell $(PERL) -ne 'print if (s/-Drevision=//)' .mvn/maven.config)

TAG = v$(VERSION)

help: ## This help.
	@$(PERL) -ne 'printf(qq(%-30s  %s\n), $$1, $$2) if (m/^((?:\w|[.%-])+):.*##\s*(.*)$$/)' $(MAKEFILE_LIST)
#	@echo home: $(home)

install: ## Install Java library
	@$(MVN) -N clean install
	@$(MVN) -f jdbc/pom.xml clean install

deploy: install ## Deploy Java library
	@$(MVN) -N deploy
	@$(MVN) -f jdbc/pom.xml deploy

tag: ## Tag the package on GitHub.
	@$(PERL) -e 'my @argv = @ARGV; foreach (@ARGV) { die("Wrong tag version (@argv): only v<MAJOR>.<MINOR>.<PATCH> allowed") unless (s/^v\d+\.\d+\.\d+// && !m/SNAPSHOT/) }' $(TAG)
	$(GIT) tag -a $(TAG) -m "$(TAG)"
	$(GIT) push origin $(TAG)
	gh release create $(TAG) --target $(BRANCH) --title "Release $(TAG)" --notes "See CHANGELOG"

docker-build: ## Do a Docker build
	@$(DOCKER_BUILD) $(DOCKER_BUILD_OPTIONS)

docker-run: docker-stop docker-build ## Start the container
	@$(DOCKER_COMPOSE) run pato $(MVN_CMD)

docker-stop:
	@$(DOCKER_COMPOSE) down 
