#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
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
function bashio::os.update() {
    local version=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${version}"; then
        version=$(bashio::var.json version "${version}")
        bashio::api.supervisor POST /os/update "${version}"
    else
        bashio::api.supervisor POST /os/update
    fi
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Load HassOS host configuration from USB stick.
# ------------------------------------------------------------------------------
function bashio::os.config_sync() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /os/config/sync
}

# ------------------------------------------------------------------------------
# Returns a JSON object with generic Home Assistant information.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::os() {
    local cache_key=${1:-'os.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'os.info'; then
        info=$(bashio::cache.get 'os.info')
    else
        info=$(bashio::api.supervisor GET /os/info false)
        bashio::cache.set 'os.info' "${info}"
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
function bashio::os.version() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::os 'os.info.version' '.version'
}

# ------------------------------------------------------------------------------
# Returns the latest version of HassOS.
# ------------------------------------------------------------------------------
function bashio::os.version_latest() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::os 'os.info.version_latest' '.version_latest'
}

# ------------------------------------------------------------------------------
# Checks if there is an update available for the Supervisor.
# ------------------------------------------------------------------------------
function bashio::os.update_available() {
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::os 'os.info.update_available' '.update_available // false'
}

# ------------------------------------------------------------------------------
# Returns the board running HassOS.
# ------------------------------------------------------------------------------
function bashio::os.board() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::os 'os.info.board' '.board'
}

# ------------------------------------------------------------------------------
# Returns the active boot.
# ------------------------------------------------------------------------------
function bashio::os.boot() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::os 'os.info.boot' '.boot'
}
