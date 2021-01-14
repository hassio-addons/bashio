#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Updates the audio server to the latest version.
#
# Arguments:
#   $1 Version to update to (optional)
# ------------------------------------------------------------------------------
function bashio::audio.update() {
    local version=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${version}"; then
        version=$(bashio::var.json version "${version}")
        bashio::api.supervisor POST /audio/update "${version}"
    else
        bashio::api.supervisor POST /audio/update
    fi
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Reloads the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.reload() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /audio/reload
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Restarts the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.restart() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /audio/restart
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Returns the logs created by the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.logs() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor GET /audio/logs true
}

# ------------------------------------------------------------------------------
# Returns a JSON object with generic version information about audio the server.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::audio() {
    local cache_key=${1:-'audio.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'audio.info'; then
        info=$(bashio::cache.get 'audio.info')
    else
        info=$(bashio::api.supervisor GET /audio/info false)
        bashio::cache.set 'audio.info' "${info}"
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
# Returns the audio server version used.
# ------------------------------------------------------------------------------
function bashio::audio.version() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio 'audio.info.version' '.version'
}

# ------------------------------------------------------------------------------
# Returns the latest version of the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.version_latest() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio 'audio.info.version_latest' '.version_latest'
}

# ------------------------------------------------------------------------------
# Checks if there is an update available for the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.update_available() {
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::audio 'audio.info.update_available' '.update_available // false'
}

# ------------------------------------------------------------------------------
# Returns the host of the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.host() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio 'audio.info.host' '.host'
}

# ------------------------------------------------------------------------------
# List all available stats about the audio server.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::audio.stats() {
    local cache_key=${1:-'audio.stats'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'audio.stats'; then
        info=$(bashio::cache.get 'audio.stats')
    else
        info=$(bashio::api.supervisor GET /audio/stats false)
        bashio::cache.set 'audio.stats' "${info}"
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
# Returns CPU usage from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.cpu_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.cpu_percent' '.cpu_percent'
}

# ------------------------------------------------------------------------------
# Returns memory usage from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.memory_usage() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.memory_usage' '.memory_usage'
}

# ------------------------------------------------------------------------------
# Returns memory limit from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.memory_limit() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.memory_limit' '.memory_limit'
}

# ------------------------------------------------------------------------------
# Returns memory usage in percent from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.memory_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.memory_percent' '.memory_percent'
}

# ------------------------------------------------------------------------------
# Returns outgoing network usage from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.network_tx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.network_tx' '.network_tx'
}

# ------------------------------------------------------------------------------
# Returns incoming network usage from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.network_rx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.network_rx' '.network_rx'
}

# ------------------------------------------------------------------------------
# Returns disk read usage from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.blk_read() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.blk_read' '.blk_read'
}

# ------------------------------------------------------------------------------
# Returns disk write usage from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.blk_write() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.blk_write' '.blk_write'
}
