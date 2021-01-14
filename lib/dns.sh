#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Updates the DNS to the latest version.
#
# Arguments:
#   $1 Version to update to (optional)
# ------------------------------------------------------------------------------
function bashio::dns.update() {
    local version=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${version}"; then
        version=$(bashio::var.json version "${version}")
        bashio::api.supervisor POST /dns/update "${version}"
    else
        bashio::api.supervisor POST /dns/update
    fi
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Reset the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.reset() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /dns/reset
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Restarts the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.restart() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /dns/restart
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Returns the logs created by the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.logs() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor GET /dns/logs true
}

# ------------------------------------------------------------------------------
# Returns a JSON object with generic version information about the DNS.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::dns() {
    local cache_key=${1:-'dns.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'dns.info'; then
        info=$(bashio::cache.get 'dns.info')
    else
        info=$(bashio::api.supervisor GET /dns/info false)
        bashio::cache.set 'dns.info' "${info}"
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
# Returns the Home Assistant DNS host.
# ------------------------------------------------------------------------------
function bashio::dns.host() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::dns 'dns.info.host' '.host'
}

# ------------------------------------------------------------------------------
# Returns the current version of the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.version() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::dns 'dns.info.version' '.version'
}

# ------------------------------------------------------------------------------
# Returns the latest version of the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.version_latest() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::dns 'dns.info.version_latest' '.version_latest'
}

# ------------------------------------------------------------------------------
# Checks if there is an update available for the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.update_available() {
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::dns 'dns.info.update_available' '.update_available // false'
}

# ------------------------------------------------------------------------------
# Returns a list of local DNS servers used by the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.locals() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::dns 'dns.info.locals' '.locals[]'
}

# ------------------------------------------------------------------------------
# Returns a list of DNS servers used by the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.servers() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::dns 'dns.info.servers' '.servers[]'
}

# ------------------------------------------------------------------------------
# List all available stats about the DNS.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::dns.stats() {
    local cache_key=${1:-'dns.stats'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'dns.stats'; then
        info=$(bashio::cache.get 'dns.stats')
    else
        info=$(bashio::api.supervisor GET /dns/stats false)
        bashio::cache.set 'dns.stats' "${info}"
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
# Returns CPU usage from the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.cpu_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::dns.stats 'dns.stats.cpu_percent' '.cpu_percent'
}

# ------------------------------------------------------------------------------
# Returns memory usage from the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.memory_usage() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::dns.stats 'dns.stats.memory_usage' '.memory_usage'
}

# ------------------------------------------------------------------------------
# Returns memory limit from the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.memory_limit() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::dns.stats 'dns.stats.memory_limit' '.memory_limit'
}

# ------------------------------------------------------------------------------
# Returns memory usage in percent from the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.memory_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::dns.stats 'dns.stats.memory_percent' '.memory_percent'
}

# ------------------------------------------------------------------------------
# Returns outgoing network usage from the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.network_tx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::dns.stats 'dns.stats.network_tx' '.network_tx'
}

# ------------------------------------------------------------------------------
# Returns incoming network usage from the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.network_rx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::dns.stats 'dns.stats.network_rx' '.network_rx'
}

# ------------------------------------------------------------------------------
# Returns disk read usage from the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.blk_read() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::dns.stats 'dns.stats.blk_read' '.blk_read'
}

# ------------------------------------------------------------------------------
# Returns disk write usage from the DNS.
# ------------------------------------------------------------------------------
function bashio::dns.blk_write() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::dns.stats 'dns.stats.blk_write' '.blk_write'
}
