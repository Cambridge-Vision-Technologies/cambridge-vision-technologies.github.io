#!make
SHELL := /bin/bash
GIT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
GIT_COMMIT:=$(shell git rev-parse --short HEAD)
GIT_REPOSITORY:=${GIT_REPOSITORY}
GITHUB_TOKEN:=${GITHUB_TOKEN}
GIT_NAME:=${GIT_NAME}
GIT_EMAIL:=${GIT_EMAIL}
CI:=${CI}

ifndef VERSION
	LABEL=${GIT_COMMIT}
else
	LABEL=${VERSION}
endif

CONTAINER_SOURCE_MOUNT=/workspaces/source
BUILD_CONTAINER_NAME=${GIT_REPOSITORY}
BUILDER_NAME=${GIT_REPOSITORY}-builder
BUILD_CONTAINER_DOCKER_FILE=Dockerfile
PWD = $(shell /bin/pwd -P)
ENV_FILE=~/${GIT_REPOSITORY}.env

ifndef NON_CONTAINER_BUILD
# Check for env file
	DOCKER_RUN_BUILD=docker run -i --rm --volume "${PWD}/:$(CONTAINER_SOURCE_MOUNT)/" --volume /var/run/docker.sock:/var/run/docker.sock --volume "${PWD}/.docker-npm-cache/:/root/.npm" --volume "${PWD}/.docker-node-modules/:$(CONTAINER_SOURCE_MOUNT)/node_modules" --env-file ${ENV_FILE} $(BUILD_CONTAINER_NAME) 
	DOCKER_RUN_BUILD_INTERACTIVE =docker run --rm -it --volume "${PWD}/:$(CONTAINER_SOURCE_MOUNT)/" --volume /var/run/docker.sock:/var/run/docker.sock --volume "${PWD}/.docker-npm-cache/:/root/.npm" --volume "${PWD}/.docker-node-modules/:$(CONTAINER_SOURCE_MOUNT)/node_modules" --env-file ${ENV_FILE} $(BUILD_CONTAINER_NAME) 
endif

.PHONY: all
all: format test build release

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

.PHONY: release
release: ./out/.docker_hash
	${DOCKER_RUN_BUILD} sh -c "make release-local"

./out/.docker_hash: Dockerfile | setup-hooks out
ifndef NON_CONTAINER_BUILD
	sh -c "make env"
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
	npm ci --ignore-scripts
	echo "BLANK" > ./node_modules/.make_marker


# LOCAL COMMANDS

.PHONY: all-local
all-local: format-local lint-local build-local test-local release-local

.PHONY: format-local
format-local: ./node_modules/.make_marker info-local
	npx prettier . --check

.PHONY: format-fix-local
format-fix-local: ./node_modules/.make_marker info-local
	npx prettier . --write

.PHONY: build-local
build-local: dist info-local

.PHONY: dist
dist: ./node_modules/.make_marker info-local
	@echo "🛠 Building..."
	rm -rf dist
	npx parcel build docs/index.html

.PHONY: test-local
test-local: ./node_modules/.make_marker info-local

.PHONY: dev-local
dev-local: ./node_modules/.make_marker info-local
	@echo "📟 Running dev server..."
	npx parcel docs/index.html

.PHONY: release-local 
release-local: ./out/.release_marker info-local

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

.PHONY: commit-msg
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
	git config --global --add safe.directory ${CONTAINER_SOURCE_MOUNT}

out/.release_marker: dist release.config.js package-lock.json README.md | out
	@echo "💸 Releasing..."
ifndef GITHUB_TOKEN
	$(error GITHUB_TOKEN is not set)
endif
ifndef GIT_COMMIT
	$(error GIT_COMMIT is not set)
endif
	gh auth setup-git && npx semantic-release
	echo "BLANK" > ./out/.release_marker

.PHONY: version
version:
ifndef LABEL
	$(error LABEL is not set)
endif
	echo "VERSION: ${LABEL}"
	sed -i 's/0.0.0-development/${LABEL}/g' ./dist/index.html
	sed -i 's/0.0.0-development/${LABEL}/g' ./dist/about.html
	sed -i 's/0.0.0-development/${LABEL}/g' ./dist/technology.html
	sed -i 's/0.0.0-development/${LABEL}/g' ./dist/problem.html

.PHONY: env
env:
ifeq ("$(wildcard $(ENV_FILE))","")
ifndef GITHUB_TOKEN
	$(error creating .env file: GITHUB_TOKEN is not set, did you make a local .env file?)
endif
ifndef GIT_NAME
	$(error creating .env file: GIT_NAME is not set, did you make a local .env file?)
endif
ifndef GIT_EMAIL
	$(error creating .env file: GIT_EMAIL is not set, did you make a local .env file?)
endif
ifndef GITHUB_REPOSITORY
	$(error creating .env file: GITHUB_REPOSITORY is not set, did you make a local .env file?)
endif
ifndef CI
	$(error creating .env file: CI is not set, did you make a local .env file?)
endif
	printf "NPM_TOKEN=${GITHUB_TOKEN}\nGITHUB_TOKEN=${GITHUB_TOKEN}\nGH_TOKEN=${GITHUB_TOKEN}\nGIT_NAME=${GIT_NAME}\nGIT_EMAIL=${GIT_EMAIL}\nGITHUB_REPOSITORY=${GITHUB_REPOSITORY}\nCI=${CI}" > $(ENV_FILE)
endif