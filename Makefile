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

PROJECT_NAME=cvt-website
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

.PHONY: build
build: ./out/.docker_hash
	${DOCKER_RUN_BUILD} sh -c "make build-local"

.PHONY: test
test: ./out/.docker_hash
	${DOCKER_RUN_BUILD} sh -c "make test-local"

.PHONY: format
format: ./out/.docker_hash
	${DOCKER_RUN_BUILD} sh -c "make format-local"

.PHONY: format-fix
format-fix: ./out/.docker_hash
	${DOCKER_RUN_BUILD} sh -c "make format-fix-local"

.PHONY: dev
dev: ./out/.docker_hash
	${DOCKER_RUN_BUILD} sh -c "make dev-local"

./out/.docker_hash: Dockerfile | setup-hooks out
ifndef NON_CONTAINER_BUILD
ifeq ("$(wildcard $(ENV_FILE))","")
	$(error You need to create an env file at ${ENV_FILE}, see .env.template for required keys)
endif
	@if ! docker buildx ls | grep -q ${BUILD_CONTAINER_NAME}; then\
		docker buildx create --name ${BUILD_CONTAINER_NAME} --use;\
	fi
	@echo "🐳 Building our docker build image..."
	docker buildx build --load -t ${BUILD_CONTAINER_NAME} -f ${BUILD_CONTAINER_DOCKER_FILE} --build-arg CONTAINER_SOURCE_MOUNT=${CONTAINER_SOURCE_MOUNT} --cache-to type=gha,mode=max --cache-from type=gha .
else
	@echo "🐳 Building locally, skipping docker image creation"	
endif
	echo "BLANK" > ./out/.docker_hash

./node_modules/.make_marker: package-lock.json | out
	@echo "💾 Installing npm dependencies"
	${DOCKER_RUN_BUILD} npm ci --ignore-scripts
	${DOCKER_RUN_BUILD} echo "BLANK" > ./node_modules/.make_marker


# LOCAL COMMANDS

.PHONY: all-local
all-local: format-local lint-local build-local test-local release-local

.PHONY: format-local
format-local: ./node_modules/.make_marker info-local
	npx prettier . --check

.PHONY: format-fix-local
format-fix: ./node_modules/.make_marker
	npx prettier . --write

.PHONY: build-local
build-local: ./node_modules/.make_marker info-local
	@echo "🛠 Building..."
	rm -rf dist
	npx parcel build docs/index.html

.PHONY: test-local
test-local: ./node_modules/.make_marker info-local

.PHONY: dev-local
dev-local: ./node_modules/.make_marker
	@echo "📟 Running dev server..."
	npx parcel docs/index.html

.PHONY: clean
clean:
	@echo "🧹 Cleaning..."
	rm -rf node_modules
	rm -rf out
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
prepare-commit-msg: ./node_modules/.make_marker
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

.PHONY: dev-setup
dev-setup:
ifndef GIT_NAME
	$(error GIT_NAME is not set)
endif
ifndef GIT_EMAIL
	$(error GIT_EMAIL is not set)
endif
	git config --global user.name "${GIT_NAME}"
	git config --global user.email "${GIT_EMAIL}"