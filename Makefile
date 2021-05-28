## -*- mode: make -*-

GIT = git
PERL = perl

.PHONY: tag

# This is GNU specific I guess
VERSION = $(shell $(PERL) -ne 'print if (s/-Drevision=//)' .mvn/maven.config)

TAG = v$(VERSION)

tag:
	@$(PERL) -e 'my @argv = @ARGV; foreach (@ARGV) { die("Wrong tag version (@argv): only vX.Y.Z allowed") unless (s/^v\d+\.\d+\.\d+// && !m/SNAPSHOT/) }' $(TAG)
	$(GIT) tag -a $(TAG) -m "$(TAG)"
	$(GIT) push origin $(TAG)
