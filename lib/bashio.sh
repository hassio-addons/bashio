#!/usr/bin/env bash
# ==============================================================================
# Community Hass.io Add-ons: Bashio
# Bashio is an bash function library for use with Hass.io add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================
set -o errexit  # Exit script when a command exits with non-zero status
set -o errtrace # Exit on error inside any functions or sub-shells
set -o nounset  # Exit script on use of an undefined variable
set -o pipefail # Return exit status of the last command in the pipe that failed

# ==============================================================================
# GLOBALS
# ==============================================================================

# Bashio version number
readonly BASHIO_VERSION="0.1.0"

# Stores the location of this library
readonly __BASHIO_LIB_DIR=$(dirname "${BASH_SOURCE[0]}")

# shellcheck source=lib/const.sh
source "${__BASHIO_LIB_DIR}/const.sh"

# Defaults
declare __BASHIO_HASSIO_API=${HASSIO_API:-${__BASHIO_DEFAULT_HASSIO_API}}
declare __BASHIO_HASSIO_TOKEN=${HASSIO_TOKEN:-${__BASHIO_DEFAULT_HASSIO_TOKEN}}
declare __BASHIO_ADDON_CONFIG=${HASSIO_ADDON_CONFIG:-${__BASHIO_DEFAULT_ADDON_CONFIG}}
declare __BASHIO_LOG_LEVEL=${LOG_LEVEL:-${__BASHIO_DEFAULT_LOG_LEVEL}}
declare __BASHIO_LOG_FORMAT=${LOG_FORMAT:-${__BASHIO_DEFAULT_LOG_FORMAT}}
declare __BASHIO_LOG_TIMESTAMP=${LOG_TIMESTAMP:-${__BASHIO_DEFAULT_LOG_TIMESTAMP}}
declare __BASHIO_HIBP_ENDPOINT=${HIBP_ENDPOINT:-${__BASHIO_DEFAULT_HIBP_ENDPOINT}}
declare __BASHIO_CACHE_DIR=${CACHE_DIR:-${__BASHIO_DEFAULT_CACHE_DIR}}
declare __BASHIO_HA_SECRETS=${HA_SECRETS:-${__BASHIO_DEFAULT_SECRETS}}

# ==============================================================================
# MODULES
# ==============================================================================
# shellcheck source=lib/color.sh
source "${__BASHIO_LIB_DIR}/color.sh"
# shellcheck source=lib/log.sh
source "${__BASHIO_LIB_DIR}/log.sh"

# shellcheck source=lib/fs.sh
source "${__BASHIO_LIB_DIR}/fs.sh"
# shellcheck source=lib/cache.sh
source "${__BASHIO_LIB_DIR}/cache.sh"

# shellcheck source=lib/addons.sh
source "${__BASHIO_LIB_DIR}/addons.sh"
# shellcheck source=lib/api.sh
source "${__BASHIO_LIB_DIR}/api.sh"
# shellcheck source=lib/config.sh
source "${__BASHIO_LIB_DIR}/config.sh"
# shellcheck source=lib/debug.sh
source "${__BASHIO_LIB_DIR}/debug.sh"
# shellcheck source=lib/exit.sh
source "${__BASHIO_LIB_DIR}/exit.sh"
# shellcheck source=lib/discovery.sh
source "${__BASHIO_LIB_DIR}/discovery.sh"
# shellcheck source=lib/dns.sh
source "${__BASHIO_LIB_DIR}/dns.sh"
# shellcheck source=lib/hardware.sh
source "${__BASHIO_LIB_DIR}/hardware.sh"
# shellcheck source=lib/hassos.sh
source "${__BASHIO_LIB_DIR}/hassos.sh"
# shellcheck source=lib/homeassistant.sh
source "${__BASHIO_LIB_DIR}/homeassistant.sh"
# shellcheck source=lib/host.sh
source "${__BASHIO_LIB_DIR}/host.sh"
# shellcheck source=lib/info.sh
source "${__BASHIO_LIB_DIR}/info.sh"
# shellcheck source=lib/jq.sh
source "${__BASHIO_LIB_DIR}/jq.sh"
# shellcheck source=lib/net.sh
source "${__BASHIO_LIB_DIR}/net.sh"
# shellcheck source=lib/pwned.sh
source "${__BASHIO_LIB_DIR}/pwned.sh"
# shellcheck source=lib/repositories.sh
source "${__BASHIO_LIB_DIR}/repositories.sh"
# shellcheck source=lib/secrets.sh
source "${__BASHIO_LIB_DIR}/secrets.sh"
# shellcheck source=lib/string.sh
source "${__BASHIO_LIB_DIR}/string.sh"
# shellcheck source=lib/supervisor.sh
source "${__BASHIO_LIB_DIR}/supervisor.sh"
# shellcheck source=lib/var.sh
source "${__BASHIO_LIB_DIR}/var.sh"
