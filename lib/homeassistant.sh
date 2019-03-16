#!/usr/bin/env bash
# ==============================================================================
# Community Hass.io Add-ons: Bashio
# Bashio is an bash function library for use with Hass.io add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Starts Home Assistant.
# ------------------------------------------------------------------------------
function bashio::homeassistant.start() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST /homeassistant/start
}

# ------------------------------------------------------------------------------
# Stops Home Assistant.
# ------------------------------------------------------------------------------
function bashio::homeassistant.stop() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST /homeassistant/stop
}

# ------------------------------------------------------------------------------
# Restarts Home Assistant.
# ------------------------------------------------------------------------------
function bashio::homeassistant.restart() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST /homeassistant/restart
}

# ------------------------------------------------------------------------------
# Updates Home Assistant to the latest version.
#
# Arguments:
#   $1 Version to update to (optional)
# ------------------------------------------------------------------------------
function bashio::homeassistant.update() {
    local version=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${version}"; then
        version=$(bashio::var.json version "${version}")
        bashio::api.hassio POST /homeassistant/update "${version}"
    else
        bashio::api.hassio POST /homeassistant/update
    fi
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Checks/validates your Home Assistant configuration.
# ------------------------------------------------------------------------------
function bashio::homeassistant.check() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST /homeassistant/check
}

# ------------------------------------------------------------------------------
# Returns the logs created by Home Assistant.
# ------------------------------------------------------------------------------
function bashio::homeassistant.logs() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio GET /homeassistant/logs true
}

# ------------------------------------------------------------------------------
# Returns a JSON object with generic Home Asssistant information.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::homeassistant() {
    local cache_key=${1:-'homeassistant.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'homeassistant.info'; then
        info=$(bashio::cache.get 'hassio.homeassistant')
    else
        info=$(bashio::api.hassio GET /homeassistant/info false)
        bashio::cache.set 'homeassistant.info' "${info}"
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
function bashio::homeassistant.version() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::homeassistant 'homeassistant.info.version' '.version'
}

# ------------------------------------------------------------------------------
# Returns the latest version of Home Assistant.
# ------------------------------------------------------------------------------
function bashio::homeassistant.last_version() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::homeassistant 'homeassistant.info.last_version' '.last_version'
}

# ------------------------------------------------------------------------------
# Checks if there is an update available for the Supervisor.
# ------------------------------------------------------------------------------
function bashio::supervisor.update_available() {
    local version
    local last_version

    bashio::log.trace "${FUNCNAME[0]}"

    version=$(bashio::homeassistant.version)
    last_version=$(bashio::homeassistant.last_version)

    if [[ "${version}" = "${last_version}" ]]; then
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Returns the arch of Home Assistant.
# ------------------------------------------------------------------------------
function bashio::homeassistant.arch() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::homeassistant 'homeassistant.info.arch' '.arch'
}

# ------------------------------------------------------------------------------
# Returns the machine info running Home Assistant.
# ------------------------------------------------------------------------------
function bashio::homeassistant.machine() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::homeassistant 'homeassistant.info.machine' '.machine'
}

# ------------------------------------------------------------------------------
# Returns the Docker image of Home Assistant.
#
# Arguments:
#   $1 Image to set (optional).
# ------------------------------------------------------------------------------
function bashio::homeassistant.image() {
    local image=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${image}"; then
        image=$(bashio::var.json image "${image}")
        bashio::api.hassio POST /homeassistant/options "${image}"
        bashio::cache.flush_all
    else
        bashio::homeassistant 'homeassistant.info.image' '.image'
    fi
}

# ------------------------------------------------------------------------------
# Returns whether or not a custom version of Home Assistant is installed.
# ------------------------------------------------------------------------------
function bashio::homeassistant.custom() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::homeassistant 'homeassistant.info.custom' '.custom // false'
}

# ------------------------------------------------------------------------------
# Returns whether or not Home Assistant starts at device boot.
# ------------------------------------------------------------------------------
function bashio::homeassistant.boot() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::homeassistant 'homeassistant.info.boot' '.boot // false'

# ------------------------------------------------------------------------------
}
# Returns the port number on which Home Assistant is running.
# ------------------------------------------------------------------------------
function bashio::homeassistant.port() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::homeassistant 'homeassistant.port' '.port'
}

# ------------------------------------------------------------------------------
# Returns whether or not Home Assistant is running on SSL.
# ------------------------------------------------------------------------------
function bashio::homeassistant.ssl() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::homeassistant 'homeassistant.info.ssl' '.ssl // false'
}

# ------------------------------------------------------------------------------
# Returns or sets whether or not Home Assistant is monitored by Watchdog.
#
# Arguments:
#   $1 True to enable watchdog, false otherwise (optional).
# ------------------------------------------------------------------------------
function bashio::homeassistant.watchdog() {
    local watchdog=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${watchdog}"; then
        watchdog=$(bashio::var.json watchdog "^${watchdog}")
        bashio::api.hassio POST /homeassistant/options "${watchdog}"
        bashio::cache.flush_all
    else
        bashio::homeassistant 'homeassistant.info.watchdog' '.watchdog // false'
    fi
}

# ------------------------------------------------------------------------------
# List all available stats about Home Assistant.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::homeassistant.stats() {
    local cache_key=${1:-'homeassistant.stats'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'homeassistant.stats'; then
        info=$(bashio::cache.get 'homeassistant.stats')
    else
        info=$(bashio::api.hassio GET /homeassistant/stats false)
        bashio::cache.set 'homeassistant.stats' "${info}"
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
function bashio::homeassistant.cpu_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::homeassistant.stats 'homeassistant.stats.cpu_percent' '.cpu_percent'
}

# ------------------------------------------------------------------------------
# Returns memory usage from Home Assistant.
# ------------------------------------------------------------------------------
function bashio::homeassistant.memory_usage() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::homeassistant.stats 'homeassistant.stats.memory_usage' '.memory_usage'
}

# ------------------------------------------------------------------------------
# Returns memory limit from Home Assistant.
# ------------------------------------------------------------------------------
function bashio::homeassistant.memory_limit() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::homeassistant.stats 'homeassistant.stats.memory_limit' '.memory_limit'
}

# ------------------------------------------------------------------------------
# Returns outgoing network usage from Home Assistant.
# ------------------------------------------------------------------------------
function bashio::homeassistant.network_tx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::homeassistant.stats 'homeassistant.stats.network_tx' '.network_tx'
}

# ------------------------------------------------------------------------------
# Returns incoming network usage from Home Assistant.
# ------------------------------------------------------------------------------
function bashio::homeassistant.network_rx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::homeassistant.stats 'homeassistant.stats.network_rx' '.network_rx'
}

# ------------------------------------------------------------------------------
# Returns disk read usage from Home Assistant.
# ------------------------------------------------------------------------------
function bashio::homeassistant.blk_read() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::homeassistant.stats 'homeassistant.stats.blk_read' '.blk_read'
}

# ------------------------------------------------------------------------------
# Returns disk write usage from Home Assistant.
# ------------------------------------------------------------------------------
function bashio::homeassistant.blk_write() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::homeassistant.stats 'homeassistant.stats.blk_write' '.blk_write'
}
