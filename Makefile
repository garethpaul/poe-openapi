.PHONY: check lint test build verify

check: verify

lint:
	scripts/validate-openapi.rb

test: lint

build: lint

verify: lint test build
