.PHONY: check generate lint test build verify

override REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

check: verify
	cd "$(REPO_ROOT)" && scripts/check-baseline.sh

generate: $(REPO_ROOT)/scripts/generate-spec-md.rb $(REPO_ROOT)/spec.yaml
	cd "$(REPO_ROOT)" && scripts/generate-spec-md.rb

lint:
	cd "$(REPO_ROOT)" && scripts/validate-openapi.rb

test: lint
	cd "$(REPO_ROOT)" && scripts/test-validator.sh
	cd "$(REPO_ROOT)" && scripts/test-generator.sh

build: lint

verify: lint test build
