.PHONY: check generate lint test build verify

check: verify
	scripts/check-baseline.sh

generate: scripts/generate-spec-md.rb spec.yaml
	scripts/generate-spec-md.rb

lint:
	scripts/validate-openapi.rb

test: lint
	scripts/test-validator.sh
	scripts/test-generator.sh

build: lint

verify: lint test build
