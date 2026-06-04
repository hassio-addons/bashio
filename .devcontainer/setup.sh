#!/usr/bin/env bash
# ==============================================================================
# Provisions the development toolchain used by the bashio CI pipeline so a
# contributor can run the exact same checks locally inside the devcontainer.
#
# The GitHub CLI, Node.js (for Prettier) and Python are provided by the
# devcontainer features. This script installs the remaining tools and pins
# them to the versions referenced by the CI workflow and the pre-commit
# configuration of this repository.
# ==============================================================================
set -o errexit
set -o nounset
set -o pipefail

# Tool versions, kept in sync with .pre-commit-config.yaml and ci.yaml.
readonly SHELLCHECK_VERSION="0.11.0"
readonly SHFMT_VERSION="3.13.1"
readonly BATS_VERSION="1.12.0"
readonly PRETTIER_VERSION="3.8.3"
readonly CODESPELL_VERSION="2.4.2"
readonly YAMLLINT_VERSION="1.38.0"

# Resolve the host architecture for the upstream release downloads.
arch="$(dpkg --print-architecture)"
case "${arch}" in
    amd64) shellcheck_arch="x86_64" ;;
    arm64) shellcheck_arch="aarch64" ;;
    *)
        echo "Unsupported architecture: ${arch}" >&2
        exit 1
        ;;
esac

echo "Updating package lists..."
sudo apt-get update

echo "Installing jq..."
sudo apt-get install --yes --no-install-recommends jq

echo "Installing shellcheck ${SHELLCHECK_VERSION}..."
tmp="$(mktemp --directory)"
curl --fail --silent --show-error --location \
    "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.${shellcheck_arch}.tar.xz" |
    tar --extract --xz --directory "${tmp}"
sudo install "${tmp}/shellcheck-v${SHELLCHECK_VERSION}/shellcheck" /usr/local/bin/shellcheck
rm --recursive --force "${tmp}"

echo "Installing shfmt ${SHFMT_VERSION}..."
sudo curl --fail --silent --show-error --location \
    --output /usr/local/bin/shfmt \
    "https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/shfmt_v${SHFMT_VERSION}_linux_${arch}"
sudo chmod +x /usr/local/bin/shfmt

echo "Installing bats ${BATS_VERSION}..."
tmp="$(mktemp --directory)"
curl --fail --silent --show-error --location \
    "https://github.com/bats-core/bats-core/archive/refs/tags/v${BATS_VERSION}.tar.gz" |
    tar --extract --gzip --directory "${tmp}"
sudo "${tmp}/bats-core-${BATS_VERSION}/install.sh" /usr/local
rm --recursive --force "${tmp}"

echo "Installing Prettier ${PRETTIER_VERSION}..."
sudo npm install --global "prettier@${PRETTIER_VERSION}"

echo "Installing Python based tooling (codespell, yamllint, prek)..."
pip install --user --no-warn-script-location \
    "codespell==${CODESPELL_VERSION}" \
    "yamllint==${YAMLLINT_VERSION}" \
    prek

echo "Toolchain installation complete."
