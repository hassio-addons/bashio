#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Returns a JSON object with generic version information about the system.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::info() {
    local cache_key=${1:-'info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'info'; then
        info=$(bashio::cache.get 'info')
    else
        info=$(bashio::api.supervisor GET /info false)
        bashio::cache.set 'info' "${info}"
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
function bashio::info.supervisor() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::info 'supervisor.info.supervisor' '.supervisor'
}

# ------------------------------------------------------------------------------
# Returns the Home Assistant version used.
# ------------------------------------------------------------------------------
function bashio::info.homeassistant() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::info 'supervisor.info.homeassistant' '.homeassistant'
}

# ------------------------------------------------------------------------------
# Returns the hassos version running on the host system.
# ------------------------------------------------------------------------------
function bashio::info.hassos() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::info 'supervisor.info.hassos' '.hassos'
}

# ------------------------------------------------------------------------------
# Returns the hostname of the host system.
# ------------------------------------------------------------------------------
function bashio::info.hostname() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::info 'supervisor.info.hostname' '.hostname'
}

# ------------------------------------------------------------------------------
# Returns the machine type used.
# ------------------------------------------------------------------------------
function bashio::info.machine() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::info 'supervisor.info.machine' '.machine'
}

# ------------------------------------------------------------------------------
# Returns the architecture of the machine.
# ------------------------------------------------------------------------------
function bashio::info.arch() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::info 'supervisor.info.arch' '.arch'
}

# ------------------------------------------------------------------------------
# Returns the stability channel the system is enrolled in.
# ------------------------------------------------------------------------------
function bashio::info.channel() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::info 'supervisor.info.channel' '.channel'
}

# ------------------------------------------------------------------------------
# Returns a list of supported architectures by this system.
# ------------------------------------------------------------------------------
function bashio::info.supported_arch() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::info 'supervisor.info.supported_arch' '.supported_arch[]'
}

# ------------------------------------------------------------------------------
# Returns logging level of Supervisor universum.
# ------------------------------------------------------------------------------
function bashio::info.logging() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::info 'supervisor.info.logging' '.logging'
}

# ------------------------------------------------------------------------------
# Returns timezone of the system.
# ------------------------------------------------------------------------------
function bashio::info.timezone() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::info 'supervisor.info.timezone' '.timezone'
}

# ------------------------------------------------------------------------------
# Returns the supported state of the system.
# ------------------------------------------------------------------------------
function bashio::info.supported() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::info 'supervisor.info.supported' '.supported'
}

# ------------------------------------------------------------------------------
# Returns the Docker version running on the system.
# ------------------------------------------------------------------------------
function bashio::info.docker() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::info 'supervisor.info.docker' '.docker'
}

# ------------------------------------------------------------------------------
# Returns the operating system running on the system.
# ------------------------------------------------------------------------------
function bashio::info.operating_system() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::info 'supervisor.info.operating_system' '.operating_system'
}
