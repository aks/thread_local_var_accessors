#!/bin/bash
set -o errexit
set -o nounset
set -o xtrace
set -o pipefail

echo "export BUNDLER_VERSION=$(tail -1 <Gemfile.lock | tr -d ' ')" >> "${BASH_ENV}"
source "${BASH_ENV}"
echo Setting Bundler Version to "${BUNDLER_VERSION}"
