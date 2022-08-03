#!/bin/bash
set -eux -o pipefail

env

# Requirements
npm install --global yarn || true

# Determine our version and build date
root_dir="$(git rev-parse --show-toplevel)"
pushd "${root_dir}" > /dev/null
IFS="-" read BASE_VERSION _other <<< "$(make version)"
export VAULT_VERSION=$BASE_VERSION
build_date="$(make build-date)"
export VAULT_BUILD_DATE=$build_date
full_version="$(make version)"
revision="$(git rev-parse HEAD)"
export VAULT_REVISION=$revision
popd > /dev/null

# Go to the UI directory of the Vault repo and build the UI
pushd "${root_dir}/ui" > /dev/null
yarn install --ignore-optional
npm rebuild node-sass
yarn --verbose run build
popd > /dev/null

# Go to the root directory of the repo and build Vault
pushd "${root_dir}" > /dev/null
mkdir -p out dist
make build
zip -r -j ${ARTIFACT_PATH}/vault.zip dist/
popd > /dev/null
