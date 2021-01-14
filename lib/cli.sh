#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Updates the CLI to the latest version.
#
# Arguments:
#   $1 Version to update to (optional)
# ------------------------------------------------------------------------------
function bashio::cli.update() {
    local version=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${version}"; then
        version=$(bashio::var.json version "${version}")
        bashio::api.supervisor POST /cli/update "${version}"
    else
        bashio::api.supervisor POST /cli/update
    fi
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Returns a JSON object with generic version information about the CLI.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::cli() {
    local cache_key=${1:-'cli.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'cli.info'; then
        info=$(bashio::cache.get 'cli.info')
    else
        info=$(bashio::api.supervisor GET /cli/info false)
        bashio::cache.set 'cli.info' "${info}"
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
# Returns the Home Assistant CLI version used.
# ------------------------------------------------------------------------------
function bashio::cli.version() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::cli 'cli.info.version' '.version'
}

# ------------------------------------------------------------------------------
# Returns the latest version of the CLI.
# ------------------------------------------------------------------------------
function bashio::cli.version_latest() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::cli 'cli.info.version_latest' '.version_latest'
}

# ------------------------------------------------------------------------------
# Checks if there is an update available for the CLI.
# ------------------------------------------------------------------------------
function bashio::cli.update_available() {
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::cli 'cli.info.update_available' '.update_available // false'
}

# ------------------------------------------------------------------------------
# List all available stats about the CLI.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::cli.stats() {
    local cache_key=${1:-'cli.stats'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'cli.stats'; then
        info=$(bashio::cache.get 'cli.stats')
    else
        info=$(bashio::api.supervisor GET /cli/stats false)
        bashio::cache.set 'cli.stats' "${info}"
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
# Returns CPU usage from the CLI.
# ------------------------------------------------------------------------------
function bashio::cli.cpu_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::cli.stats 'cli.stats.cpu_percent' '.cpu_percent'
}

# ------------------------------------------------------------------------------
# Returns memory usage from the CLI.
# ------------------------------------------------------------------------------
function bashio::cli.memory_usage() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::cli.stats 'cli.stats.memory_usage' '.memory_usage'
}

# ------------------------------------------------------------------------------
# Returns memory limit from the CLI.
# ------------------------------------------------------------------------------
function bashio::cli.memory_limit() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::cli.stats 'cli.stats.memory_limit' '.memory_limit'
}

# ------------------------------------------------------------------------------
# Returns memory usage in percent from the CLI.
# ------------------------------------------------------------------------------
function bashio::cli.memory_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::cli.stats 'cli.stats.memory_percent' '.memory_percent'
}

# ------------------------------------------------------------------------------
# Returns outgoing network usage from the CLI.
# ------------------------------------------------------------------------------
function bashio::cli.network_tx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::cli.stats 'cli.stats.network_tx' '.network_tx'
}

# ------------------------------------------------------------------------------
# Returns incoming network usage from the CLI.
# ------------------------------------------------------------------------------
function bashio::cli.network_rx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::cli.stats 'cli.stats.network_rx' '.network_rx'
}

# ------------------------------------------------------------------------------
# Returns disk read usage from the CLI.
# ------------------------------------------------------------------------------
function bashio::cli.blk_read() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::cli.stats 'cli.stats.blk_read' '.blk_read'
}

# ------------------------------------------------------------------------------
# Returns disk write usage from the CLI.
# ------------------------------------------------------------------------------
function bashio::cli.blk_write() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::cli.stats 'cli.stats.blk_write' '.blk_write'
}
