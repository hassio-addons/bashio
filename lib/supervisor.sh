#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Check to see if the Supervisor is still alive.
# ------------------------------------------------------------------------------
function bashio::supervisor.ping() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor GET /supervisor/ping
}

# ------------------------------------------------------------------------------
# Updates the Supervisor to the latest version.
#
# Arguments:
#   $1 Version to update to (optional)
# ------------------------------------------------------------------------------
function bashio::supervisor.update() {
    local version=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${version}"; then
        version=$(bashio::var.json version "${version}")
        bashio::api.supervisor POST /supervisor/update "${version}"
    else
        bashio::api.supervisor POST /supervisor/update
    fi
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Reloads the Supervisor.
# ------------------------------------------------------------------------------
function bashio::supervisor.reload() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /supervisor/reload
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Returns the logs created by the Supervisor.
# ------------------------------------------------------------------------------
function bashio::supervisor.logs() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor GET /supervisor/logs true
}

# ------------------------------------------------------------------------------
# Returns a JSON object with generic version information about the system.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::supervisor() {
    local cache_key=${1:-'supervisor.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'supervisor.info'; then
        info=$(bashio::cache.get 'supervisor.info')
    else
        info=$(bashio::api.supervisor GET /supervisor/info false)
        bashio::cache.set 'supervisor.info' "${info}"
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
# Returns the Home Assistant Supervisor version used.
# ------------------------------------------------------------------------------
function bashio::supervisor.version() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor 'supervisor.info.version' '.version'
}

# ------------------------------------------------------------------------------
# Returns the latest version of the Supervisor.
# ------------------------------------------------------------------------------
function bashio::supervisor.version_latest() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor 'supervisor.info.version_latest' '.version_latest'
}

# ------------------------------------------------------------------------------
# Checks if there is an update available for the Supervisor.
# ------------------------------------------------------------------------------
function bashio::supervisor.update_available() {
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::supervisor 'supervisor.info.update_available' '.update_available // false'
}

# ------------------------------------------------------------------------------
# Returns the architecture of the system.
# ------------------------------------------------------------------------------
function bashio::supervisor.arch() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor 'supervisor.info.arch' '.arch'
}

# ------------------------------------------------------------------------------
# Returns the supported state of the system.
# ------------------------------------------------------------------------------
function bashio::supervisor.supported() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor 'supervisor.info.supported' '.supported'
}

# ------------------------------------------------------------------------------
# Returns the healthy state of the system.
# ------------------------------------------------------------------------------
function bashio::supervisor.healthy() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor 'supervisor.info.healthy' '.healthy'
}

# ------------------------------------------------------------------------------
# Returns or sets the stability channel of the setup.
#
# Arguments:
#   $1 Stability channel to switch to: stable, beta or dev (optional).
# ------------------------------------------------------------------------------
function bashio::supervisor.channel() {
    local channel=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${channel}"; then
        channel=$(bashio::var.json channel "${channel}")
        bashio::api.supervisor POST /supervisor/options "${channel}"
        bashio::cache.flush_all
    else
        bashio::supervisor 'supervisor.info.channel' '.channel // false'
    fi
}

# ------------------------------------------------------------------------------
# Returns or sets the current timezone of the system.
#
# Arguments:
#   $1 Timezone to set (optional).
# ------------------------------------------------------------------------------
function bashio::supervisor.timezone() {
    local timezone=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${timezone}"; then
        channel=$(bashio::var.json timezone "${timezone}")
        bashio::api.supervisor POST /supervisor/options "${timezone}"
        bashio::cache.flush_all
    else
        bashio::supervisor 'supervisor.info.timezone' '.timezone'
    fi
}

# ------------------------------------------------------------------------------
# Returns the current logging level of the Supervisor.
#
# Arguments:
#   $1 Logging level to set (optional).
# ------------------------------------------------------------------------------
function bashio::supervisor.logging() {
    local logging=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${logging}"; then
        logging=$(bashio::var.json logging "${logging}")
        bashio::api.supervisor POST /supervisor/options "${logging}"
        bashio::cache.flush_all
    else
        bashio::supervisor 'supervisor.info.logging' '.logging'
    fi
}

# ------------------------------------------------------------------------------
# Returns the ip address of the supervisor.
# ------------------------------------------------------------------------------
function bashio::supervisor.ip_address() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor 'supervisor.info.ip_address' '.ip_address'
}

# ------------------------------------------------------------------------------
# Returns the time to wait after boot in seconds.
#
# Arguments:
#   $1 Timezone to set (optional).
# ------------------------------------------------------------------------------
function bashio::supervisor.wait_boot() {
    local wait=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${wait}"; then
        wait=$(bashio::var.json wait_boot "${wait}")
        bashio::api.supervisor POST /supervisor/options "${wait}"
        bashio::cache.flush_all
    else
        bashio::supervisor 'supervisor.info.wait_boot' '.wait_boot'
    fi
}

# ------------------------------------------------------------------------------
# Returns if debug is enabled on the supervisor
#
# Arguments:
#   $1 Set debug (optional).
# ------------------------------------------------------------------------------
function bashio::supervisor.debug() {
    local debug=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${debug}"; then
        if bashio::var.true "${debug}"; then
            debug=$(bashio::var.json debug "^true")
        else
            debug=$(bashio::var.json debug "^false")
        fi
        bashio::api.supervisor POST /supervisor/options "${debug}"
        bashio::cache.flush_all
    else
        bashio::supervisor 'supervisor.info.debug' '.debug // false'
    fi
}

# ------------------------------------------------------------------------------
# Returns if debug block is enabled on the supervisor
#
# Arguments:
#   $1 Set debug block (optional).
# ------------------------------------------------------------------------------
function bashio::supervisor.debug_block() {
    local debug=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${debug}"; then
        if bashio::var.true "${debug}"; then
            debug=$(bashio::var.json debug_block "^true")
        else
            debug=$(bashio::var.json debug_block "^false")
        fi
        bashio::api.supervisor POST /supervisor/options "${debug}"
        bashio::cache.flush_all
    else
        bashio::supervisor 'supervisor.info.debug_block' '.debug_block // false'
    fi
}

# ------------------------------------------------------------------------------
# Returns a list of add-on slugs of the add-ons installed.
# ------------------------------------------------------------------------------
function bashio::supervisor.addons() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor 'supervisor.info.addons' '.addons[].slug'
}

# ------------------------------------------------------------------------------
# Returns a list of add-on repositories installed.
# ------------------------------------------------------------------------------
function bashio::supervisor.addons_repositories() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor 'supervisor.info.addons_repositories' '.addons_repositories[]'
}

# ------------------------------------------------------------------------------
# List all available stats about the Supervisor.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::supervisor.stats() {
    local cache_key=${1:-'supervisor.stats'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'supervisor.stats'; then
        info=$(bashio::cache.get 'supervisor.stats')
    else
        info=$(bashio::api.supervisor GET /supervisor/stats false)
        bashio::cache.set 'supervisor.stats' "${info}"
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
# Returns CPU usage from the Supervisor.
# ------------------------------------------------------------------------------
function bashio::supervisor.cpu_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor.stats 'supervisor.stats.cpu_percent' '.cpu_percent'
}

# ------------------------------------------------------------------------------
# Returns memory usage from the Supervisor.
# ------------------------------------------------------------------------------
function bashio::supervisor.memory_usage() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor.stats 'supervisor.stats.memory_usage' '.memory_usage'
}

# ------------------------------------------------------------------------------
# Returns memory limit from the Supervisor.
# ------------------------------------------------------------------------------
function bashio::supervisor.memory_limit() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor.stats 'supervisor.stats.memory_limit' '.memory_limit'
}

# ------------------------------------------------------------------------------
# Returns memory usage in percent from the Supervisor.
# ------------------------------------------------------------------------------
function bashio::supervisor.memory_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor.stats 'supervisor.stats.memory_percent' '.memory_percent'
}

# ------------------------------------------------------------------------------
# Returns outgoing network usage from the Supervisor.
# ------------------------------------------------------------------------------
function bashio::supervisor.network_tx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor.stats 'supervisor.stats.network_tx' '.network_tx'
}

# ------------------------------------------------------------------------------
# Returns incoming network usage from the Supervisor.
# ------------------------------------------------------------------------------
function bashio::supervisor.network_rx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor.stats 'supervisor.stats.network_rx' '.network_rx'
}

# ------------------------------------------------------------------------------
# Returns disk read usage from the Supervisor.
# ------------------------------------------------------------------------------
function bashio::supervisor.blk_read() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor.stats 'supervisor.stats.blk_read' '.blk_read'
}

# ------------------------------------------------------------------------------
# Returns disk write usage from the Supervisor.
# ------------------------------------------------------------------------------
function bashio::supervisor.blk_write() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::supervisor.stats 'supervisor.stats.blk_write' '.blk_write'
}
