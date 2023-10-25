## -*- mode: make -*-

GIT      := git
PERL     := perl
BRANCH   := master

.PHONY: tag

# This is GNU specific I guess
VERSION = $(shell $(PERL) -ne 'print if (s/-Drevision=//)' .mvn/maven.config)

TAG = v$(VERSION)

help: ## This help.
	@perl -ne 'printf(qq(%-30s  %s\n), $$1, $$2) if (m/^((?:\w|[.%-])+):.*##\s*(.*)$$/)' $(MAKEFILE_LIST)
#	@echo home: $(home)

tag: ## Tag the package on GitHub.
	@$(PERL) -e 'my @argv = @ARGV; foreach (@ARGV) { die("Wrong tag version (@argv): only vX.Y.Z allowed") unless (s/^v\d+\.\d+\.\d+// && !m/SNAPSHOT/) }' $(TAG)
	$(GIT) tag -a $(TAG) -m "$(TAG)"
	$(GIT) push origin $(TAG)
	gh release create $(TAG) --target $(BRANCH) --title "Release $(TAG)" --notes "See CHANGELOG"
