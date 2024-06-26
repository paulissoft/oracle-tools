## -*- mode: make -*-

GIT      := git
PERL     := perl
BRANCH   := master
MVN      := mvn

.PHONY: tag

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
