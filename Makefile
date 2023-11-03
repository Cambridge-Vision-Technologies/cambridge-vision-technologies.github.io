.PHONY: all
all: setup format build test

.PHONY: setup
setup:
	npm ci

format:
	npx prettier . --check

format-fix:
	npx prettier . --write

.PHONY: build
build: setup
	npx parcel build docs/index.html

.PHONY: test
test:

.PHONY: dev
dev: setup
	npx parcel docs/index.html

.PHONY: clean
clean:
	rm -rf node_modules
	rm -rf dist