.PHONY: check generate lint test build root-test verify

ifneq ($(origin MAKEFILE_LIST),file)
$(error MAKEFILE_LIST must not be overridden)
endif
override REPO_ROOT := $(shell path='$(subst ','"'"',$(MAKEFILE_LIST))'; path=$$(printf '%s' "$$path" | /usr/bin/sed 's/^ //'); directory=$$(/usr/bin/dirname -- "$$path"); CDPATH= cd -- "$$directory" && /bin/pwd -P)

check: verify
	cd "$(REPO_ROOT)" && scripts/check-baseline.sh

generate:
	cd "$(REPO_ROOT)" && scripts/generate-spec-md.rb

lint:
	cd "$(REPO_ROOT)" && scripts/validate-openapi.rb

test: lint
	cd "$(REPO_ROOT)" && scripts/test-validator.sh
	cd "$(REPO_ROOT)" && scripts/test-generator.sh

build: lint

root-test:
	cd "$(REPO_ROOT)" && scripts/test-makefile-root.sh

verify: lint test build root-test
