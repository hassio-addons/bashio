#!/usr/bin/env bash
# ==============================================================================
# Community Hass.io Add-ons: Bashio
# Bashio is an bash function library for use with Hass.io add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Updates HassOS to the latest version.
#
# Arguments:
#   $1 Version to update to (optional)
# ------------------------------------------------------------------------------
function bashio::hassos.update() {
    local version=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${version}"; then
        version=$(bashio::var.json version "${version}")
        bashio::api.hassio POST /hassos/update "${version}"
    else
        bashio::api.hassio POST /hassos/update
    fi
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Updates HassOS CLI to the latest version.
#
# Arguments:
#   $1 Version to update to (optional)
# ------------------------------------------------------------------------------
function bashio::hassos.update_cli() {
    local version=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${version}"; then
        version=$(bashio::var.json version "${version}")
        bashio::api.hassio POST /hassos/update/cli "${version}"
    else
        bashio::api.hassio POST /hassos/update/cli
    fi
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Load HassOS host configuration from USB stick.
# ------------------------------------------------------------------------------
function bashio::hassos.config_sync() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST /hassos/config/sync
}

# ------------------------------------------------------------------------------
# Returns a JSON object with generic Home Asssistant information.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::hassos() {
    local cache_key=${1:-'hassos.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'hassos.info'; then
        info=$(bashio::cache.get 'hassio.hassos')
    else
        info=$(bashio::api.hassio GET /hassos/info false)
        bashio::cache.set 'hassos.info' "${info}"
    fi

    response="${info}"
    if bashio::var.has_value "${filter}"; then
        response=$(bashio::jq "${info}" "${filter}")
    fi

    bashio::cache.set "${cache_key}" "${response}"
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Returns the version of HassOS.
# ------------------------------------------------------------------------------
function bashio::hassos.version() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::hassos 'hassos.info.version' '.version'
}

# ------------------------------------------------------------------------------
# Returns the latest version of HassOS.
# ------------------------------------------------------------------------------
function bashio::hassos.version_latest() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::hassos 'hassos.info.version_latest' '.version_latest'
}

# ------------------------------------------------------------------------------
# Checks if there is an update available for the Supervisor.
# ------------------------------------------------------------------------------
function bashio::hassos.update_available() {
    local version
    local last_version

    bashio::log.trace "${FUNCNAME[0]}"

    version=$(bashio::hassos.version)
    last_version=$(bashio::hassos.last_version)

    if [[ "${version}" = "${last_version}" ]]; then
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Returns the CLI version of HassOS.
# ------------------------------------------------------------------------------
function bashio::hassos.version_cli() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::hassos 'hassos.info.version_cli' '.version_cli'
}

# ------------------------------------------------------------------------------
# Returns the latest CLI version of HassOS.
# ------------------------------------------------------------------------------
function bashio::hassos.version_cli_latest() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::hassos 'hassos.info.version_cli_latest' '.version_cli_latest'
}

# ------------------------------------------------------------------------------
# Checks if there is an update available for the Supervisor.
# ------------------------------------------------------------------------------
function bashio::hassos.update_available_cli() {
    local version
    local last_version

    bashio::log.trace "${FUNCNAME[0]}"

    version=$(bashio::hassos.version_cli)
    last_version=$(bashio::hassos.version_cli_latest)

    if [[ "${version}" = "${last_version}" ]]; then
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Returns the board running HassOS.
# ------------------------------------------------------------------------------
function bashio::hassos.board() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::hassos 'hassos.info.board' '.board'
}
