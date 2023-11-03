#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$DIR/.."

log() {
  echo "$(basename ${BASH_SOURCE[0]}): $@"
}

install_hooks() {
  git config core.hooksPath \
    || git config core.hooksPath ./.dev/hooks
}

permissions() {
  chmod +x ./.dev/hooks/pre-commit
  chmod +x ./.dev/hooks/commit-msg
  chmod +x ./.dev/hooks/post-checkout
  chmod +x ./.dev/hooks/prepare-commit-msg
}

log 're/configuring hooks...'
install_hooks
permissions