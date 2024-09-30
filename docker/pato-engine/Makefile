## -*- mode: make -*-

# Otherwise perl may complain on a Mac
LANG                 := C

UID                  := $(shell id -u)
DOCKER               := docker
DOCKER_LOG_LEVEL     := INFO
DOCKER_OPTIONS       := --log-level $(DOCKER_LOG_LEVEL)
DOCKER_IMAGE_NAME    := pato-engine
DOCKER_IMAGE_TAG     := pato-engine
DOCKER_BUILD_OPTIONS := --tag $(DOCKER_IMAGE_TAG)
DOCKER_BUILD		     := DOCKER_BUILDKIT=1 $(DOCKER) $(DOCKER_OPTIONS) buildx build $(DOCKER_BUILD_OPTIONS) 
DOCKER_BUILD_FILE    := .

# run-time working directory and command
# - WORKDIR: usually the project root
# - CMD: something like "mvn -f <path relative to $(WORKDIR)>/pom.xml ..."
CMD                  := mvn --help
WORKDIR              := .

.PHONY: help

help: ## This help.
	@perl -ne 'printf(qq(%-30s  %s\n), $$1, $$2) if (m/^((?:\w|[.%-])+):.*##\s*(.*)$$/)' $(MAKEFILE_LIST)

build: ## Build the docker image
	@$(DOCKER_BUILD) $(DOCKER_BUILD_FILE)

# --name $(DOCKER_IMAGE_NAME) \

# See https://hub.docker.com/_/maven
run: ## Run the docker image
	@$(DOCKER) run -it --rm \
--env UID=$(UID) \
-v "$(HOME)/.m2":/root/.m2 \
-v "$(WORKDIR):/usr/src/mymaven" \
-v "$(TNS_ADMIN):/opt/oracle/network/admin" \
-w /usr/src/mymaven $(DOCKER_IMAGE_NAME) $(CMD)

