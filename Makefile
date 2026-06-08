.PHONY: lint test verify

lint:
	scripts/validate-openapi.rb

test: lint

verify: lint
