#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Updates the Multicast plugin to the latest version.
#
# Arguments:
#   $1 Version to update to (optional)
# ------------------------------------------------------------------------------
function bashio::multicast.update() {
    local version=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${version}"; then
        version=$(bashio::var.json version "${version}")
        bashio::api.supervisor POST /multicast/update "${version}"
    else
        bashio::api.supervisor POST /multicast/update
    fi
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Restarts the Multicast plugin.
# ------------------------------------------------------------------------------
function bashio::multicast.restart() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /multicast/restart
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Returns the logs created by the Multicast plugin.
# ------------------------------------------------------------------------------
function bashio::multicast.logs() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor GET /multicast/logs true
}

# ------------------------------------------------------------------------------
# Returns a JSON object with generic information about the Multicast plugin.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::multicast() {
    local cache_key=${1:-'multicast.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'multicast.info'; then
        info=$(bashio::cache.get 'multicast.info')
    else
        info=$(bashio::api.supervisor GET /multicast/info false)
        bashio::cache.set 'multicast.info' "${info}"
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
# Returns the Multicast version used.
# ------------------------------------------------------------------------------
function bashio::multicast.version() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::multicast 'multicast.info.version' '.version'
}

# ------------------------------------------------------------------------------
# Returns the latest version of the Multicast plugin.
# ------------------------------------------------------------------------------
function bashio::multicast.version_latest() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::multicast 'multicast.info.version_latest' '.version_latest'
}

# ------------------------------------------------------------------------------
# Checks if there is an update available for the Multicast plugin.
# ------------------------------------------------------------------------------
function bashio::multicast.update_available() {
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::multicast 'multicast.info.update_available' '.update_available // false'
}

# ------------------------------------------------------------------------------
# List all available stats about the Multicast plugin.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::multicast.stats() {
    local cache_key=${1:-'multicast.stats'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'multicast.stats'; then
        info=$(bashio::cache.get 'multicast.stats')
    else
        info=$(bashio::api.supervisor GET /multicast/stats false)
        bashio::cache.set 'multicast.stats' "${info}"
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
# Returns CPU usage from the Multicast plugin.
# ------------------------------------------------------------------------------
function bashio::multicast.cpu_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::multicast.stats 'multicast.stats.cpu_percent' '.cpu_percent'
}

# ------------------------------------------------------------------------------
# Returns memory usage from the Multicast plugin.
# ------------------------------------------------------------------------------
function bashio::multicast.memory_usage() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::multicast.stats 'multicast.stats.memory_usage' '.memory_usage'
}

# ------------------------------------------------------------------------------
# Returns memory limit from the Multicast plugin.
# ------------------------------------------------------------------------------
function bashio::multicast.memory_limit() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::multicast.stats 'multicast.stats.memory_limit' '.memory_limit'
}

# ------------------------------------------------------------------------------
# Returns memory usage in percent from the Multicast plugin.
# ------------------------------------------------------------------------------
function bashio::multicast.memory_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::multicast.stats 'multicast.stats.memory_percent' '.memory_percent'
}

# ------------------------------------------------------------------------------
# Returns outgoing network usage from the Multicast plugin.
# ------------------------------------------------------------------------------
function bashio::multicast.network_tx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::multicast.stats 'multicast.stats.network_tx' '.network_tx'
}

# ------------------------------------------------------------------------------
# Returns incoming network usage from the Multicast plugin.
# ------------------------------------------------------------------------------
function bashio::multicast.network_rx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::multicast.stats 'multicast.stats.network_rx' '.network_rx'
}

# ------------------------------------------------------------------------------
# Returns disk read usage from the Multicast plugin.
# ------------------------------------------------------------------------------
function bashio::multicast.blk_read() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::multicast.stats 'multicast.stats.blk_read' '.blk_read'
}

# ------------------------------------------------------------------------------
# Returns disk write usage from the Multicast plugin.
# ------------------------------------------------------------------------------
function bashio::multicast.blk_write() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::multicast.stats 'multicast.stats.blk_write' '.blk_write'
}
