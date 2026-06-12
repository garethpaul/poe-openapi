.PHONY: check lint test build verify

check: verify
	scripts/check-baseline.sh

lint:
	scripts/validate-openapi.rb

test: lint
	scripts/test-validator.sh

build: lint

verify: lint test build
