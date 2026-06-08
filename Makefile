.PHONY: check lint test verify

check: verify

lint:
	scripts/validate-openapi.rb

test: lint

verify: lint
