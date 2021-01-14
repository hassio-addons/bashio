#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Updates the Observer plugin to the latest version.
#
# Arguments:
#   $1 Version to update to (optional)
# ------------------------------------------------------------------------------
function bashio::observer.update() {
    local version=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${version}"; then
        version=$(bashio::var.json version "${version}")
        bashio::api.supervisor POST /observer/update "${version}"
    else
        bashio::api.supervisor POST /observer/update
    fi
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Returns a JSON object with generic information about the Observer plugin.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::observer() {
    local cache_key=${1:-'observer.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'observer.info'; then
        info=$(bashio::cache.get 'observer.info')
    else
        info=$(bashio::api.supervisor GET /observer/info false)
        bashio::cache.set 'observer.info' "${info}"
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
# Returns the Observer version used.
# ------------------------------------------------------------------------------
function bashio::observer.version() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::observer 'observer.info.version' '.version'
}

# ------------------------------------------------------------------------------
# Returns the latest version of the Observer plugin.
# ------------------------------------------------------------------------------
function bashio::observer.version_latest() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::observer 'observer.info.version_latest' '.version_latest'
}

# ------------------------------------------------------------------------------
# Checks if there is an update available for the Observer plugin.
# ------------------------------------------------------------------------------
function bashio::observer.update_available() {
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::observer 'observer.info.update_available' '.update_available // false'
}

# ------------------------------------------------------------------------------
# Returns the host of the Observer plugin.
# ------------------------------------------------------------------------------
function bashio::observer.host() {
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::observer 'observer.info.host' '.host'
}

# ------------------------------------------------------------------------------
# List all available stats about the Observer plugin.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::observer.stats() {
    local cache_key=${1:-'observer.stats'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'observer.stats'; then
        info=$(bashio::cache.get 'observer.stats')
    else
        info=$(bashio::api.supervisor GET /observer/stats false)
        bashio::cache.set 'observer.stats' "${info}"
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
# Returns CPU usage from the Observer plugin.
# ------------------------------------------------------------------------------
function bashio::observer.cpu_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::observer.stats 'observer.stats.cpu_percent' '.cpu_percent'
}

# ------------------------------------------------------------------------------
# Returns memory usage from the Observer plugin.
# ------------------------------------------------------------------------------
function bashio::observer.memory_usage() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::observer.stats 'observer.stats.memory_usage' '.memory_usage'
}

# ------------------------------------------------------------------------------
# Returns memory limit from the Observer plugin.
# ------------------------------------------------------------------------------
function bashio::observer.memory_limit() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::observer.stats 'observer.stats.memory_limit' '.memory_limit'
}

# ------------------------------------------------------------------------------
# Returns memory usage in percent from the Observer plugin.
# ------------------------------------------------------------------------------
function bashio::observer.memory_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::observer.stats 'observer.stats.memory_percent' '.memory_percent'
}

# ------------------------------------------------------------------------------
# Returns outgoing network usage from the Observer plugin.
# ------------------------------------------------------------------------------
function bashio::observer.network_tx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::observer.stats 'observer.stats.network_tx' '.network_tx'
}

# ------------------------------------------------------------------------------
# Returns incoming network usage from the Observer plugin.
# ------------------------------------------------------------------------------
function bashio::observer.network_rx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::observer.stats 'observer.stats.network_rx' '.network_rx'
}

# ------------------------------------------------------------------------------
# Returns disk read usage from the Observer plugin.
# ------------------------------------------------------------------------------
function bashio::observer.blk_read() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::observer.stats 'observer.stats.blk_read' '.blk_read'
}

# ------------------------------------------------------------------------------
# Returns disk write usage from the Observer plugin.
# ------------------------------------------------------------------------------
function bashio::observer.blk_write() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::observer.stats 'observer.stats.blk_write' '.blk_write'
}
