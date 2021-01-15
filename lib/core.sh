#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Starts Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.start() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /core/start
}

# ------------------------------------------------------------------------------
# Stops Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.stop() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /core/stop
}

# ------------------------------------------------------------------------------
# Restarts Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.restart() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /core/restart
}

# ------------------------------------------------------------------------------
# Rebuild Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.rebuild() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /core/rebuild
}

# ------------------------------------------------------------------------------
# Updates Home Assistant to the latest version.
#
# Arguments:
#   $1 Version to update to (optional)
# ------------------------------------------------------------------------------
function bashio::core.update() {
    local version=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${version}"; then
        version=$(bashio::var.json version "${version}")
        bashio::api.supervisor POST /core/update "${version}"
    else
        bashio::api.supervisor POST /core/update
    fi
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Checks/validates your Home Assistant configuration.
# ------------------------------------------------------------------------------
function bashio::core.check() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /core/check
}

# ------------------------------------------------------------------------------
# Returns the logs created by Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.logs() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor GET /core/logs true
}

# ------------------------------------------------------------------------------
# Returns a JSON object with generic Home Asssistant information.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::core() {
    local cache_key=${1:-'core.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'core.info'; then
        info=$(bashio::cache.get 'core.info')
    else
        info=$(bashio::api.supervisor GET /core/info false)
        bashio::cache.set 'core.info' "${info}"
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
# Returns the version of Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.version() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core 'core.info.version' '.version'
}

# ------------------------------------------------------------------------------
# Returns the latest version of Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.version_latest() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core 'core.info.version_latest' '.version_latest'
}

# ------------------------------------------------------------------------------
# Checks if there is an update available for Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.update_available() {
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::core 'core.info.update_available' '.update_available // false'
}

# ------------------------------------------------------------------------------
# Returns the arch of Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.arch() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core 'core.info.arch' '.arch'
}

# ------------------------------------------------------------------------------
# Returns the machine info running Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.machine() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core 'core.info.machine' '.machine'
}

# ------------------------------------------------------------------------------
# Returns the Docker image of Home Assistant.
#
# Arguments:
#   $1 Image to set (optional).
# ------------------------------------------------------------------------------
function bashio::core.image() {
    local image=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${image}"; then
        image=$(bashio::var.json image "${image}")
        bashio::api.supervisor POST /core/options "${image}"
        bashio::cache.flush_all
    else
        bashio::core 'core.info.image' '.image'
    fi
}

# ------------------------------------------------------------------------------
# Returns whether or not a custom version of Home Assistant is installed.
# ------------------------------------------------------------------------------
function bashio::core.custom() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core 'core.info.custom' '.custom // false'
}

# ------------------------------------------------------------------------------
# Returns whether or not Home Assistant starts at device boot.
# ------------------------------------------------------------------------------
function bashio::core.boot() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core 'core.info.boot' '.boot // false'

# ------------------------------------------------------------------------------
}
# Returns the port number on which Home Assistant is running.
# ------------------------------------------------------------------------------
function bashio::core.port() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core 'core.port' '.port'
}

# ------------------------------------------------------------------------------
# Returns whether or not Home Assistant is running on SSL.
# ------------------------------------------------------------------------------
function bashio::core.ssl() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core 'core.info.ssl' '.ssl // false'
}

# ------------------------------------------------------------------------------
# Returns or sets whether or not Home Assistant is monitored by Watchdog.
#
# Arguments:
#   $1 True to enable watchdog, false otherwise (optional).
# ------------------------------------------------------------------------------
function bashio::core.watchdog() {
    local watchdog=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${watchdog}"; then
        watchdog=$(bashio::var.json watchdog "^${watchdog}")
        bashio::api.supervisor POST /core/options "${watchdog}"
        bashio::cache.flush_all
    else
        bashio::core 'core.info.watchdog' '.watchdog // false'
    fi
}

# ------------------------------------------------------------------------------
# List all available stats about Home Assistant.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::core.stats() {
    local cache_key=${1:-'core.stats'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'core.stats'; then
        info=$(bashio::cache.get 'core.stats')
    else
        info=$(bashio::api.supervisor GET /core/stats false)
        bashio::cache.set 'core.stats' "${info}"
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
# Returns CPU usage from Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.cpu_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core.stats 'core.stats.cpu_percent' '.cpu_percent'
}

# ------------------------------------------------------------------------------
# Returns memory usage from Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.memory_usage() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core.stats \
        'core.stats.memory_usage' \
        '.memory_usage'
}

# ------------------------------------------------------------------------------
# Returns memory limit from Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.memory_limit() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core.stats \
        'core.stats.memory_limit' \
        '.memory_limit'
}

# ------------------------------------------------------------------------------
# Returns memory usage in percent from Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.memory_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core.stats \
        'core.stats.memory_percent' \
        '.memory_percent'
}

# ------------------------------------------------------------------------------
# Returns outgoing network usage from Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.network_tx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core.stats 'core.stats.network_tx' '.network_tx'
}

# ------------------------------------------------------------------------------
# Returns incoming network usage from Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.network_rx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core.stats 'core.stats.network_rx' '.network_rx'
}

# ------------------------------------------------------------------------------
# Returns disk read usage from Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.blk_read() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core.stats 'core.stats.blk_read' '.blk_read'
}

# ------------------------------------------------------------------------------
# Returns disk write usage from Home Assistant.
# ------------------------------------------------------------------------------
function bashio::core.blk_write() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::core.stats 'core.stats.blk_write' '.blk_write'
}
