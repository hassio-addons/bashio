#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Returns a JSON object with hardware information about the system.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::hardware() {
    local cache_key=${1:-'hardware.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'hardware.info'; then
        info=$(bashio::cache.get 'hardware.info')
    else
        info=$(bashio::api.supervisor GET /hardware/info false)
        bashio::cache.set 'hardware.info' "${info}"
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
# Returns a list of available serial devices on the host system.
# ------------------------------------------------------------------------------
function bashio::hardware.serial() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::hardware 'hardware.info.serial' '.serial[]'
}

# ------------------------------------------------------------------------------
# Returns a list of available input devices on the host system.
# ------------------------------------------------------------------------------
function bashio::hardware.input() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::hardware 'hardware.info.input' '.input[]'
}

# ------------------------------------------------------------------------------
# Returns a list of available disk devices on the host system.
# ------------------------------------------------------------------------------
function bashio::hardware.disk() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::hardware 'hardware.info.disk' '.disk[]'
}

# ------------------------------------------------------------------------------
# Returns a list of available GPIO on the host system.
# ------------------------------------------------------------------------------
function bashio::hardware.gpio() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::hardware 'hardware.info.gpio' '.gpio[]'
}

# ------------------------------------------------------------------------------
# Returns a list of available USB devices on the host system.
# ------------------------------------------------------------------------------
function bashio::hardware.usb() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::hardware 'hardware.info.usb' '.usb[]'
}
