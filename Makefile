#!make
SHELL := /bin/bash
GIT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
GIT_COMMIT:=$(shell git rev-parse --short HEAD)
GIT_NAME:=${GIT_NAME}

ifndef VERSION
	LABEL=${GIT_COMMIT}
else
	LABEL=${VERSION}
endif

PROJECT_NAME=website
CONTAINER_SOURCE_MOUNT=/workspaces/${PROJECT_NAME}
BUILD_CONTAINER_NAME=cvt-website
BUILDER_NAME=cvt-website-builder
BUILD_CONTAINER_DOCKER_FILE=Dockerfile
PWD = $(shell /bin/pwd -P)
ENV_FILE=~/${PROJECT_NAME}.env

ifndef NON_CONTAINER_BUILD
# Check for env file
	DOCKER_RUN_BUILD=docker run -i --rm --volume "${PWD}/:$(CONTAINER_SOURCE_MOUNT)/" --volume /var/run/docker.sock:/var/run/docker.sock --volume "${PWD}/.docker-npm-cache/:/root/.npm" --volume "${PWD}/.docker-node-modules/:$(CONTAINER_SOURCE_MOUNT)/node_modules" --env-file ${ENV_FILE} $(BUILD_CONTAINER_NAME) 
	DOCKER_RUN_BUILD_INTERACTIVE =docker run --rm -it --volume "${PWD}/:$(CONTAINER_SOURCE_MOUNT)/" --volume /var/run/docker.sock:/var/run/docker.sock --volume "${PWD}/.docker-npm-cache/:/root/.npm" --volume "${PWD}/.docker-node-modules/:$(CONTAINER_SOURCE_MOUNT)/node_modules" --env-file ${ENV_FILE} $(BUILD_CONTAINER_NAME) 
endif

.PHONY: all
all: format build test

./node_modules/.make_marker: package-lock.json | out
	@echo "💾 Installing npm dependencies"
	${DOCKER_RUN_BUILD} npm ci --ignore-scripts
	${DOCKER_RUN_BUILD} echo "BLANK" > ./node_modules/.make_marker

.PHONY: format
format: ./node_modules/.make_marker info-local
	${DOCKER_RUN_BUILD} npx prettier . --check

.PHONY: format-fix
format-fix: ./node_modules/.make_marker
	${DOCKER_RUN_BUILD} npx prettier . --write

.PHONY: build
build: ./node_modules/.make_marker info-local
	@echo "🛠 Building..."
	rm -rf dist
	${DOCKER_RUN_BUILD} npx parcel build docs/index.html

.PHONY: test 
test: ./node_modules/.make_marker info-local

.PHONY: dev
dev: ./node_modules/.make_marker
	@echo "📟 Running dev server..."
	${DOCKER_RUN_BUILD} npx parcel docs/index.html

.PHONY: clean
clean:
	@echo "🧹 Cleaning..."
	rm -rf node_modules
	rm -rf dist
	rm -rf .docker-node-modules
	rm -rf .docker-nom-cache

# Commit management

.PHONY: setup-hooks
setup-hooks:
ifneq ($(CI), true)
	sh .dev/bootstrap.sh
endif

commit-msg:
	npx --no-install commitlint --edit ${COMMIT_FILE}

.PHONY: prepare-commit-msg
prepare-commit-msg:
	make prepare-commit-msg-local

.PHONY: prepare-commit-msg-local
prepare-commit-msg-local: ./node_modules/.make_marker
ifndef GIT_NAME
	$(error GIT_NAME is not set)
endif
ifndef GIT_EMAIL
	$(error GIT_EMAIL is not set)
endif
	git config --global user.name "${GIT_NAME}"
	git config --global user.email "${GIT_EMAIL}"
	node_modules/.bin/cz --hook

.PHONY: info-local
info-local: | setup-hooks
	@echo "🌱 Running in branch ${GIT_BRANCH}"
	@echo "🏷 Using GIT_COMMIT ${GIT_COMMIT}"
	@echo "📍 PWD is ${PWD}"

out:
	mkdir out