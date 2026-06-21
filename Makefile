.PHONY: check generate lint test build root-test verify

override SHELL := /bin/sh
override .SHELLFLAGS := -eu -c
ifneq ($(strip $(MAKEFILES)),)
$(error MAKEFILES must be empty; repository verification requires this Makefile to be loaded alone)
endif
override MAKEFILES :=
ifneq ($(origin MAKEFILE_LIST),file)
$(error MAKEFILE_LIST must not be overridden)
endif
override REPOSITORY_MAKEFILE := $(value MAKEFILE_LIST)
export REPOSITORY_MAKEFILE
override REPO_ROOT :=
override RUBY := ruby

override define RUN_IN_REPO
makefile=$${REPOSITORY_MAKEFILE# }; \
if [ -z "$$makefile" ] || [ ! -f "$$makefile" ]; then \
	printf '%s\n' 'repository Makefile path could not be resolved' >&2; \
	exit 1; \
fi; \
case "$$makefile" in \
	*/*) repo_directory=$${makefile%/*} ;; \
	*) repo_directory=. ;; \
esac; \
REPO_ROOT=$$(CDPATH= cd -- "$$repo_directory" && pwd -P); \
export REPO_ROOT; \
cd "$$REPO_ROOT" &&
endef

check: verify
	$(RUN_IN_REPO) scripts/check-baseline.sh

generate:
	$(RUN_IN_REPO) $(RUBY) scripts/generate-spec-md.rb

lint:
	$(RUN_IN_REPO) $(RUBY) scripts/validate-openapi.rb

test: lint
	$(RUN_IN_REPO) scripts/test-validator.sh
	$(RUN_IN_REPO) scripts/test-generator.sh

build: lint

root-test:
	$(RUN_IN_REPO) scripts/test-makefile-root.sh

verify: lint test build root-test
